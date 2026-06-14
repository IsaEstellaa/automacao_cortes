import 'package:flutter/material.dart';

class AppColors {

  // ============================================
  // cores gerais
  // ============================================

  static const background = Color(0xFFE1D9CB);
  static const card = Color(0xFFF4EEE8);
  static const green = Color(0xFF7E8462);

  // textos -----
  static const textoSutil = Color.fromARGB(255, 178, 154, 137);


  // botoes -----

  static const buttonBrown = Color(0xFF987A64);

  // fitas -----
  static const fundoFitaVerde = Color(0xFFDFE2D4);
  static const listrasFitaVerde = Color.fromARGB(70, 32, 66, 31);

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