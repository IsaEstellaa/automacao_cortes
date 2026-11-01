const receberFoto = require('../middlewares/upload.middleware');
const express = require('express');
const router = express.Router();
const { cadastrar, login, buscarPerfil, atualizarPerfil } = require('../controllers/usuario.controller');
const autenticar = require('../middlewares/auth.middleware');
const { enviarFotoPerfil, removerFotoPerfil } = require('../controllers/usuario.controller');

// rotas públicas (sem token)
router.post('/cadastrar', cadastrar);
router.post('/login', login);

// rotas privadas (com token)
router.get('/perfil', autenticar, buscarPerfil);
router.put('/perfil', autenticar, atualizarPerfil);
router.put('/perfil/foto', autenticar, receberFoto, enviarFotoPerfil);
router.delete('/perfil/foto', autenticar, removerFotoPerfil);

module.exports = router;