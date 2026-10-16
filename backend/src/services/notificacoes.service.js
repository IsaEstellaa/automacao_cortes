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

// caso nao informe o titulo
const TITULOS_PADRAO = {
  A: 'Alerta',
  I: 'Informação',
  E: 'Erro',
  S: 'Sucesso',
  P: 'Notificação',
};

const criarNotificacao = async (
  { idUsuario, titulo = null, mensagem, tipo = 'P', idPeca = null, idCorte = null },
  db = pool
) => {
  if (!TIPOS.includes(tipo)) {
    throw new Error(`Tipo de notificação inválido: ${tipo}`);
  }

  if (!mensagem || mensagem.trim() === '') {
    throw new Error('Mensagem da notificação é obrigatória');
  }

  const tituloFinal = titulo && titulo.trim() !== ''
    ? titulo.trim().slice(0, 80)
    : TITULOS_PADRAO[tipo];

  const resultado = await db.query(
    `INSERT INTO NOTIFICACOES (ID_USUARIO, ID_PECA, ID_CORTE, TIPO, TITULO, MENSAGEM)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [idUsuario, idPeca, idCorte, tipo, tituloFinal, mensagem.trim()]
  );

  return resultado.rows[0];
};

module.exports = { criarNotificacao, TIPOS };