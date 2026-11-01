const multer = require('multer');

const LIMITE_MB = 5;

// a foto fica na memória só até ser enviada ao Storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: LIMITE_MB * 1024 * 1024, files: 1 },
});

const receberFoto = (req, res, next) => {
  upload.single('foto')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ erro: `A foto deve ter no máximo ${LIMITE_MB} MB!` });
      }
      return res.status(400).json({ erro: 'Não foi possível ler a foto enviada!' });
    }
    next();
  });
};

module.exports = receberFoto;