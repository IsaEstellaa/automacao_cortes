const pool = require('../config/database');
const { criarNotificacao } = require('./notificacoes.service');
const { enviarPush } = require('./push.service');

const entregarNotificacao = async (notificacao) => {
  const { avisar } = require('./realtime.service');

  avisar(notificacao.id_usuario, 'notificacoes');

  await enviarPush(notificacao.id_usuario, {
    titulo: notificacao.titulo,
    corpo: notificacao.mensagem,
    dados: { tipo: notificacao.tipo },
  });
};

// salva no banco e entrega
const notificar = async (dados) => {
  const notificacao = await criarNotificacao(dados);
  await entregarNotificacao(notificacao);
  return notificacao;
};

// fim do lote
const notificarFimDoLote = async ({ idUsuario, idExecucao, houveErro, totalFios }) => {
  const origem = await pool.query(
    `SELECT C.ID_CORTE, C.ID_PECA
     FROM EXECUCAO_CORTE E
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     WHERE E.ID_EXECUCAO = $1`,
    [idExecucao]
  );
  const idCorte = origem.rows[0]?.id_corte ?? null;
  const idPeca = origem.rows[0]?.id_peca ?? null;

  if (houveErro) {
    return notificar({
      idUsuario, idPeca, idCorte,
      tipo: 'E',
      titulo: 'Corte com falha',
      mensagem: 'Alguns fios não foram cortados. Verifique a máquina e tente novamente.',
    });
  }

  // ainda existe trabalho na fila?
  const resta = await pool.query(
    `SELECT (
       EXISTS (
         SELECT 1 FROM EXECUCAO_CORTE E
         JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
         JOIN PECA P ON P.ID_PECA = C.ID_PECA
         WHERE P.ID_USUARIO = $1 AND E.SITUACAO IN ('A', 'P')
       )
       OR EXISTS (
         SELECT 1 FROM RETENTATIVA R
         JOIN EXECUCAO_CORTE E ON E.ID_EXECUCAO = R.ID_EXECUCAO
         JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
         JOIN PECA P ON P.ID_PECA = C.ID_PECA
         WHERE P.ID_USUARIO = $1 AND R.SITUACAO = 'P'
       )
     ) AS ainda_tem`,
    [idUsuario]
  );

  if (!resta.rows[0].ainda_tem) {
    return notificar({
      idUsuario, idPeca, idCorte,
      tipo: 'S',
      titulo: 'Fila concluída',
      mensagem: 'Todos os cortes da fila foram concluídos.',
    });
  }

  return notificar({
    idUsuario, idPeca, idCorte,
    tipo: 'S',
    titulo: 'Corte concluído',
    mensagem:
      totalFios === 1
        ? 'O fio foi cortado com sucesso.'
        : `Os ${totalFios} fios foram cortados com sucesso.`,
  });
};

module.exports = { notificar, entregarNotificacao, notificarFimDoLote };