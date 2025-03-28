import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'Telas/Tela_LoginOuSignin.dart';
import 'Telas/paginaPrincipal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoteadorTela(),
    );
  }
}

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (kDebugMode) {
          print("Autenticação mudou! Usuário logado: ${snapshot.hasData}");
        }

        if (snapshot.hasData) {
          if (kDebugMode) {
            print("Deveria ir para PaginaPrincipal!");
          }
          return PaginaPrincipal();
        } else {
          if (kDebugMode) {
            print("Deveria ir para a Paginadelogin!");
          }
          return const PaginaDeInicio();
        }
      },
    );
  }
}