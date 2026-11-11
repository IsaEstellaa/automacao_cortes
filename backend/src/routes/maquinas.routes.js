const express = require('express');
const router = express.Router();
const autenticar = require('../middlewares/auth.middleware');
const controller = require('../controllers/maquinas.controller');

router.post('/', autenticar, controller.criar);
router.get('/status', autenticar, controller.status);
router.put('/:id', autenticar, controller.renomear);
router.post('/:id/chave', autenticar, controller.novaChave);
router.delete('/:id', autenticar, controller.remover);

module.exports = router;