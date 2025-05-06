import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Comun/meu_snackbar.dart'; // Assumindo que este arquivo existe e contém a função mostarSnackBar

class TelaEditarEmail extends StatefulWidget {
  const TelaEditarEmail({super.key});

  @override
  State<TelaEditarEmail> createState() => _TelaEditarEmailState();
}

class _TelaEditarEmailState extends State<TelaEditarEmail> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  User? _user;
  String _emailAtual = '';
  bool _obscureSenhaAtual = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _user = _auth.currentUser;
    if (_user == null) {
      setState(() {
        _errorMessage = "Utilizador não autenticado.";
        _isLoading = false;
      });
      return;
    }

    // Get email directly from Firebase Auth user
    _emailAtual = _user!.email ?? '';
    if (_emailAtual.isEmpty) {
      _errorMessage = "Email atual não encontrado.";
    }
    _emailController.text = _emailAtual; // Pre-fill the field

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _reautenticarUsuario(String senha) async {
    if (_user == null || _user!.email == null) {
      mostarSnackBar(
          context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return false;
    }
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!, // Use current email for re-auth
        password: senha,
      );
      await _user!.reauthenticateWithCredential(credential);
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
      mostarSnackBar(context: context, mensagem: mensagemErro, erro: true);
      return false;
    } catch (e) {
      mostarSnackBar(context: context,
          mensagem: "Erro inesperado ao reautenticar: $e",
          erro: true);
      return false;
    }
  }

  Future<void> _salvarEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_user == null) {
      mostarSnackBar(
          context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return;
    }

    String emailNovo = _emailController.text.trim();
    if (emailNovo == _emailAtual) {
      mostarSnackBar(context: context,
          mensagem: "O novo email é igual ao email atual.",
          erro: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String senhaAtual = _senhaAtualController.text;

    // 1. Reautenticar com a senha atual
    bool reauthSuccess = await _reautenticarUsuario(senhaAtual);

    if (!reauthSuccess) {
      setState(() {
        _isSaving = false;
      });
      return; // Parar se a reautenticação falhar
    }

    // 2. Se reautenticação OK, iniciar o fluxo de atualização de email com verificação
    try {
      // CORRIGIDO: Usar verifyBeforeUpdateEmail(newEmail) que é o método correto para Flutter
      await _user!.verifyBeforeUpdateEmail(emailNovo);

      // Nota: O email no Firebase Auth só será atualizado DEPOIS que o utilizador clicar
      // no link de verificação enviado para o emailNovo.

      // Podemos optar por atualizar o email no Firestore AQUI para que a UI local mostre
      // o email 'pendente', ou esperar que o email seja verificado no Auth.
      // Manter a atualização no Firestore como estava, mas com a nota de que é 'pendente'.
      // Uma abordagem mais robusta seria reagir a alterações de autenticação ou usar Cloud Functions.
      await _firestore.collection('utilizadores').doc(_user!.uid).update({
        'email': emailNovo,
        // Atualiza no Firestore *localmente*, pode ser inconsistente temporariamente
      });

      // CORRIGIDO: Mensagem de sucesso informando sobre o email de verificação e removendo 'duracao'
      mostarSnackBar(
        context: context,
        mensagem: "Link de verificação enviado para $emailNovo. Por favor, verifique o novo email para confirmar a alteração.",
        erro: false, // Não é um erro, é um sucesso!
        // REMOVIDO: Parâmetro 'duracao' que não existe na função mostarSnackBar
        // duracao: const Duration(seconds: 5),
      );

      // Após enviar o email, o fluxo ideal seria talvez não sair da tela
      // imediatamente, mas informar o utilizador para verificar o email.
      // Manter o pop() por agora para seguir o fluxo original, mas considere a UX.
      if (mounted) {
        // Await briefly to allow user to read snackbar before popping
        await Future.delayed(
            const Duration(seconds: 3)); // Esperar para a mensagem
        Navigator.of(context).pop(); // Voltar para a TelaPerfil
      }
    } on FirebaseAuthException catch (e) {
      String mensagemErro = "Erro ao iniciar atualização de email.";
      if (e.code == 'email-already-in-use') {
        mensagemErro = "Este email já está a ser utilizado por outra conta.";
      } else if (e.code == 'invalid-email') {
        mensagemErro = "O formato do novo email é inválido.";
      } else if (e.code == 'requires-recent-login') {
        // Este erro não deveria ocorrer se _reautenticarUsuario foi bem sucedido,
        // mas é bom ter um fallback.
        mensagemErro =
        "É necessário autenticar novamente para alterar o email.";
      }
      else {
        mensagemErro = "Erro ao iniciar atualização de email: ${e.message}";
      }
      mostarSnackBar(context: context, mensagem: mensagemErro, erro: true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar email: $e');
      }
      mostarSnackBar(context: context,
          mensagem: "Erro inesperado ao salvar email: $e",
          erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar Email'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null &&
          _emailAtual.isEmpty // Show error if initial load failed
          ? Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,)
      ))
          : _user == null
          ? const Center(child: Text("Utilizador não encontrado."))
          : _buildEditForm(),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // Campo para Novo Email
            TextFormField(
              controller: _emailController,
              enabled: !_isSaving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Novo Email",
                hintText: "Insira o seu novo email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'Por favor, insira o novo email';
                }
                // Basic email format validation
                if (!RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value)) {
                  return 'Formato de email inválido';
                }
                if (value.trim() == _emailAtual) {
                  return 'O novo email não pode ser igual ao email atual.';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Campo de Senha Atual para confirmação
            const Text(
              "Confirme a sua senha atual para salvar a alteração:",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _senhaAtualController,
              obscureText: _obscureSenhaAtual,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: "Senha Atual",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureSenhaAtual ? Icons.visibility_off : Icons
                      .visibility),
                  onPressed: () =>
                      setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a sua senha atual para confirmar';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Botão Salvar
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _salvarEmail,
              icon: _isSaving
                  ? const SizedBox(width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              // MODIFICADO: Texto do botão
              label: Text(_isSaving ? 'Salvando...' : 'Alterar Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
