const pool = require('../config/database');

// registro do token
const registrar = async (req, res) => {
  const { token } = req.body;

  if (!token || typeof token !== 'string') {
    return res.status(400).json({ erro: 'Token é obrigatório' });
  }

  try {
    await pool.query(
      `INSERT INTO DISPOSITIVO (ID_USUARIO, TOKEN_FCM)
       VALUES ($1, $2)
       ON CONFLICT (TOKEN_FCM)
       DO UPDATE SET ID_USUARIO = EXCLUDED.ID_USUARIO,
                     ULTIMA_MODIFICACAO = NOW()`,
      [req.usuarioId, token]
    );
    res.status(204).end();
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao registrar dispositivo' });
  }
};

// remocao
const remover = async (req, res) => {
  const { token } = req.body;

  if (!token || typeof token !== 'string') {
    return res.status(400).json({ erro: 'Token é obrigatório' });
  }

  try {
    await pool.query(
      'DELETE FROM DISPOSITIVO WHERE TOKEN_FCM = $1 AND ID_USUARIO = $2',
      [token, req.usuarioId]
    );
    res.status(204).end();
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao remover dispositivo' });
  }
};

module.exports = { registrar, remover };