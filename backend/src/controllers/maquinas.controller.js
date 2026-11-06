const crypto = require('crypto');
const pool = require('../config/database');

// POST /maquinas
const criar = async (req, res) => {
  try {
    const nome = (req.body.nome || 'Minha máquina').trim().slice(0, 100);
    const chave = crypto.randomBytes(24).toString('hex');
    const hash = crypto.createHash('sha256').update(chave).digest('hex');

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
    console.error(erro);
    res.status(500).json({ erro: 'Erro ao criar máquina' });
  }
};

// GET /maquinas/status  (online = contato nos últimos 15 s)
// TODO: REVER
const status = async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT ID_MAQUINA, NOME, ULTIMO_CONTATO,
              (ULTIMO_CONTATO IS NOT NULL
               AND ULTIMO_CONTATO > NOW() - INTERVAL '15 seconds') AS ONLINE
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

module.exports = { criar, status };