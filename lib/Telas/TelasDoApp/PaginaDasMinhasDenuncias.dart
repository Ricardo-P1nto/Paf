import 'package:flutter/material.dart';
import 'CriarReportScreen.dart';

class paginaDasMinhasDenuncias extends StatelessWidget {
  const paginaDasMinhasDenuncias({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Aqui ficam as minhas denúncias'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CriarReportScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}