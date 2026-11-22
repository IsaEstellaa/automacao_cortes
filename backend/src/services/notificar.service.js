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

// fim da retentativa
const notificarFimDaRetentativa = async ({ idUsuario, idExecucao, concluidos, falhas }) => {
  const total = concluidos + falhas;

  const origem = await pool.query(
    `SELECT C.ID_CORTE, C.ID_PECA
     FROM EXECUCAO_CORTE E
     JOIN CORTE C ON C.ID_CORTE = E.ID_CORTE
     WHERE E.ID_EXECUCAO = $1`,
    [idExecucao]
  );
  const idCorte = origem.rows[0]?.id_corte ?? null;
  const idPeca = origem.rows[0]?.id_peca ?? null;

  if (falhas === 0) {
    return notificar({
      idUsuario, idPeca, idCorte,
      tipo: 'S',
      titulo: 'Retentativa concluída',
      mensagem:
        total === 1
          ? 'O fio que falhou foi cortado com sucesso na nova tentativa.'
          : `Os ${total} fios que falharam foram cortados com sucesso na nova tentativa.`,
    });
  }

  if (concluidos === 0) {
    return notificar({
      idUsuario, idPeca, idCorte,
      tipo: 'E',
      titulo: 'Retentativa com falha',
      mensagem:
        total === 1
          ? 'O fio não foi cortado na nova tentativa. Verifique a máquina e o fio antes de tentar de novo.'
          : `Os ${total} fios não foram cortados na nova tentativa. Verifique a máquina e o fio antes de tentar de novo.`,
    });
  }

  return notificar({
    idUsuario, idPeca, idCorte,
    tipo: 'A',
    titulo: 'Retentativa não concluída',
    mensagem: `${concluidos} de ${total} fios foram cortados na nova tentativa. ${
      falhas === 1 ? '1 falhou de novo' : `${falhas} falharam novamente`
    }. Confira os detalhes no histórico.`,
  });
};

module.exports = { notificar, entregarNotificacao, notificarFimDoLote, notificarFimDaRetentativa };