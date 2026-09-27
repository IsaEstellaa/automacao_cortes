const pool = require('./database');

const criarTabelas = async () => {
  try {
    // USUARIO
    await pool.query(`
      CREATE TABLE IF NOT EXISTS USUARIO (
        ID_USUARIO SERIAL PRIMARY KEY,
        NOME VARCHAR(100) NOT NULL,
        EMAIL VARCHAR(100) NOT NULL UNIQUE,
        DESCRICAO TEXT,
        TELEFONE VARCHAR(20),
        SENHA VARCHAR(255) NOT NULL,
        DATA_NASC DATE,
        SEXO CHAR(1),
        SITUACAO CHAR(1) DEFAULT 'A',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        DATA_EXCLUSAO TIMESTAMP DEFAULT NULL,
        ULTIMA_MODIFICACAO TIMESTAMP DEFAULT NOW(),
        URL_FOTO TEXT
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN USUARIO.SEXO IS 'M = Masculino, F = Feminino';
      COMMENT ON COLUMN USUARIO.SITUACAO IS 'A = Ativo, I = Inativo, P = Pendente';
    `);
    console.log('✅ Tabela USUARIO criada!');

    // MATERIAL
    await pool.query(`
      CREATE TABLE IF NOT EXISTS MATERIAL (
        ID_MATERIAL SERIAL PRIMARY KEY,
        ID_USUARIO INT REFERENCES USUARIO(ID_USUARIO),
        NOME VARCHAR(100) NOT NULL,
        ESPESSURA FLOAT,
        GRAMATURA FLOAT NOT NULL,
        OBSERVACAO TEXT,
        STATUS CHAR(1) DEFAULT 'A'
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN MATERIAL.STATUS IS 'A = Ativo, I = Inativo';
    `);
    console.log('✅ Tabela MATERIAL criada!');

    // PECA
    await pool.query(`
      CREATE TABLE IF NOT EXISTS PECA (
        ID_PECA SERIAL PRIMARY KEY,
        ID_USUARIO INT REFERENCES USUARIO(ID_USUARIO),
        NOME VARCHAR(100) NOT NULL,
        DESCRICAO TEXT,
        SITUACAO CHAR(1) DEFAULT 'A',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        ULTIMA_MODIFICACAO TIMESTAMP DEFAULT NOW()
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN PECA.SITUACAO IS 'A = Ativo, I = Inativo';
    `);
    console.log('✅ Tabela PECA criada!');

    // FOTOS_PECA
    await pool.query(`
      CREATE TABLE IF NOT EXISTS FOTOS_PECA (
        ID_FOTO SERIAL PRIMARY KEY,
        ID_PECA INT REFERENCES PECA(ID_PECA),
        URL_PECA TEXT NOT NULL,
        SITUACAO CHAR(1) DEFAULT 'A',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        ULTIMA_MODIFICACAO TIMESTAMP DEFAULT NOW()
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN FOTOS_PECA.SITUACAO IS 'A = Ativo, I = Inativo';
    `);
    console.log('✅ Tabela FOTOS_PECA criada!');

    // CORTE
    await pool.query(`
      CREATE TABLE IF NOT EXISTS CORTE (
        ID_CORTE SERIAL PRIMARY KEY,
        ID_PECA INT REFERENCES PECA(ID_PECA),
        ID_CORTE_ANTERIOR INT REFERENCES CORTE(ID_CORTE),
        QUANTIDADE INT NOT NULL,
        METRAGEM FLOAT NOT NULL,
        SITUACAO CHAR(1) DEFAULT 'A',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        DATA_EXCLUSAO TIMESTAMP
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN CORTE.SITUACAO IS 'A = Ativo, I = Inativo';
    `);
    console.log('✅ Tabela CORTE criada!');

    // EXECUCAO_CORTE
    await pool.query(`
      CREATE TABLE IF NOT EXISTS EXECUCAO_CORTE (
        ID_EXECUCAO SERIAL PRIMARY KEY,
        ID_CORTE INT REFERENCES CORTE(ID_CORTE),
        ID_MATERIAL INT REFERENCES MATERIAL(ID_MATERIAL),
        SITUACAO CHAR(1) DEFAULT 'A',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        DATA_INICIO TIMESTAMP,
        DATA_FIM TIMESTAMP
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN EXECUCAO_CORTE.SITUACAO IS 'A = Aguardando, P = Processando, C = Concluída, E = Erro';
    `);
    console.log('✅ Tabela EXECUCAO_CORTE criada!');

    // FIO
    await pool.query(`
      CREATE TABLE IF NOT EXISTS FIO (
        ID_FIO SERIAL PRIMARY KEY,
        ID_EXECUCAO INT REFERENCES EXECUCAO_CORTE(ID_EXECUCAO),
        STATUS CHAR(1) DEFAULT 'P'
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN FIO.STATUS IS 'P = Pendente, C = Concluído, E = Erro';
    `);
    console.log('✅ Tabela FIO criada!');

    // RETENTATIVA
    // ID_EXECUCAO -> Qual execução de corte está relacionada à retentativa
    // ID_FIO -> Qual fio está sendo retentado
    await pool.query(`
      CREATE TABLE IF NOT EXISTS RETENTATIVA (
        ID_RETENTATIVA SERIAL PRIMARY KEY,
        ID_EXECUCAO INT REFERENCES EXECUCAO_CORTE(ID_EXECUCAO),
        ID_FIO INT REFERENCES FIO(ID_FIO),
        SITUACAO CHAR(1) DEFAULT 'P',
        DATA_CADASTRO TIMESTAMP DEFAULT NOW(),
        DATA_INICIO TIMESTAMP,
        DATA_FIM TIMESTAMP
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN RETENTATIVA.SITUACAO IS 'P = Pendente, C = Concluída, E = Erro';
    `);
    console.log('✅ Tabela RETENTATIVA criada!');

    // LOG_FIOS
    // ID_FIO -> Qual fio está relacionado ao log
    // ID_RETENTATIVA -> Qual retentativa está relacionada ao log (pode ser NULL se não for uma retentativa)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS LOG_FIOS (
        ID_LOG SERIAL PRIMARY KEY,
        ID_FIO INT REFERENCES FIO(ID_FIO),
        ID_RETENTATIVA INT REFERENCES RETENTATIVA(ID_RETENTATIVA),
        MENSAGEM TEXT NOT NULL,
        DATA_HORA TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ Tabela LOG_FIOS criada!');

    // NOTIFICACOES
    await pool.query(`
      CREATE TABLE IF NOT EXISTS NOTIFICACOES (
        ID_NOTIFICACAO SERIAL PRIMARY KEY,
        ID_USUARIO INT REFERENCES USUARIO(ID_USUARIO),
        ID_PECA INT REFERENCES PECA(ID_PECA),
        ID_CORTE INT REFERENCES CORTE(ID_CORTE),
        TIPO CHAR(1) NOT NULL DEFAULT 'P',
        MENSAGEM TEXT NOT NULL,
        VISUALIZADA CHAR(1) DEFAULT 'N',
        HORA_VISUALIZACAO TIMESTAMP,
        DATA_CADASTRO TIMESTAMP DEFAULT NOW()
      );
    `);
    await pool.query(`
      COMMENT ON COLUMN NOTIFICACOES.TIPO IS 'A = Alerta, I = Informação, E = Erro, S = Sucesso, P = Padrão';
      COMMENT ON COLUMN NOTIFICACOES.VISUALIZADA IS 'S = Sim, N = Não';
    `);
    console.log('✅ Tabela NOTIFICACOES criada!');

    console.log('\n🎉 Todas as tabelas criadas com sucesso!');
    process.exit(0);

  } catch (err) {
    console.error('Erro ao criar tabelas:', err.message);
    process.exit(1);
  }
};

criarTabelas();