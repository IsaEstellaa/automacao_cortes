const pool = require('../config/database');
const { notificar } = require('./notificar.service');
const { enviarAviso } = require('./push.service');

const JANELA_ONLINE_MS = 15000;
const maquinas = new Map();

// aviso silencioso para o app recarregar
const avisar = (idUsuario, evento) => {
  if (!idUsuario) return;
  enviarAviso(idUsuario, evento).catch(() => {});
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

const avisarMaquinaOffline = async (idMaquina, idUsuario) => {
  try {
    const ativa = await pool.query(
      `SELECT 1 FROM MAQUINA WHERE ID_MAQUINA = $1 AND SITUACAO = 'A'`,
      [idMaquina]
    );
    if (ativa.rows.length === 0) {
      maquinas.delete(idMaquina);
      return;
    }

    await notificar({
      idUsuario,
      tipo: 'A',
      titulo: 'Máquina offline',
      mensagem: 'Não conseguimos falar com a sua máquina. Confira a energia e o Wi-Fi.',
    });
  } catch (erro) {
    console.error('[notificar] máquina offline:', erro.message);
  }
};

const iniciarVigiaMaquinas = () => {
  setInterval(() => {
    const agora = Date.now();
    for (const [idMaquina, m] of maquinas) {
      if (m.online && agora - m.ultimoContato > JANELA_ONLINE_MS) {
        m.online = false;
        avisar(m.idUsuario, 'status');
        avisarMaquinaOffline(idMaquina, m.idUsuario);
      }
    }
  }, 5000);
};

const iniciarRealtime = () => {
  iniciarVigiaMaquinas();
};

module.exports = { iniciarRealtime, avisar, registrarContato };