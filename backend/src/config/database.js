const { Pool } = require("pg");
require("dotenv").config();

// Pool gerencia as conexões com o banco
// em vez de abrir e fechar uma conexão por vez,
// ele mantém um conjunto de conexões reutilizáveis
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// testa a conexão ao iniciar
pool.connect((err, client, release) => {
  if (err) {
    console.error("Erro ao conectar no banco:", err.message);
  } else {
    console.log("Banco de dados conectado!");
    release();
  }
});

module.exports = pool;
