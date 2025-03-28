import 'package:flutter/material.dart';

class PaginaCommingSoon extends StatelessWidget {
  const PaginaCommingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comming Soon'),
      ),

      //Esta pagina so vai dizer comming soon

      body: const Center(
        child: Text(
          'Ainda a preparar esta tela',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}











