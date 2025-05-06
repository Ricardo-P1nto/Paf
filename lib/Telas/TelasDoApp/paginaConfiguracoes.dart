import 'package:flutter/material.dart';
import 'package:teste/Telas/TelasDoApp/Paginas%20Das%20Configura%C3%A7%C3%B5es/TelaPerfil.dart';
import '../../Comun/meu_commingsoon.dart'; // Keep for other options
import '../../servicos/autenticacao_servico.dart';

class PaginaConfiguracoes extends StatelessWidget {
  PaginaConfiguracoes({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // appBar: AppBar( // Optional: Add an AppBar if needed for consistency
      //   title: const Text('Configurações'),
      //   backgroundColor: Colors.blueGrey, // Match theme
      // ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Conta'), // Changed from 'Perfil' to 'Conta'
            subtitle: const Text('Ver e editar perfil, alterar senha'), // Added subtitle for clarity
            onTap: () {
              Navigator.push(
                context,
                // Navigate to the actual profile screen
                MaterialPageRoute(builder: (context) => const TelaPerfil()),
              );
            },
          ),
          const Divider(), // Add visual separation
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificações'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon(appTitle: 'Notificações',)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacidade'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon(appTitle: 'Privacidade',)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon(appTitle: 'Idioma',)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda & Suporte'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaginaCommingSoon(appTitle: 'Ajuda',)),
              );
            },
          ),
           const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text('Terminar Sessão', style: TextStyle(color: Colors.red[700])),
            onTap: () async {
              // Show confirmation dialog before logging out
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Terminar Sessão'),
                    content: const Text('Tem a certeza que deseja sair da sua conta?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(false); // Don't logout
                        },
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sair'),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Confirm logout
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                 await AutenticacaoServico().deslogar(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

