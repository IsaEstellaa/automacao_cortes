const pool = require('../config/database');

// tipos de notificações aceitos:
// A -> Alerta
// I -> Info
// E -> Erro
// S -> Sucesso
// P -> Padrão
const TIPOS = ['A', 'I', 'E', 'S', 'P'];

// ============================================
// cria uma notificação (uso interno do sistema)
// ============================================
const criarNotificacao = async (
  { idUsuario, mensagem, tipo = 'P', idPeca = null, idCorte = null },
  db = pool
) => {
  if (!TIPOS.includes(tipo)) {
    throw new Error(`Tipo de notificação inválido: ${tipo}`);
  }

  if (!mensagem || mensagem.trim() === '') {
    throw new Error('Mensagem da notificação é obrigatória');
  }

  const resultado = await db.query(
    `INSERT INTO NOTIFICACOES (ID_USUARIO, ID_PECA, ID_CORTE, TIPO, MENSAGEM)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [idUsuario, idPeca, idCorte, tipo, mensagem.trim()]
  );

  return resultado.rows[0];
};

module.exports = { criarNotificacao, TIPOS };