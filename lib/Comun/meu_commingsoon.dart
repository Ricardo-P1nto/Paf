import 'package:flutter/material.dart';

class PaginaCommingSoon extends StatelessWidget {
  final String appTitle; // Parâmetro que será recebido

  const PaginaCommingSoon({
    super.key,
    required this.appTitle, // Torna o parâmetro obrigatório
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle), // Usa o parâmetro recebido como título
      ),

      body: const Center(
        child: Text(
          'Ainda a preparar esta tela',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}