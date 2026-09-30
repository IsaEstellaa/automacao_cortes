const pool = require('../config/database');

// ============================================
// criar material
// ============================================
const criar = async (req, res) => {
  const { nome, gramatura, espessura, observacao } = req.body;

  // validações
  if (!nome || nome.trim() === '') {
    return res.status(400).json({ erro: 'Nome é obrigatório!' });
  }

  if (gramatura === undefined || gramatura === null || isNaN(gramatura) || Number(gramatura) <= 0) {
    return res.status(400).json({ erro: 'Gramatura é obrigatória e deve ser maior que zero!' });
  }

  if (espessura !== undefined && espessura !== null && (isNaN(espessura) || Number(espessura) <= 0)) {
    return res.status(400).json({ erro: 'Espessura deve ser um número maior que zero!' });
  }

  try {
    const resultado = await pool.query(
      `INSERT INTO MATERIAL (ID_USUARIO, NOME, GRAMATURA, ESPESSURA, OBSERVACAO)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.usuarioId, nome.trim(), gramatura, espessura ?? null, observacao ?? null]
    );

    return res.status(201).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// listar materiais do usuário (só ativos)
// ============================================
const listar = async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT * FROM MATERIAL
       WHERE ID_USUARIO = $1 AND STATUS = 'A'
       ORDER BY NOME`,
      [req.usuarioId]
    );

    return res.status(200).json(resultado.rows);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// buscar um material por id
// ============================================
const buscarPorId = async (req, res) => {
  const { id } = req.params;

  try {
    const resultado = await pool.query(
      `SELECT * FROM MATERIAL
       WHERE ID_MATERIAL = $1 AND ID_USUARIO = $2 AND STATUS = 'A'`,
      [id, req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Material não encontrado!' });
    }

    return res.status(200).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// atualizar material
// ============================================
const atualizar = async (req, res) => {
  const { id } = req.params;
  const { nome, gramatura, espessura, observacao } = req.body;

  if (!nome || nome.trim() === '') {
    return res.status(400).json({ erro: 'Nome é obrigatório!' });
  }

  if (gramatura === undefined || gramatura === null || isNaN(gramatura) || Number(gramatura) <= 0) {
    return res.status(400).json({ erro: 'Gramatura é obrigatória e deve ser maior que zero!' });
  }

  if (espessura !== undefined && espessura !== null && (isNaN(espessura) || Number(espessura) <= 0)) {
    return res.status(400).json({ erro: 'Espessura deve ser um número maior que zero!' });
  }

  try {
    const resultado = await pool.query(
      `UPDATE MATERIAL
       SET NOME = $1, GRAMATURA = $2, ESPESSURA = $3, OBSERVACAO = $4
       WHERE ID_MATERIAL = $5 AND ID_USUARIO = $6 AND STATUS = 'A'
       RETURNING *`,
      [nome.trim(), gramatura, espessura ?? null, observacao ?? null, id, req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Material não encontrado!' });
    }

    return res.status(200).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// excluir material (soft delete)
// ============================================
const excluir = async (req, res) => {
  const { id } = req.params;

  try {
    const resultado = await pool.query(
      `UPDATE MATERIAL
       SET STATUS = 'I'
       WHERE ID_MATERIAL = $1 AND ID_USUARIO = $2 AND STATUS = 'A'
       RETURNING ID_MATERIAL`,
      [id, req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Material não encontrado!' });
    }

    return res.status(200).json({ mensagem: 'Material excluído com sucesso!' });

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

module.exports = { criar, listar, buscarPorId, atualizar, excluir };