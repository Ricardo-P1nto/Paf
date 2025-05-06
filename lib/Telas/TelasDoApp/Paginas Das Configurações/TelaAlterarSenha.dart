import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teste/Comun/meu_snackbar.dart';

// Re-using the validator from paginaRegistar.dart
String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor insira uma password';
  } else if (value.length < 6) {
    return 'A password deve ter pelo menos 6 caracteres';
  } else if (!RegExp(r'^(?=.*[0-9]).{6,}$').hasMatch(value)) {
    return 'A password deve conter pelo menos 1 número';
  }
  return null;
}

class TelaAlterarSenha extends StatefulWidget {
  const TelaAlterarSenha({super.key});

  @override
  State<TelaAlterarSenha> createState() => _TelaAlterarSenhaState();
}

class _TelaAlterarSenhaState extends State<TelaAlterarSenha> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarNovaSenhaController = TextEditingController();
  bool _isSaving = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _reautenticarUsuario(String senha) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      // Use erro: true for red color
      mostarSnackBar(context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return false;
    }
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: senha,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      String mensagemErro = "Senha atual incorreta.";
      if (e.code == 'wrong-password') {
        mensagemErro = "A senha atual que inseriu está incorreta.";
      } else if (e.code == 'too-many-requests') {
        mensagemErro = "Muitas tentativas. Tente novamente mais tarde.";
      } else {
         mensagemErro = "Erro ao verificar senha: ${e.message}";
      }
      // Use erro: true for red color
      mostarSnackBar(context: context, mensagem: mensagemErro, erro: true);
      return false;
    } catch (e) {
      // Use erro: true for red color
      mostarSnackBar(context: context, mensagem: "Erro inesperado ao reautenticar: $e", erro: true);
      return false;
    }
  }

  Future<void> _alterarSenha() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() { _isSaving = true; });

    String senhaAtual = _senhaAtualController.text;
    String novaSenha = _novaSenhaController.text;

    // 1. Reautenticar com a senha atual
    bool reauthSuccess = await _reautenticarUsuario(senhaAtual);

    if (!reauthSuccess) {
      setState(() { _isSaving = false; });
      return; // Stop if re-authentication failed
    }

    // 2. Se reautenticação OK, tentar alterar a senha
    User? user = _auth.currentUser;
    if (user == null) {
       // Use erro: true for red color
       mostarSnackBar(context: context, mensagem: "Erro: Utilizador não encontrado após reautenticação.", erro: true);
       setState(() { _isSaving = false; });
       return;
    }

    try {
      await user.updatePassword(novaSenha);
      // Use erro: false for green color
      mostarSnackBar(context: context, mensagem: "Senha alterada com sucesso!", erro: false);

      // Limpar campos e voltar
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarNovaSenhaController.clear();
      if (mounted) {
         Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
       String mensagemErro = "Erro ao alterar senha.";
       // Use the passwordValidator logic for weak password check if needed, though Firebase handles basic length
       if (e.code == 'weak-password') {
         mensagemErro = passwordValidator(novaSenha) ?? "A nova senha é muito fraca."; // Reuse validator message
       } else {
         mensagemErro = "Erro ao alterar senha: ${e.message}";
       }
       // Use erro: true for red color
       mostarSnackBar(context: context, mensagem: mensagemErro, erro: true);
    } catch (e) {
      if (kDebugMode) {
        print("Erro inesperado ao alterar senha: $e");
      }
      // Use erro: true for red color
      mostarSnackBar(context: context, mensagem: "Erro inesperado ao alterar senha: $e", erro: true);
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alterar Senha"),
        backgroundColor: Colors.blueGrey, // Match theme
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _senhaAtualController,
                obscureText: _obscureSenhaAtual,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: "Senha Atual",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSenhaAtual ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a sua senha atual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _novaSenhaController,
                obscureText: _obscureNovaSenha,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: "Nova Senha",
                  hintText: "Mín. 6 caracteres, incl. 1 número", // Updated hint
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                   suffixIcon: IconButton(
                    icon: Icon(_obscureNovaSenha ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNovaSenha = !_obscureNovaSenha),
                  ),
                ),
                validator: (value) { // Use the imported validator
                  final validationError = passwordValidator(value);
                  if (validationError != null) {
                    return validationError;
                  }
                  if (value == _senhaAtualController.text) {
                    return 'A nova senha não pode ser igual à senha atual.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmarNovaSenhaController,
                obscureText: _obscureConfirmarSenha,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: "Confirmar Nova Senha",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                   suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmarSenha ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmarSenha = !_obscureConfirmarSenha),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme a nova senha';
                  }
                  if (value != _novaSenhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _alterarSenha,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_alt),
                label: Text(_isSaving ? 'Salvando...' : 'Alterar Senha'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }
}

