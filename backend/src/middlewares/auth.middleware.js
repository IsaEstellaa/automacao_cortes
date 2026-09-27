const jwt = require('jsonwebtoken');

const autenticar = (req, res, next) => {
  // pega o token do header
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ erro: 'Token não fornecido!' });
  }

  // formato: "Bearer TOKEN"
  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.usuarioId = decoded.id; // disponibiliza o id para os controllers
    next();
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido!' });
  }
};

module.exports = autenticar;