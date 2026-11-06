const pool = require('../config/database');

const MENSAGENS_ERRO = {
  FALHA_MEDICAO: 'Falha na medição',
  FIO_TRAVOU: 'Fio travou',
};

const montarCorte = async (client, idExecucao) => {
  const dados = await client.query(
    `SELECT E.ID_EXECUCAO, C.QUANTIDADE, C.METRAGEM, M.NOME AS MATERIAL
     FROM EXECUCAO_CORTE E
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     JOIN MATERIAL M ON M.ID_MATERIAL = E.ID_MATERIAL
     WHERE E.ID_EXECUCAO = $1`,
    [idExecucao]
  );
  const fios = await client.query(
    `SELECT ID_FIO FROM FIO
     WHERE ID_EXECUCAO = $1 AND STATUS = 'P'
     ORDER BY ID_FIO`,
    [idExecucao]
  );
  const d = dados.rows[0];
  return {
    tipo: 'corte',
    id_execucao: d.id_execucao,
    metragem: Number(d.metragem),
    material: d.material,
    fios: fios.rows.map((f) => ({ id_fio: f.id_fio })),
  };
};

const montarRetentativas = async (client, idUsuario) => {
  const r = await client.query(
    `SELECT R.ID_RETENTATIVA, R.ID_FIO, R.ID_EXECUCAO, C.METRAGEM, M.NOME AS MATERIAL
     FROM RETENTATIVA R
     JOIN EXECUCAO_CORTE E ON E.ID_EXECUCAO = R.ID_EXECUCAO
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     JOIN PECA P ON P.ID_PECA = C.ID_PECA
     JOIN MATERIAL M ON M.ID_MATERIAL = E.ID_MATERIAL
     WHERE P.ID_USUARIO = $1 AND R.SITUACAO = 'P'
     ORDER BY R.ID_RETENTATIVA`,
    [idUsuario]
  );
  if (r.rows.length === 0) return null;

  return {
    tipo: 'retentativa',
    id_execucao: r.rows[0].id_execucao,
    metragem: Number(r.rows[0].metragem),
    material: r.rows[0].material,
    fios: r.rows.map((x) => ({
      id_fio: x.id_fio,
      id_retentativa: x.id_retentativa,
    })),
  };
};

// GET /maquina/trabalho
const trabalho = async (req, res) => {
  const { idUsuario } = req.maquina;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // já existe lote em andamento?
    const emAndamento = await client.query(
      `SELECT E.ID_EXECUCAO
       FROM EXECUCAO_CORTE E
       JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE P.ID_USUARIO = $1 AND E.SITUACAO = 'P'
       ORDER BY E.ID_EXECUCAO
       LIMIT 1`,
      [idUsuario]
    );
    if (emAndamento.rows.length > 0) {
      const t = await montarCorte(client, emAndamento.rows[0].id_execucao);
      await client.query('COMMIT');
      return res.json({ trabalho: t });
    }

    // retentativas pendentes
    const retentativas = await montarRetentativas(client, idUsuario);
    if (retentativas) {
      await client.query('COMMIT');
      return res.json({ trabalho: retentativas });
    }

    // pega o lote mais antigo da fila e marca como em andamento
    const pegou = await client.query(
      `UPDATE EXECUCAO_CORTE
       SET SITUACAO = 'P', DATA_INICIO = NOW()
       WHERE ID_EXECUCAO = (
         SELECT E.ID_EXECUCAO
         FROM EXECUCAO_CORTE E
         JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
         JOIN PECA P ON P.ID_PECA = C.ID_PECA
         WHERE P.ID_USUARIO = $1 AND E.SITUACAO = 'A'
         ORDER BY E.ID_EXECUCAO
         LIMIT 1
         FOR UPDATE OF E SKIP LOCKED
       )
       RETURNING ID_EXECUCAO`,
      [idUsuario]
    );

    if (pegou.rows.length === 0) {
      await client.query('COMMIT');
      return res.json({ trabalho: null });
    }

    const t = await montarCorte(client, pegou.rows[0].id_execucao);
    await client.query('COMMIT');
    res.json({ trabalho: t });
  } catch (erro) {
    await client.query('ROLLBACK');
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao buscar trabalho' });
  } finally {
    client.release();
  }
};

// POST /maquina/fios/:idFio/resultado
// body: { status: 'C' | 'E', codigo_erro?: 'FALHA_MEDICAO' | 'FIO_TRAVOU' }
const resultado = async (req, res) => {
  const { idUsuario } = req.maquina;
  const idFio = Number(req.params.idFio);
  const { status, codigo_erro } = req.body;

  if (!Number.isInteger(idFio)) {
    return res.status(400).json({ erro: 'Fio inválido' });
  }
  if (status !== 'C' && status !== 'E') {
    return res.status(400).json({ erro: "status deve ser 'C' ou 'E'" });
  }
  if (status === 'E' && !MENSAGENS_ERRO[codigo_erro]) {
    return res.status(400).json({
      erro: 'codigo_erro deve ser FALHA_MEDICAO ou FIO_TRAVOU',
    });
  }
  const mensagem = status === 'E' ? MENSAGENS_ERRO[codigo_erro] : null;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const fio = await client.query(
      `SELECT F.ID_FIO, F.STATUS, F.ID_EXECUCAO
       FROM FIO F
       JOIN EXECUCAO_CORTE E ON E.ID_EXECUCAO = F.ID_EXECUCAO
       JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
       JOIN PECA P ON P.ID_PECA = C.ID_PECA
       WHERE F.ID_FIO = $1 AND P.ID_USUARIO = $2
       FOR UPDATE OF F`,
      [idFio, idUsuario]
    );
    if (fio.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Fio não encontrado' });
    }
    const { status: statusAtual, id_execucao: idExecucao } = fio.rows[0];

    // --- caminho da retentativa ---
    const ret = await client.query(
      `SELECT ID_RETENTATIVA FROM RETENTATIVA
       WHERE ID_FIO = $1 AND SITUACAO = 'P'
       LIMIT 1
       FOR UPDATE`,
      [idFio]
    );
    if (ret.rows.length > 0) {
      const idRet = ret.rows[0].id_retentativa;

      await client.query(
        `UPDATE RETENTATIVA
         SET SITUACAO = $1,
             DATA_INICIO = COALESCE(DATA_INICIO, NOW()),
             DATA_FIM = NOW()
         WHERE ID_RETENTATIVA = $2`,
        [status, idRet]
      );

      if (status === 'C') {
        await client.query(`UPDATE FIO SET STATUS = 'C' WHERE ID_FIO = $1`, [idFio]);
      } else {
        await client.query(
          `INSERT INTO LOG_FIOS (ID_FIO, ID_RETENTATIVA, MENSAGEM)
           VALUES ($1, $2, $3)`,
          [idFio, idRet, `Falha na segunda tentativa: ${mensagem}`]
        );
      }

      await client.query('COMMIT');
      return res.json({ ok: true });
    }

    // --- caminho normal ---
    if (statusAtual !== 'P') {
      // resultado repetido
      await client.query('ROLLBACK');
      return res.json({ ok: true, repetido: true });
    }

    await client.query(`UPDATE FIO SET STATUS = $1 WHERE ID_FIO = $2`, [status, idFio]);

    if (status === 'E') {
      await client.query(
        `INSERT INTO LOG_FIOS (ID_FIO, MENSAGEM) VALUES ($1, $2)`,
        [idFio, mensagem]
      );
    }

    // fecha o lote
    const resumo = await client.query(
      `SELECT
         COUNT(*) FILTER (WHERE STATUS = 'P') AS pendentes,
         COUNT(*) FILTER (WHERE STATUS = 'E') AS com_erro
       FROM FIO WHERE ID_EXECUCAO = $1`,
      [idExecucao]
    );
    const { pendentes, com_erro } = resumo.rows[0];

    if (Number(pendentes) === 0) {
      await client.query(
        `UPDATE EXECUCAO_CORTE
         SET SITUACAO = $1, DATA_FIM = NOW()
         WHERE ID_EXECUCAO = $2`,
        [Number(com_erro) > 0 ? 'E' : 'C', idExecucao]
      );
    }

    await client.query('COMMIT');
    res.json({ ok: true, lote_finalizado: Number(pendentes) === 0 });
  } catch (erro) {
    await client.query('ROLLBACK');
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao registrar resultado' });
  } finally {
    client.release();
  }
};

module.exports = { trabalho, resultado };