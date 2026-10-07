const pool = require('../config/database');

// ============================================
// verifica se há algo em andamento (fila ou retentativa pendente)
// ============================================
const filaOcupada = async (client, idUsuario) => {
  const resultado = await client.query(
    `SELECT 1
     FROM EXECUCAO_CORTE E
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     JOIN PECA P ON P.ID_PECA = C.ID_PECA
     WHERE P.ID_USUARIO = $1
       AND (
         E.SITUACAO IN ('A', 'P')
         OR EXISTS (
           SELECT 1 FROM RETENTATIVA R
           WHERE R.ID_EXECUCAO = E.ID_EXECUCAO AND R.SITUACAO = 'P'
         )
       )
     LIMIT 1`,
    [idUsuario]
  );

  return resultado.rows.length > 0;
};

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

    // só envia se a fila estiver vazia (e sem retentativa pendente)
    if (await filaOcupada(client, req.usuarioId)) {
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

// ============================================
// busca execuções do usuário por situação
// ============================================
const buscarExecucoes = async (idUsuario, situacoes, ordem) => {
  const execucoes = await pool.query(
    `SELECT E.ID_EXECUCAO, E.ID_CORTE, E.ID_MATERIAL, E.SITUACAO,
            E.DATA_CADASTRO, E.DATA_INICIO, E.DATA_FIM,
            C.QUANTIDADE, C.METRAGEM,
            P.ID_PECA, P.NOME AS NOME_PECA,
            M.NOME AS NOME_MATERIAL
     FROM EXECUCAO_CORTE E
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     JOIN PECA P ON P.ID_PECA = C.ID_PECA
     JOIN MATERIAL M ON M.ID_MATERIAL = E.ID_MATERIAL
     WHERE P.ID_USUARIO = $1 AND E.SITUACAO = ANY($2)
     ORDER BY ${ordem}`,
    [idUsuario, situacoes]
  );

  const ids = execucoes.rows.map((e) => e.id_execucao);
  let fios = { rows: [] };

  if (ids.length > 0) {
    fios = await pool.query(
      `SELECT ID_FIO, ID_EXECUCAO, STATUS
       FROM FIO
       WHERE ID_EXECUCAO = ANY($1)
       ORDER BY ID_FIO`,
      [ids]
    );
  }

  return execucoes.rows.map((e) => ({
    ...e,
    fios: fios.rows
      .filter((f) => f.id_execucao === e.id_execucao)
      .map((f) => ({ id_fio: f.id_fio, status: f.status })),
  }));
};

// ============================================
// listar fila (aguardando e processando, FIFO)
// ============================================
const listarFila = async (req, res) => {
  try {
    const fila = await buscarExecucoes(req.usuarioId, ['A', 'P'], 'E.ID_EXECUCAO');
    return res.status(200).json(fila);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// listar histórico (concluídas e com erro, agrupado por peça)
// ============================================
const listarHistorico = async (req, res) => {
  try {
    const execucoes = await buscarExecucoes(
      req.usuarioId,
      ['C', 'E'],
      'E.DATA_FIM DESC NULLS LAST, E.ID_EXECUCAO DESC'
    );

    const grupos = new Map();

    for (const e of execucoes) {
      if (!grupos.has(e.id_peca)) {
        grupos.set(e.id_peca, {
          id_peca: e.id_peca,
          nome_peca: e.nome_peca,
          execucoes: [],
        });
      }
      grupos.get(e.id_peca).execucoes.push(e);
    }

    return res.status(200).json([...grupos.values()]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// detalhes de uma execução (alimenta o ModalDetalhesCorte)
// ============================================
const detalhes = async (req, res) => {
  const idExecucao = Number(req.params.id);

  if (!Number.isInteger(idExecucao)) {
    return res.status(400).json({ erro: 'Id da execução inválido!' });
  }

  try {
    const execucao = await pool.query(
      `SELECT E.ID_EXECUCAO, E.SITUACAO, E.DATA_INICIO, E.DATA_FIM,
              C.QUANTIDADE, C.METRAGEM,
              P.ID_PECA, P.NOME AS NOME_PECA
       FROM EXECUCAO_CORTE E
       JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE E.ID_EXECUCAO = $1 AND P.ID_USUARIO = $2`,
      [idExecucao, req.usuarioId]
    );

    if (execucao.rows.length === 0) {
      return res.status(404).json({ erro: 'Execução não encontrada!' });
    }

    // fios com o último log de erro e se há retentativa pendente
    const fios = await pool.query(
      `SELECT F.ID_FIO, F.STATUS, L.MENSAGEM,
              EXISTS (
                SELECT 1 FROM RETENTATIVA R
                WHERE R.ID_FIO = F.ID_FIO AND R.SITUACAO = 'P'
              ) AS RETENTANDO
       FROM FIO F
       LEFT JOIN LATERAL (
         SELECT MENSAGEM FROM LOG_FIOS
         WHERE ID_FIO = F.ID_FIO
         ORDER BY DATA_HORA DESC, ID_LOG DESC
         LIMIT 1
       ) L ON TRUE
       WHERE F.ID_EXECUCAO = $1
       ORDER BY F.ID_FIO`,
      [idExecucao]
    );

    const listaFios = fios.rows.map((f) => ({
      id_fio: f.id_fio,
      status: f.status,
      // só mostra mensagem se o fio ainda está com erro
      mensagem: f.status === 'E' ? f.mensagem : null,
      retentando: f.retentando,
    }));

    return res.status(200).json({
      ...execucao.rows[0],
      retentando: listaFios.some((f) => f.retentando),
      fios: listaFios,
    });

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// retentar fios com erro de uma execução
// ============================================
const retentar = async (req, res) => {
  const idExecucao = Number(req.params.id);

  if (!Number.isInteger(idExecucao)) {
    return res.status(400).json({ erro: 'Id da execução inválido!' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // evita corrida entre envio e retentativa
    await client.query('SELECT pg_advisory_xact_lock($1)', [req.usuarioId]);

    const execucao = await client.query(
      `SELECT E.ID_EXECUCAO, E.SITUACAO
       FROM EXECUCAO_CORTE E
       JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE E.ID_EXECUCAO = $1 AND P.ID_USUARIO = $2`,
      [idExecucao, req.usuarioId]
    );

    if (execucao.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Execução não encontrada!' });
    }

    if (!['C', 'E'].includes(execucao.rows[0].situacao)) {
      await client.query('ROLLBACK');
      return res.status(409).json({ erro: 'Só é possível retentar execuções finalizadas!' });
    }

    // fios com erro que ainda não têm retentativa pendente
    const fios = await client.query(
      `SELECT F.ID_FIO
       FROM FIO F
       WHERE F.ID_EXECUCAO = $1
         AND F.STATUS = 'E'
         AND NOT EXISTS (
           SELECT 1 FROM RETENTATIVA R
           WHERE R.ID_FIO = F.ID_FIO AND R.SITUACAO = 'P'
         )
       ORDER BY F.ID_FIO`,
      [idExecucao]
    );

    if (fios.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ erro: 'Não há fios com erro para retentar!' });
    }

    // regra: máquina ocupada (fila ou outra retentativa) não aceita retentar
    if (await filaOcupada(client, req.usuarioId)) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        erro: 'Há cortes em andamento. Aguarde finalizar para retentar.',
      });
    }

    const idsFios = fios.rows.map((f) => f.id_fio);

    const retentativas = await client.query(
      `INSERT INTO RETENTATIVA (ID_EXECUCAO, ID_FIO)
       SELECT $1, UNNEST($2::int[])
       RETURNING ID_RETENTATIVA, ID_EXECUCAO, ID_FIO, SITUACAO, DATA_CADASTRO`,
      [idExecucao, idsFios]
    );

    await client.query('COMMIT');
    return res.status(201).json(retentativas.rows);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

module.exports = { criar, listarFila, listarHistorico, detalhes, retentar };