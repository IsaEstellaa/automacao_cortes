const pool = require('../config/database');

// ============================================
// criar execuções (envia cortes para a máquina)
// ============================================
const criar = async (req, res) => {
  const { id_material, cortes } = req.body;

  if (!Number.isInteger(id_material)) {
    return res.status(400).json({ erro: 'Material é obrigatório!' });
  }

  if (!Array.isArray(cortes) || cortes.length === 0) {
    return res.status(400).json({ erro: 'Selecione pelo menos um corte!' });
  }

  if (!cortes.every((c) => Number.isInteger(c))) {
    return res.status(400).json({ erro: 'Lista de cortes inválida!' });
  }

  if (new Set(cortes).size !== cortes.length) {
    return res.status(400).json({ erro: 'Há cortes repetidos na lista!' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // evita dois envios simultâneos passarem juntos pela checagem da fila
    await client.query('SELECT pg_advisory_xact_lock($1)', [req.usuarioId]);

    // só envia se a fila estiver vazia
    const fila = await client.query(
      `SELECT 1
       FROM EXECUCAO_CORTE E
       JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE P.ID_USUARIO = $1 AND E.SITUACAO IN ('A', 'P')
       LIMIT 1`,
      [req.usuarioId]
    );

    if (fila.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        erro: 'Já existem cortes na fila. Aguarde finalizar para enviar novos.',
      });
    }

    // material precisa ser do usuário e estar ativo
    const material = await client.query(
      `SELECT ID_MATERIAL FROM MATERIAL
       WHERE ID_MATERIAL = $1 AND ID_USUARIO = $2 AND STATUS = 'A'`,
      [id_material, req.usuarioId]
    );

    if (material.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Material não encontrado!' });
    }

    // cortes precisam ser do usuário, ativos, de peças ativas e da mesma peça
    const encontrados = await client.query(
      `SELECT C.ID_CORTE, C.ID_PECA, C.QUANTIDADE
       FROM CORTE C
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE C.ID_CORTE = ANY($1)
         AND C.SITUACAO = 'A'
         AND P.SITUACAO = 'A'
         AND P.ID_USUARIO = $2`,
      [cortes, req.usuarioId]
    );

    if (encontrados.rows.length !== cortes.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Um ou mais cortes não foram encontrados!' });
    }

    const pecasDistintas = new Set(encontrados.rows.map((c) => c.id_peca));

    if (pecasDistintas.size > 1) {
      await client.query('ROLLBACK');
      return res.status(400).json({ erro: 'Todos os cortes devem ser da mesma peça!' });
    }

    const mapaCortes = new Map(encontrados.rows.map((c) => [c.id_corte, c]));
    const criadas = [];

    // cria na ordem em que vieram
    for (const idCorte of cortes) {
      const corte = mapaCortes.get(idCorte);

      const execucao = await client.query(
        `INSERT INTO EXECUCAO_CORTE (ID_CORTE, ID_MATERIAL)
         VALUES ($1, $2)
         RETURNING ID_EXECUCAO, ID_CORTE, ID_MATERIAL, SITUACAO, DATA_CADASTRO`,
        [idCorte, id_material]
      );

      const idExecucao = execucao.rows[0].id_execucao;

      // gera os N fios - pendentes
      await client.query(
        `INSERT INTO FIO (ID_EXECUCAO)
         SELECT $1 FROM generate_series(1, $2)`,
        [idExecucao, corte.quantidade]
      );

      criadas.push({ ...execucao.rows[0], total_fios: corte.quantidade });
    }

    await client.query('COMMIT');
    return res.status(201).json(criadas);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

module.exports = { criar };