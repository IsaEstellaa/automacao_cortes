const crypto = require('crypto');
const pool = require('../config/database');

const gerarChave = () => {
  const chave = crypto.randomBytes(24).toString('hex');
  const hash = crypto.createHash('sha256').update(chave).digest('hex');
  return { chave, hash };
};

const limparNome = (nome) =>
  String(nome ?? '').trim().slice(0, 100);

// POST /maquinas
const criar = async (req, res) => {
  try {
    const nome = limparNome(req.body.nome) || 'Minha máquina';

    const existente = await pool.query(
      `SELECT 1 FROM MAQUINA WHERE ID_USUARIO = $1 AND SITUACAO = 'A' LIMIT 1`,
      [req.usuarioId]
    );
    if (existente.rows.length > 0) {
      return res.status(409).json({
        erro: 'Você já tem uma máquina ativa. Remova-a para cadastrar outra.',
      });
    }

    const { chave, hash } = gerarChave();

    const r = await pool.query(
      `INSERT INTO MAQUINA (ID_USUARIO, NOME, CHAVE_HASH)
       VALUES ($1, $2, $3)
       RETURNING ID_MAQUINA, NOME`,
      [req.usuarioId, nome, hash]
    );

    res.status(201).json({
      id_maquina: r.rows[0].id_maquina,
      nome: r.rows[0].nome,
      chave,
      aviso: 'Guarde esta chave: ela não será mostrada novamente.',
    });
  } catch (erro) {
    if (erro.code === '23505') {
      return res.status(409).json({
        erro: 'Você já tem uma máquina ativa. Remova-a para cadastrar outra.',
      });
    }
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao criar máquina' });
  }
};

// GET /maquinas/status
const status = async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT ID_MAQUINA, NOME, ULTIMO_CONTATO,
              (ULTIMO_CONTATO IS NOT NULL
               AND ULTIMO_CONTATO > NOW() - INTERVAL '15 seconds') AS ONLINE,
              CASE WHEN ULTIMO_CONTATO IS NULL THEN NULL
                   ELSE EXTRACT(EPOCH FROM (NOW() - ULTIMO_CONTATO))::int
              END AS SEGUNDOS_DESDE_CONTATO
       FROM MAQUINA
       WHERE ID_USUARIO = $1 AND SITUACAO = 'A'
       ORDER BY ID_MAQUINA`,
      [req.usuarioId]
    );
    res.json(r.rows);
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao buscar status' });
  }
};

// PUT /maquinas/:id
const renomear = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const nome = limparNome(req.body.nome);

    if (!Number.isInteger(id)) {
      return res.status(400).json({ erro: 'Máquina inválida' });
    }
    if (!nome) {
      return res.status(400).json({ erro: 'Informe o nome da máquina' });
    }

    const r = await pool.query(
      `UPDATE MAQUINA
       SET NOME = $1, ULTIMA_MODIFICACAO = NOW()
       WHERE ID_MAQUINA = $2 AND ID_USUARIO = $3 AND SITUACAO = 'A'
       RETURNING ID_MAQUINA, NOME`,
      [nome, id, req.usuarioId]
    );

    if (r.rows.length === 0) {
      return res.status(404).json({ erro: 'Máquina não encontrada' });
    }
    res.json(r.rows[0]);
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao renomear máquina' });
  }
};

// POST /maquinas/:id/chave
// gera uma chave nova
const novaChave = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ erro: 'Máquina inválida' });
    }

    const { chave, hash } = gerarChave();

    const r = await pool.query(
      `UPDATE MAQUINA
       SET CHAVE_HASH = $1, ULTIMO_CONTATO = NULL, ULTIMA_MODIFICACAO = NOW()
       WHERE ID_MAQUINA = $2 AND ID_USUARIO = $3 AND SITUACAO = 'A'
       RETURNING ID_MAQUINA, NOME`,
      [hash, id, req.usuarioId]
    );

    if (r.rows.length === 0) {
      return res.status(404).json({ erro: 'Máquina não encontrada' });
    }

    res.json({
      id_maquina: r.rows[0].id_maquina,
      nome: r.rows[0].nome,
      chave,
      aviso: 'Guarde esta chave: ela não será mostrada novamente.',
    });
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao gerar nova chave' });
  }
};

// DELETE /maquinas/:id
const remover = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ erro: 'Máquina inválida' });
    }

    const r = await pool.query(
      `UPDATE MAQUINA
       SET SITUACAO = 'I', ULTIMA_MODIFICACAO = NOW()
       WHERE ID_MAQUINA = $1 AND ID_USUARIO = $2 AND SITUACAO = 'A'
       RETURNING ID_MAQUINA`,
      [id, req.usuarioId]
    );

    if (r.rows.length === 0) {
      return res.status(404).json({ erro: 'Máquina não encontrada' });
    }
    res.json({ ok: true });
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao remover máquina' });
  }
};

module.exports = { criar, status, renomear, novaChave, remover };