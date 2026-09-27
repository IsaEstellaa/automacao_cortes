const pool = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// ============================================
// cadastro de usuário
// ============================================
const cadastrar = async (req, res) => {
  const { nome, email, senha, telefone, data_nasc, sexo } = req.body;

  try {
    // verifica se o email já existe
    const emailExiste = await pool.query(
      'SELECT ID_USUARIO FROM USUARIO WHERE EMAIL = $1',
      [email]
    );

    if (emailExiste.rows.length > 0) {
      return res.status(400).json({ erro: 'Email já cadastrado!' });
    }

    // criptografa a senha
    // TODO: Talvez, utilizar uma função de hash mais forte
    const senhaCriptografada = await bcrypt.hash(senha, 10);

    // insere o usuário
    const resultado = await pool.query(
      `INSERT INTO USUARIO (NOME, EMAIL, SENHA, TELEFONE, DATA_NASC, SEXO)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING ID_USUARIO, NOME, EMAIL`,
      [nome, email, senhaCriptografada, telefone, data_nasc, sexo]
    );

    const usuario = resultado.rows[0];

    // gera o token JWT
    const token = jwt.sign(
      { id: usuario.id_usuario },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(201).json({ usuario, token });

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// login
// ============================================
const login = async (req, res) => {
  const { email, senha } = req.body;

  try {
    // busca o usuário pelo email
    const resultado = await pool.query(
      'SELECT * FROM USUARIO WHERE EMAIL = $1 AND SITUACAO = $2',
      [email, 'A']
    );

    if (resultado.rows.length === 0) {
      return res.status(401).json({ erro: 'Email ou senha inválidos!' });
    }

    const usuario = resultado.rows[0];

    // verifica a senha
    const senhaValida = await bcrypt.compare(senha, usuario.senha);

    if (!senhaValida) {
      return res.status(401).json({ erro: 'Email ou senha inválidos!' });
    }

    // gera o token JWT
    const token = jwt.sign(
      { id: usuario.id_usuario },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // remove a senha da resposta
    delete usuario.senha;

    return res.status(200).json({ usuario, token });

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

// ============================================
// buscar perfil
// ============================================
const buscarPerfil = async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT ID_USUARIO, NOME, EMAIL, DESCRICAO, TELEFONE, 
              DATA_NASC, SEXO, URL_FOTO, DATA_CADASTRO
       FROM USUARIO WHERE ID_USUARIO = $1`,
      [req.usuarioId]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado!' });
    }

    return res.status(200).json(resultado.rows[0]);

  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ erro: 'Erro interno do servidor' });
  }
};

module.exports = { cadastrar, login, buscarPerfil };