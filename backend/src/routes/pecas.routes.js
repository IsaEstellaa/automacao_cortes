const express = require('express');
const router = express.Router();
const { criar, listar, buscarPorId, atualizar, excluir, adicionarFoto, excluirFoto } = require('../controllers/pecas.controller');
const autenticar = require('../middlewares/auth.middleware');
const receberFoto = require('../middlewares/upload.middleware');


// todas as rotas de peça exigem login
router.use(autenticar);

router.post('/', criar);
router.get('/', listar);
router.get('/:id', buscarPorId);
router.put('/:id', atualizar);
router.delete('/:id', excluir);
router.post('/:id/fotos', receberFoto, adicionarFoto);
router.delete('/:id/fotos/:idFoto', excluirFoto);

module.exports = router;