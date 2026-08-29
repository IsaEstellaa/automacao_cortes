import 'package:flutter/material.dart';

class AppColors {

  // ============================================
  // cores gerais
  // ============================================

  static const background = Color(0xFFE1D9CB);
  static const card = Color(0xFFF4EEE8);
  static const green = Color(0xFF7E8462);
  static const greenSelected = Color(0xFF4C5039);
  static const white = Color(0xFFF0ECE8);

  // textos -----
  static const textoSutil = Color.fromARGB(255, 178, 154, 137);
  static const textoPreto = Color(0xFF2B2B2B);


  // botoes -----

  static const buttonBrown = Color(0xFF987A64);

  // fitas -----
  static const fundoFitaVerde = Color(0xFFDFE2D4);
  static const listrasFitaVerde = Color.fromARGB(70, 32, 66, 31);
  static const fundoFitaRosa = Color.fromRGBO(180, 149, 121, 0.39);
  static const listrasFitaRosa = Color.fromARGB(115, 108, 66, 36);
  static const fundoFitaAmarelo = Color.fromRGBO(237, 234, 202, 0.769);
  static const listrasFitaAmarelo = Color.fromRGBO(118, 110, 45, 0.612);
  static const fundoFitaVermelho = Color.fromRGBO(233, 201, 196, 0.814);
  static const listrasFitaVermelho = Color.fromRGBO(121, 50, 34, 0.604);

  // tracejado
  static const tracejado = Color(0xFFB49579);

  // bordas
  static const bordaMarrom = Color.fromRGBO(180, 149, 121, 0.60);

  // gradientes -----
  static const gradienteTitulo = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.fromARGB(140, 141, 94, 61), // 0%
      Color.fromARGB(140, 33, 74, 29), // 30%
      Color.fromARGB(140, 114, 77, 50), // 58%
      Color.fromARGB(140, 28, 70, 24), // 79%
      Color.fromARGB(140, 116, 78, 50), // 100%
    ],
    stops: [
      0.0,
      0.30,
      0.58,
      0.79,
      1.0,
    ],
  );

  // sombras
  static const sombra = [
    BoxShadow(
      color: Color.fromARGB(40, 0, 0, 0), // cor + opacidade (0x33 = ~20%)
      blurRadius: 6,            // o quanto a sombra espalha
      offset: Offset(0, 6),     // (horizontal, vertical)
    ),
  ];
  // ============================================


}