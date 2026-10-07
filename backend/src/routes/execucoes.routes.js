const express = require('express');
const router = express.Router();
const { criar, listarFila, listarHistorico, detalhes, retentar } = require('../controllers/execucoes.controller');
const autenticar = require('../middlewares/auth.middleware');

// todas as rotas de execução exigem login
router.use(autenticar);

router.post('/', criar);
router.get('/fila', listarFila);
router.get('/historico', listarHistorico);
router.get('/:id/detalhes', detalhes);
router.post('/:id/retentar', retentar);

module.exports = router;