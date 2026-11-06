const crypto = require('crypto');
const pool = require('../config/database');

const autenticarMaquina = async (req, res, next) => {
  try {
    const chave = req.headers['x-maquina-chave'];
    if (!chave) {
      return res.status(401).json({ erro: 'Chave da máquina ausente' });
    }

    const hash = crypto.createHash('sha256').update(chave).digest('hex');

    const resultado = await pool.query(
      `UPDATE MAQUINA
       SET ULTIMO_CONTATO = NOW()
       WHERE CHAVE_HASH = $1 AND SITUACAO = 'A'
       RETURNING ID_MAQUINA, ID_USUARIO`,
      [hash]
    );

    if (resultado.rows.length === 0) {
      return res.status(401).json({ erro: 'Chave da máquina inválida' });
    }

    req.maquina = {
      id: resultado.rows[0].id_maquina,
      idUsuario: resultado.rows[0].id_usuario,
    };
    next();
  } catch (erro) {
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao autenticar a máquina' });
  }
};

module.exports = autenticarMaquina;