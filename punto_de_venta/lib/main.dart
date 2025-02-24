import 'package:flutter/material.dart';
import 'package:punto_de_venta/pages/sign.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punto de Venta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      initialRoute: Sign.id,
      routes: {Sign.id: (_) => Sign()},

      debugShowCheckedModeBanner: false,
    );
  }
}
