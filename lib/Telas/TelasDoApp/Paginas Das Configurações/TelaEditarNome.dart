import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Comun/meu_snackbar.dart';

class TelaEditarNome extends StatefulWidget {
  const TelaEditarNome({super.key});

  @override
  State<TelaEditarNome> createState() => _TelaEditarNomeState();
}

class _TelaEditarNomeState extends State<TelaEditarNome> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  User? _user;
  String _nomeAtual = '';
  bool _obscureSenhaAtual = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
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

    try {
      // Fetch from Firestore first
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('utilizadores').doc(_user!.uid).get();

      if (userDoc.exists && userDoc.data()!.containsKey('nome')) {
        _nomeAtual = userDoc.data()!['nome'];
      } else {
        // Fallback to Auth display name
        _nomeAtual = _user!.displayName ?? '';
        if (_nomeAtual.isEmpty) {
           _errorMessage = "Nome atual não encontrado.";
        }
      }
      _nomeController.text = _nomeAtual; // Pre-fill the field

    } catch (e) {
      _errorMessage = "Erro ao carregar nome atual: $e";
      mostarSnackBar(context: context, mensagem: _errorMessage!, erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _reautenticarUsuario(String senha) async {
    if (_user == null || _user!.email == null) {
      mostarSnackBar(context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return false;
    }
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
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
      mostarSnackBar(context: context, mensagem: "Erro inesperado ao reautenticar: $e", erro: true);
      return false;
    }
  }

  Future<void> _salvarNome() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_user == null) {
      mostarSnackBar(context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return;
    }

    String nomeNovo = _nomeController.text.trim();
    if (nomeNovo == _nomeAtual) {
       mostarSnackBar(context: context, mensagem: "O novo nome é igual ao nome atual.", erro: true);
       return;
    }

    setState(() { _isSaving = true; });

    String senhaAtual = _senhaAtualController.text;

    // 1. Reautenticar com a senha atual
    bool reauthSuccess = await _reautenticarUsuario(senhaAtual);

    if (!reauthSuccess) {
      setState(() { _isSaving = false; });
      return; // Stop if re-authentication failed
    }

    // 2. Se reautenticação OK, atualizar nome
    try {
      // Atualizar nome no Firestore
      await _firestore.collection('utilizadores').doc(_user!.uid).update({
        'nome': nomeNovo,
      });

      // Atualizar DisplayName no FirebaseAuth
      await _user!.updateDisplayName(nomeNovo);

      mostarSnackBar(context: context, mensagem: "Nome atualizado com sucesso!", erro: false);
      if (mounted) {
         Navigator.of(context).pop(); // Voltar para a TelaPerfil
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar nome: $e');
      }
      mostarSnackBar(context: context, mensagem: "Erro ao salvar nome: $e", erro: true);
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
        title: const Text('Alterar Nome'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _nomeAtual.isEmpty // Show error if initial load failed
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)
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
            // Campo para Novo Nome
            TextFormField(
              controller: _nomeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: "Novo Nome",
                hintText: "Insira o seu novo nome",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o novo nome';
                }
                if (value.trim() == _nomeAtual) {
                  return 'O novo nome não pode ser igual ao nome atual.';
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
                  icon: Icon(_obscureSenhaAtual ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
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
              onPressed: _isSaving ? null : _salvarNome,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar Novo Nome'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    super.dispose();
  }
}

