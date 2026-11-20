const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const pool = require('../config/database');

let pronto = false;

function iniciar() {
  if (pronto) return true;

  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (!b64) {
    console.warn('[push] FIREBASE_SERVICE_ACCOUNT_BASE64 não definida: push desativado');
    return false;
  }

  try {
    const credencial = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
    initializeApp({ credential: cert(credencial) });
    pronto = true;
    console.log('[push] Firebase pronto');
    return true;
  } catch (erro) {
    console.error('[push] credencial inválida:', erro.message);
    return false;
  }
}

// envia para todos os celulares
async function enviarPush(idUsuario, { titulo, corpo, dados = {} }) {
  if (!iniciar()) return;

  try {
    const { rows } = await pool.query(
      'SELECT TOKEN_FCM FROM DISPOSITIVO WHERE ID_USUARIO = $1',
      [idUsuario]
    );
    const tokens = rows.map((r) => r.token_fcm);
    if (tokens.length === 0) return;

    const resposta = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: titulo, body: corpo },
      data: Object.fromEntries(
        Object.entries(dados).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'automacao_cortes' },
      },
    });

    // apaga tokens
    const invalidos = [];
    resposta.responses.forEach((r, i) => {
      if (r.success) return;
      const codigo = r.error && r.error.code;
      if (
        codigo === 'messaging/registration-token-not-registered' ||
        codigo === 'messaging/invalid-registration-token'
      ) {
        invalidos.push(tokens[i]);
      } else {
        console.warn('[push] falha ao enviar:', codigo);
      }
    });

    if (invalidos.length > 0) {
      await pool.query(
        'DELETE FROM DISPOSITIVO WHERE TOKEN_FCM = ANY($1)',
        [invalidos]
      );
    }
  } catch (erro) {
    console.error('[push] erro ao enviar:', erro.message);
  }
}

module.exports = { iniciar, enviarPush };