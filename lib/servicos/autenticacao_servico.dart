import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Telas/Tela_LoginOuSignin.dart';
import '../Telas/paginaPrincipal.dart';

class AutenticacaoServico {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //Cadastrar usuário
  // Retorna UserCredential em caso de sucesso, String com mensagem de erro em caso de falha
  Future<dynamic> cadastrarUsuario({required String email, required String senha}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: senha);
      // Não atualiza o nome de exibição aqui, será feito na TelaCompletarPerfil
      // Não faz navegação aqui
      return userCredential; // Retorna UserCredential em caso de sucesso
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Erro ao cadastrar: ${e.code}");
      }
      if (e.code == "email-already-in-use") {
        return "Este email já está em uso";
      }
      return e.message ?? "Erro desconhecido ao cadastrar"; // Retorna mensagem de erro
    } catch (e) {
      if (kDebugMode) {
        print("Erro inesperado ao cadastrar: $e");
      }
      return "Erro inesperado ao cadastrar"; // Retorna mensagem de erro genérica
    }
  }

  //Logar usuário
  Future<String?> logarUsuarios (
    {required String email, required String senha, required BuildContext context}) async {
      try {
        await _firebaseAuth.signInWithEmailAndPassword(email: email, password: senha);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaginaPrincipal()),
        );
        return null;
      } on FirebaseAuthException catch (e) {
        return e.message;
      }
  }

  //Deslogar usuário
  Future<void> deslogar(BuildContext context) async {
    try {
      if (kDebugMode) {
        print("Saindo da conta...");
      }
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) {
        print("Usuário deslogado!");
      }

      // Garante que a navegação só acontece após o logout ser concluído
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EscolhaLogInSignIn()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao deslogar: $e");
      }
    }
  }

  //Criar usuário com Google
  criarUsuarioComGoogle() async{
    //Inicializa o GoogleSignIn
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    //user cancela o log in
    if(googleUser == null) return;

    //Pegar as credenciais do Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    //Criar credenciais do Google
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //Logar com as credenciais do Google
    return await _firebaseAuth.signInWithCredential(credential);
  }

}
