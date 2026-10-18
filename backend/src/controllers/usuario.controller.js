const pool = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// ============================================
// cadastro de usuário
// ============================================
const cadastrar = async (req, res) => {
  const { nome, email, senha, telefone, data_nasc, sexo } = req.body;

  if (typeof nome !== 'string' || nome.trim() === '') {
    return res.status(400).json({ erro: 'Nome é obrigatório!' });
  }

  if (typeof email !== 'string' || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) {
    return res.status(400).json({ erro: 'Informe um e-mail válido!' });
  }

  if (typeof senha !== 'string' || senha.length < 6) {
    return res.status(400).json({ erro: 'A senha deve ter pelo menos 6 caracteres!' });
  }

  if (Buffer.byteLength(senha, 'utf8') > 72) {
    return res.status(400).json({ erro: 'A senha é muito longa!' });
  }

  const nomeLimpo = nome.trim();
  const emailLimpo = email.trim();

  try {
    // verifica se o email já existe
    const emailExiste = await pool.query(
      'SELECT ID_USUARIO FROM USUARIO WHERE EMAIL = $1',
      [emailLimpo]
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
      [nomeLimpo, emailLimpo, senhaCriptografada, telefone, data_nasc, sexo]
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

// ============================================
// atualizar perfil: nome, descrição, telefone, data de nascimento e sexo
// ============================================
const SEXOS = ['F', 'M', 'O'];

const dataValida = (texto) => {
  if (typeof texto !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;

  const [ano, mes, dia] = texto.split('-').map(Number);
  const data = new Date(Date.UTC(ano, mes - 1, dia));

  if (
    data.getUTCFullYear() !== ano ||
    data.getUTCMonth() !== mes - 1 ||
    data.getUTCDate() !== dia
  ) {
    return false;
  }

  return ano >= 1900 && data <= new Date();
};

const atualizarPerfil = async (req, res) => {
  const { nome, descricao, telefone, data_nasc, sexo } = req.body;

  const nomeLimpo = typeof nome === 'string' ? nome.trim() : '';
  if (nomeLimpo.length < 2 || nomeLimpo.length > 100) {
    return res.status(400).json({ erro: 'O nome deve ter entre 2 e 100 caracteres!' });
  }

  let descricaoFinal = null;
  if (descricao !== undefined && descricao !== null) {
    if (typeof descricao !== 'string') {
      return res.status(400).json({ erro: 'Descrição inválida!' });
    }
    descricaoFinal = descricao.trim() || null;
    if (descricaoFinal && descricaoFinal.length > 300) {
      return res.status(400).json({ erro: 'A descrição pode ter no máximo 300 caracteres!' });
    }
  }

  let telefoneFinal = null;
  if (telefone !== undefined && telefone !== null && telefone !== '') {
    const digitos = typeof telefone === 'string' ? telefone.replace(/\D/g, '') : '';
    if (digitos.length < 10 || digitos.length > 11) {
      return res.status(400).json({ erro: 'Telefone inválido! Informe o DDD e o número.' });
    }
    telefoneFinal = digitos;
  }

  let dataFinal = null;
  if (data_nasc !== undefined && data_nasc !== null && data_nasc !== '') {
    if (!dataValida(data_nasc)) {
      return res.status(400).json({ erro: 'Data de nascimento inválida!' });
    }
    dataFinal = data_nasc;
  }

  let sexoFinal = null;
  if (sexo !== undefined && sexo !== null && sexo !== '') {
    if (!SEXOS.includes(sexo)) {
      return res.status(400).json({ erro: 'Sexo inválido!' });
    }
    sexoFinal = sexo;
  }

  try {
    const resultado = await pool.query(
      `UPDATE USUARIO
       SET NOME = $1, DESCRICAO = $2, TELEFONE = $3, DATA_NASC = $4, SEXO = $5,
           ULTIMA_MODIFICACAO = NOW()
       WHERE ID_USUARIO = $6 AND SITUACAO = 'A'
       RETURNING ID_USUARIO, NOME, EMAIL, DESCRICAO, TELEFONE,
                 DATA_NASC, SEXO, URL_FOTO, DATA_CADASTRO`,
      [nomeLimpo, descricaoFinal, telefoneFinal, dataFinal, sexoFinal, req.usuarioId]
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

module.exports = { cadastrar, login, buscarPerfil, atualizarPerfil };