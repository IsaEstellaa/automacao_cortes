const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// middlewares
app.use(cors());
app.use(express.json());

// rota de teste
app.get('/', (req, res) => {
  res.json({ mensagem: 'API funcionando!' });
});

// inicia o servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});