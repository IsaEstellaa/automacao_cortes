const express = require('express');
const router = express.Router();
const autenticar = require('../middlewares/auth.middleware');
const controller = require('../controllers/dispositivos.controller');

router.post('/', autenticar, controller.registrar);
router.post('/remover', autenticar, controller.remover);

module.exports = router;