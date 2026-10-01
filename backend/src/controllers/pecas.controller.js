const pool = require('../config/database');

// ============================================
// validação dos cortes (usada no criar e no atualizar)
// ============================================
const validarCortes = (cortes) => {
  if (!Array.isArray(cortes) || cortes.length === 0) {
    return 'A peça precisa ter pelo menos um corte!';
  }

  for (const c of cortes) {
    if (!Number.isInteger(Number(c.quantidade)) || Number(c.quantidade) <= 0) {
      return 'Quantidade de fios deve ser um número inteiro maior que zero!';
    }
    if (isNaN(c.metragem) || Number(c.metragem) <= 0) {
      return 'Metragem deve ser um número maior que zero!';
    }
  }

  return null;
};

// ============================================
// monta a peça com seus cortes ativos
// ============================================
const buscarPecaComCortes = async (client, idPeca, idUsuario) => {
  const peca = await client.query(
    `SELECT * FROM PECA
     WHERE ID_PECA = $1 AND ID_USUARIO = $2 AND SITUACAO = 'A'`,
    [idPeca, idUsuario]
  );

  if (peca.rows.length === 0) return null;

  const cortes = await client.query(
    `SELECT ID_CORTE, QUANTIDADE, METRAGEM
     FROM CORTE
     WHERE ID_PECA = $1 AND SITUACAO = 'A'
     ORDER BY ID_CORTE`,
    [idPeca]
  );

  return { ...peca.rows[0], cortes: cortes.rows };
};

// ============================================
// criar peça (com cortes)
// ============================================
const criar = async (req, res) => {
  const { nome, descricao, cortes } = req.body;

  if (!nome || nome.trim() === '') {
    return res.status(400).json({ erro: 'Nome é obrigatório!' });
  }

  const erroCortes = validarCortes(cortes);
  if (erroCortes) {
    return res.status(400).json({ erro: erroCortes });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const peca = await client.query(
      `INSERT INTO PECA (ID_USUARIO, NOME, DESCRICAO)
       VALUES ($1, $2, $3)
       RETURNING ID_PECA`,
      [req.usuarioId, nome.trim(), descricao ?? null]
    );

    const idPeca = peca.rows[0].id_peca;

    for (const c of cortes) {
      await client.query(
        `INSERT INTO CORTE (ID_PECA, QUANTIDADE, METRAGEM)
         VALUES ($1, $2, $3)`,
        [idPeca, c.quantidade, c.metragem]
      );
    }

    await client.query('COMMIT');

    const resultado = await buscarPecaComCortes(pool, idPeca, req.usuarioId);
    return res.status(201).json(resultado);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

// ============================================
// listar peças do usuário (com cortes)
// ============================================
const listar = async (req, res) => {
  try {
    const pecas = await pool.query(
      `SELECT * FROM PECA
       WHERE ID_USUARIO = $1 AND SITUACAO = 'A'
       ORDER BY NOME`,
      [req.usuarioId]
    );

    const ids = pecas.rows.map((p) => p.id_peca);
    let cortes = { rows: [] };

    if (ids.length > 0) {
      cortes = await pool.query(
        `SELECT ID_CORTE, ID_PECA, QUANTIDADE, METRAGEM
         FROM CORTE
         WHERE ID_PECA = ANY($1) AND SITUACAO = 'A'
         ORDER BY ID_CORTE`,
        [ids]
      );
    }

    const resultado = pecas.rows.map((p) => ({
      ...p,
      cortes: cortes.rows.filter((c) => c.id_peca === p.id_peca),
    }));

    return res.status(200).json(resultado);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// buscar uma peça por id (com cortes)
// ============================================
const buscarPorId = async (req, res) => {
  try {
    const peca = await buscarPecaComCortes(pool, req.params.id, req.usuarioId);

    if (!peca) {
      return res.status(404).json({ erro: 'Peça não encontrada!' });
    }

    return res.status(200).json(peca);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// atualizar peça (nome, descrição e cortes)
// ============================================
const atualizar = async (req, res) => {
  const { id } = req.params;
  const { nome, descricao, cortes } = req.body;

  if (!nome || nome.trim() === '') {
    return res.status(400).json({ erro: 'Nome é obrigatório!' });
  }

  const erroCortes = validarCortes(cortes);
  if (erroCortes) {
    return res.status(400).json({ erro: erroCortes });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // atualiza a peça
    const peca = await client.query(
      `UPDATE PECA
       SET NOME = $1, DESCRICAO = $2, ULTIMA_MODIFICACAO = NOW()
       WHERE ID_PECA = $3 AND ID_USUARIO = $4 AND SITUACAO = 'A'
       RETURNING ID_PECA`,
      [nome.trim(), descricao ?? null, id, req.usuarioId]
    );

    if (peca.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Peça não encontrada!' });
    }

    // cortes ativos atuais da peça
    const atuais = await client.query(
      `SELECT ID_CORTE, QUANTIDADE, METRAGEM
       FROM CORTE
       WHERE ID_PECA = $1 AND SITUACAO = 'A'`,
      [id]
    );

    const mapaAtuais = new Map(atuais.rows.map((c) => [c.id_corte, c]));
    const idsMantidos = new Set();

    for (const c of cortes) {
      if (c.id_corte) {
        const atual = mapaAtuais.get(Number(c.id_corte));

        if (!atual) {
          await client.query('ROLLBACK');
          return res.status(400).json({ erro: `Corte ${c.id_corte} não pertence a esta peça!` });
        }

        idsMantidos.add(atual.id_corte);

        const mudou =
          Number(atual.quantidade) !== Number(c.quantidade) ||
          Number(atual.metragem) !== Number(c.metragem);

        if (mudou) {
          await client.query(
            `UPDATE CORTE SET SITUACAO = 'I', DATA_EXCLUSAO = NOW()
             WHERE ID_CORTE = $1`,
            [atual.id_corte]
          );
          await client.query(
            `INSERT INTO CORTE (ID_PECA, ID_CORTE_ANTERIOR, QUANTIDADE, METRAGEM)
             VALUES ($1, $2, $3, $4)`,
            [id, atual.id_corte, c.quantidade, c.metragem]
          );
        }
      } else {
        // corte novo
        await client.query(
          `INSERT INTO CORTE (ID_PECA, QUANTIDADE, METRAGEM)
           VALUES ($1, $2, $3)`,
          [id, c.quantidade, c.metragem]
        );
      }
    }

    // cortes que existiam e não vieram na lista foram removidos na tela
    for (const atual of atuais.rows) {
      if (!idsMantidos.has(atual.id_corte)) {
        await client.query(
          `UPDATE CORTE SET SITUACAO = 'I', DATA_EXCLUSAO = NOW()
           WHERE ID_CORTE = $1`,
          [atual.id_corte]
        );
      }
    }

    await client.query('COMMIT');

    const resultado = await buscarPecaComCortes(pool, id, req.usuarioId);
    return res.status(200).json(resultado);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

// ============================================
// excluir peça (soft delete)
// ============================================
const excluir = async (req, res) => {
  const { id } = req.params;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const peca = await client.query(
      `UPDATE PECA
       SET SITUACAO = 'I', ULTIMA_MODIFICACAO = NOW()
       WHERE ID_PECA = $1 AND ID_USUARIO = $2 AND SITUACAO = 'A'
       RETURNING ID_PECA`,
      [id, req.usuarioId]
    );

    if (peca.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Peça não encontrada!' });
    }

    // inativa também os cortes da peça
    await client.query(
      `UPDATE CORTE SET SITUACAO = 'I', DATA_EXCLUSAO = NOW()
       WHERE ID_PECA = $1 AND SITUACAO = 'A'`,
      [id]
    );

    await client.query('COMMIT');
    return res.status(200).json({ mensagem: 'Peça excluída com sucesso!' });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

module.exports = { criar, listar, buscarPorId, atualizar, excluir };