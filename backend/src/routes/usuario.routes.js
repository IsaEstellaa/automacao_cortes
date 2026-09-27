const express = require('express');
const router = express.Router();
const { cadastrar, login, buscarPerfil } = require('../controllers/usuario.controller');
const autenticar = require('../middlewares/auth.middleware');

// rotas públicas (sem token)
router.post('/cadastrar', cadastrar);
router.post('/login', login);

// rotas privadas (com token)
router.get('/perfil', autenticar, buscarPerfil);

module.exports = router;