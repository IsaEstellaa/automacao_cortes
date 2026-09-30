const express = require('express');
const cors = require('cors');
require('dotenv').config();

const usuarioRoutes = require('./routes/usuario.routes');
const materiaisRoutes = require('./routes/materiais.routes');

const app = express();

// middlewares
app.use(cors());
app.use(express.json());

// rotas
app.use('/usuario', usuarioRoutes);
app.use('/materiais', materiaisRoutes);

app.get('/', (req, res) => {
  res.json({ mensagem: 'API funcionando!' });
});

// inicia o servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});