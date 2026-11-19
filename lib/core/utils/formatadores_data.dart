const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

// "Hoje", "Ontem" ou "xx de novembro de 2026"
String formatarDia(DateTime dia) {
  final agora = DateTime.now();

  final hoje = DateTime.utc(agora.year, agora.month, agora.day);
  final alvo = DateTime.utc(dia.year, dia.month, dia.day);
  final diferenca = hoje.difference(alvo).inDays;

  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Ontem';

  return '${dia.day} de ${_meses[dia.month - 1]} de ${dia.year}';
}

// "xx/xx às xx:xx"
String formatarDiaHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)} às ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';