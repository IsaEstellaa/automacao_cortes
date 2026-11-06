const express = require('express');
const router = express.Router();
const autenticar = require('../middlewares/auth.middleware');
const controller = require('../controllers/maquinas.controller');

router.post('/', autenticar, controller.criar);
router.get('/status', autenticar, controller.status);

module.exports = router;