const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');

const BUCKET = 'fotos';

let cliente = null;

const obterCliente = () => {
  if (!cliente) {
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_KEY) {
      throw new Error('SUPABASE_URL e SUPABASE_SERVICE_KEY precisam estar no .env');
    }

    cliente = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, {
      auth: { persistSession: false },
    });
  }

  return cliente;
};

// ============================================
// descobre o tipo da imagem pelo CONTEÚDO do arquivo
// ============================================
const detectarTipo = (buffer) => {
  if (!buffer || buffer.length < 12) return null;

  // JPEG
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return { ext: 'jpg', contentType: 'image/jpeg' };
  }

  // PNG
  const assinaturaPng = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (buffer.subarray(0, 8).equals(assinaturaPng)) {
    return { ext: 'png', contentType: 'image/png' };
  }

  // WebP
  if (
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP'
  ) {
    return { ext: 'webp', contentType: 'image/webp' };
  }

  return null;
};

// ============================================
// envia uma foto e devolve o endereço público
// ============================================
const enviarFoto = async (pasta, buffer, tipo) => {
  const caminho = `${pasta}/${crypto.randomUUID()}.${tipo.ext}`;

  const { error } = await obterCliente()
    .storage.from(BUCKET)
    .upload(caminho, buffer, {
      contentType: tipo.contentType,
      cacheControl: '31536000',
      upsert: false,
    });

  if (error) {
    throw new Error(`Falha ao enviar a foto: ${error.message}`);
  }

  const { data } = obterCliente().storage.from(BUCKET).getPublicUrl(caminho);
  return data.publicUrl;
};

// ============================================
// remove uma foto a partir do endereço público
// ============================================
const removerFoto = async (url) => {
  if (!url) return;

  const marcador = `/storage/v1/object/public/${BUCKET}/`;
  const posicao = url.indexOf(marcador);
  if (posicao === -1) return;

  const caminho = decodeURIComponent(url.slice(posicao + marcador.length));

  const { error } = await obterCliente().storage.from(BUCKET).remove([caminho]);
  if (error) {
    console.error('Falha ao remover a foto antiga:', error.message);
  }
};

module.exports = { detectarTipo, enviarFoto, removerFoto };