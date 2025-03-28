import 'package:flutter/material.dart';
import '../../Comun/meu_commingsoon.dart';
import '../../servicos/autenticacao_servico.dart';

class PaginaConfiguracoes extends StatelessWidget {
  PaginaConfiguracoes({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificações'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacidade'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ajuda'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Deslogar'),
            onTap: () async {
              await AutenticacaoServico().deslogar(context);
            },
          ),
        ],
      ),
    );
  }
}