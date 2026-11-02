const pool = require('../config/database');
const storage = require('../services/storage.service');

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
// fotos das peças
// ============================================
const MAX_FOTOS_PECA = 5;

// fotos ativas, na ordem do envio (a primeira é a capa)
const buscarFotos = async (db, idsPecas) => {
  const resultado = await db.query(
    `SELECT ID_FOTO, ID_PECA, URL_PECA
     FROM FOTOS_PECA
     WHERE ID_PECA = ANY($1) AND SITUACAO = 'A'
     ORDER BY ID_FOTO`,
    [idsPecas]
  );

  return resultado.rows;
};

const formatarFotos = (linhas, idPeca) =>
  linhas
    .filter((f) => f.id_peca === idPeca)
    .map((f) => ({ id_foto: f.id_foto, url: f.url_peca }));
    
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

  const fotos = await buscarFotos(client, [idPeca]);

  return {
    ...peca.rows[0],
    cortes: cortes.rows,
    fotos: formatarFotos(fotos, peca.rows[0].id_peca),
  };
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

    const fotos = ids.length > 0 ? await buscarFotos(pool, ids) : [];

    const resultado = pecas.rows.map((p) => ({
      ...p,
      cortes: cortes.rows.filter((c) => c.id_peca === p.id_peca),
      fotos: formatarFotos(fotos, p.id_peca),
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

// ============================================
// adicionar foto a uma peça
// ============================================
const adicionarFoto = async (req, res) => {
  const idPeca = Number(req.params.id);

  if (!Number.isInteger(idPeca)) {
    return res.status(400).json({ erro: 'Id da peça inválido!' });
  }

  if (!req.file) {
    return res.status(400).json({ erro: 'Envie uma foto no campo "foto"!' });
  }

  const tipo = storage.detectarTipo(req.file.buffer);
  if (!tipo) {
    return res.status(400).json({ erro: 'Formato inválido! Use JPG, PNG ou WebP.' });
  }

  const erroLimite = { erro: `Cada peça pode ter no máximo ${MAX_FOTOS_PECA} fotos!` };
  let url = null;

  try {
    const peca = await pool.query(
      `SELECT 1 FROM PECA
       WHERE ID_PECA = $1 AND ID_USUARIO = $2 AND SITUACAO = 'A'`,
      [idPeca, req.usuarioId]
    );

    if (peca.rows.length === 0) {
      return res.status(404).json({ erro: 'Peça não encontrada!' });
    }

    // confere o limite antes de enviar o arquivo
    const total = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM FOTOS_PECA
       WHERE ID_PECA = $1 AND SITUACAO = 'A'`,
      [idPeca]
    );

    if (total.rows[0].total >= MAX_FOTOS_PECA) {
      return res.status(409).json(erroLimite);
    }

    url = await storage.enviarFoto(`pecas/${idPeca}`, req.file.buffer, tipo);

    const resultado = await pool.query(
      `INSERT INTO FOTOS_PECA (ID_PECA, URL_PECA)
       SELECT $1::int, $2::text
       WHERE (SELECT COUNT(*) FROM FOTOS_PECA
              WHERE ID_PECA = $1::int AND SITUACAO = 'A') < $3::int
       RETURNING ID_FOTO, URL_PECA`,
      [idPeca, url, MAX_FOTOS_PECA]
    );

    if (resultado.rows.length === 0) {
      await storage.removerFoto(url);
      return res.status(409).json(erroLimite);
    }

    const foto = resultado.rows[0];
    return res.status(201).json({ id_foto: foto.id_foto, url: foto.url_peca });

  } catch (err) {
    console.error(err.message);
    if (url) await storage.removerFoto(url);
    return res.status(500).json({ erro: 'Não foi possível salvar a foto' });
  }
};

// ============================================
// remover foto de uma peça (inativa e apaga o arquivo)
// ============================================
const excluirFoto = async (req, res) => {
  const idPeca = Number(req.params.id);
  const idFoto = Number(req.params.idFoto);

  if (!Number.isInteger(idPeca) || !Number.isInteger(idFoto)) {
    return res.status(400).json({ erro: 'Id inválido!' });
  }

  try {
    const resultado = await pool.query(
      `UPDATE FOTOS_PECA F
       SET SITUACAO = 'I', ULTIMA_MODIFICACAO = NOW()
       FROM PECA P
       WHERE F.ID_FOTO = $1 AND F.ID_PECA = $2 AND F.SITUACAO = 'A'
         AND P.ID_PECA = F.ID_PECA AND P.ID_USUARIO = $3 AND P.SITUACAO = 'A'
       RETURNING F.URL_PECA`,
      [idFoto, idPeca, req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Foto não encontrada!' });
    }

    await storage.removerFoto(resultado.rows[0].url_peca);

    return res.status(204).send();

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

module.exports = { criar, listar, buscarPorId, atualizar, excluir, adicionarFoto, excluirFoto };