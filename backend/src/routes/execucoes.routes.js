const express = require('express');
const router = express.Router();
const { criar } = require('../controllers/execucoes.controller');
const autenticar = require('../middlewares/auth.middleware');

// todas as rotas de execução exigem login
router.use(autenticar);

router.post('/', criar);

module.exports = router;