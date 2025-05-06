import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Comun/meu_snackbar.dart';

class TelaEditarFoto extends StatefulWidget {
  const TelaEditarFoto({super.key});

  @override
  State<TelaEditarFoto> createState() => _TelaEditarFotoState();
}

class _TelaEditarFotoState extends State<TelaEditarFoto> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _senhaAtualController = TextEditingController();
  File? _imagemSelecionada;
  String? _imagemUrlAtual;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  User? _user;
  bool _obscureSenhaAtual = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
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
      // Fetch from Firestore first as it might be more up-to-date
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('utilizadores').doc(_user!.uid).get();

      if (userDoc.exists && userDoc.data()!.containsKey('fotoPerfil')) {
        _imagemUrlAtual = userDoc.data()!['fotoPerfil'];
      } else {
        // Fallback to Auth photoURL if Firestore doesn't have it
        _imagemUrlAtual = _user!.photoURL;
      }
    } catch (e) {
      _errorMessage = "Erro ao carregar foto atual: $e";
      mostarSnackBar(context: context, mensagem: _errorMessage!, erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _escolherImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<String?> _uploadImagem(File imagem, String uid) async {
    try {
      final ref = _storage.ref().child('fotos_perfil/$uid.jpg');
      await ref.putFile(imagem);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao fazer upload da imagem: $e');
      }
      mostarSnackBar(context: context, mensagem: "Erro ao fazer upload da imagem: $e", erro: true);
      return null;
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

  Future<void> _salvarFoto() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_user == null) {
      mostarSnackBar(context: context, mensagem: "Utilizador não encontrado.", erro: true);
      return;
    }
    if (_imagemSelecionada == null) {
      mostarSnackBar(context: context, mensagem: "Por favor, selecione uma nova foto.", erro: true);
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

    // 2. Se reautenticação OK, fazer upload e atualizar
    try {
      // Upload da nova imagem
      String? imagemUrlNova = await _uploadImagem(_imagemSelecionada!, _user!.uid);
      if (imagemUrlNova == null) {
        // Error already shown in _uploadImagem
        setState(() { _isSaving = false; });
        return;
      }

      // Atualizar dados no Firestore
      await _firestore.collection('utilizadores').doc(_user!.uid).update({
        'fotoPerfil': imagemUrlNova,
      });

      // Atualizar PhotoURL no FirebaseAuth
      await _user!.updatePhotoURL(imagemUrlNova);

      mostarSnackBar(context: context, mensagem: "Foto de perfil atualizada com sucesso!", erro: false);
      if (mounted) {
         Navigator.of(context).pop(); // Voltar para a TelaPerfil
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar foto: $e');
      }
      mostarSnackBar(context: context, mensagem: "Erro ao salvar foto: $e", erro: true);
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
        title: const Text('Alterar Foto de Perfil'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _imagemUrlAtual == null // Show error if initial load failed
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
            // Seletor de Imagem
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : _escolherImagem,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 80, // Larger avatar for editing photo
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imagemSelecionada != null
                          ? FileImage(_imagemSelecionada!) as ImageProvider<Object>?
                          : (_imagemUrlAtual != null && _imagemUrlAtual!.isNotEmpty)
                              ? NetworkImage(_imagemUrlAtual!)
                              : null,
                      child: (_imagemSelecionada == null && (_imagemUrlAtual == null || _imagemUrlAtual!.isEmpty))
                          ? Icon(Icons.person, size: 80, color: Colors.grey[600])
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 24),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _imagemSelecionada == null ? "Toque na imagem para alterar" : "Nova foto selecionada",
                style: TextStyle(color: _imagemSelecionada == null ? Colors.grey : Colors.blueGrey, fontWeight: FontWeight.w500)
              )
            ),
            const SizedBox(height: 40),

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
              onPressed: (_isSaving || _imagemSelecionada == null) ? null : _salvarFoto,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar Nova Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey, // Indicate disabled state
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
    _senhaAtualController.dispose();
    super.dispose();
  }
}

