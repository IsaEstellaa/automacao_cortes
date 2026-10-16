const pool = require('../config/database');

// ============================================
// listar notificações do usuário
// ============================================
const listar = async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT * FROM NOTIFICACOES
       WHERE ID_USUARIO = $1
       ORDER BY DATA_CADASTRO DESC, ID_NOTIFICACAO DESC
       LIMIT 100`,
      [req.usuarioId]
    );

    return res.status(200).json(resultado.rows);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// contar notificações não visualizadas
// ============================================
const contar = async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT COUNT(*)::int AS nao_visualizadas
       FROM NOTIFICACOES
       WHERE ID_USUARIO = $1 AND VISUALIZADA = 'N'`,
      [req.usuarioId]
    );

    return res.status(200).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// marcar uma notificação como vista
// ============================================
const marcarVisualizada = async (req, res) => {
  const id = Number(req.params.id);

  if (!Number.isInteger(id)) {
    return res.status(400).json({ erro: 'Id da notificação inválido!' });
  }

  try {
    const resultado = await pool.query(
      `UPDATE NOTIFICACOES
       SET VISUALIZADA = 'S',
           HORA_VISUALIZACAO = CASE WHEN VISUALIZADA = 'S' THEN HORA_VISUALIZACAO ELSE NOW() END
       WHERE ID_NOTIFICACAO = $1 AND ID_USUARIO = $2
       RETURNING *`,
      [id, req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Notificação não encontrada!' });
    }

    return res.status(200).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// marcar todas como vistas
// ============================================
const marcarTodasVisualizadas = async (req, res) => {
  try {
    const resultado = await pool.query(
      `UPDATE NOTIFICACOES
       SET VISUALIZADA = 'S', HORA_VISUALIZACAO = NOW()
       WHERE ID_USUARIO = $1 AND VISUALIZADA = 'N'`,
      [req.usuarioId]
    );

    return res.status(200).json({ atualizadas: resultado.rowCount });

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

module.exports = { listar, contar, marcarVisualizada, marcarTodasVisualizadas };