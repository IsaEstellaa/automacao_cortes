const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

let io = null;

const JANELA_ONLINE_MS = 15000;
const maquinas = new Map();

const salaDoUsuario = (idUsuario) => `usuario:${idUsuario}`;

const avisar = (idUsuario, evento) => {
  if (!io || !idUsuario) return;
  io.to(salaDoUsuario(idUsuario)).emit(evento);
};

const registrarContato = (idMaquina, idUsuario) => {
  const agora = Date.now();
  const m = maquinas.get(idMaquina);

  if (!m || !m.online) {
    maquinas.set(idMaquina, { idUsuario, ultimoContato: agora, online: true });
    avisar(idUsuario, 'status');
  } else {
    m.ultimoContato = agora;
  }
};

const iniciarVigiaMaquinas = () => {
  setInterval(() => {
    const agora = Date.now();
    for (const m of maquinas.values()) {
      if (m.online && agora - m.ultimoContato > JANELA_ONLINE_MS) {
        m.online = false;
        avisar(m.idUsuario, 'status');
      }
    }
  }, 5000);
};

const iniciarRealtime = (servidorHttp) => {
  io = new Server(servidorHttp, {
    cors: { origin: '*' },
    pingInterval: 10000,
    pingTimeout: 8000,
  });

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token) return next(new Error('Token ausente'));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const idUsuario = decoded.id;

      if (!idUsuario) return next(new Error('Token inválido'));
      socket.data.idUsuario = idUsuario;
      next();
    } catch (erro) {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(salaDoUsuario(socket.data.idUsuario));
  });

  iniciarVigiaMaquinas();
};

module.exports = { iniciarRealtime, avisar, registrarContato };