const express = require('express');
const router = express.Router();
const {
  listar,
  contar,
  marcarVisualizada,
  marcarTodasVisualizadas,
} = require('../controllers/notificacoes.controller');
const autenticar = require('../middlewares/auth.middleware');

router.use(autenticar);

router.get('/', listar);
router.get('/contagem', contar);
router.patch('/visualizar-todas', marcarTodasVisualizadas);
router.patch('/:id/visualizada', marcarVisualizada);

module.exports = router;