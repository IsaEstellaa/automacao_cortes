const express = require('express');
const router = express.Router();
const autenticarMaquina = require('../middlewares/maquina.middleware');
const controller = require('../controllers/maquina.controller');

router.get('/trabalho', autenticarMaquina, controller.trabalho);
router.post('/fios/:idFio/resultado', autenticarMaquina, controller.resultado);

module.exports = router;