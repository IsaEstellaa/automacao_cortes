require('dotenv').config();
const { criarNotificacao } = require('./src/services/notificacoes.service');

criarNotificacao({ idUsuario: 1, mensagem: 'Teste da função', tipo: 'I' })
  .then((n) => { console.log(n); process.exit(0); })
  .catch((e) => { console.error(e.message); process.exit(1); });