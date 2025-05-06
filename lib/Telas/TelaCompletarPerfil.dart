import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Telas/paginaPrincipal.dart';
import '../servicos/autenticacao_servico.dart';
import '../Comun/meu_snackbar.dart';

class TelaCompletarPerfil extends StatefulWidget {
  final String email;
  final String senha;

  const TelaCompletarPerfil({
    super.key,
    required this.email,
    required this.senha,
  });

  @override
  State<TelaCompletarPerfil> createState() => _TelaCompletarPerfilState();
}

class _TelaCompletarPerfilState extends State<TelaCompletarPerfil> {
  final _formKey = GlobalKey<FormState>(); // Adicionado GlobalKey para o Form
  final TextEditingController _nomeController = TextEditingController();
  File? _imagemSelecionada;
  final AutenticacaoServico _autenServico = AutenticacaoServico();
  bool _isLoading = false;

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
    if (uid.isEmpty) {
       if (kDebugMode) {
         print('❌ UID inválido para upload de imagem');
       }
       return null;
    }
    try {
      final ref = FirebaseStorage.instance.ref().child('fotos_perfil/$uid.jpg');
      await ref.putFile(imagem);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao fazer upload da imagem: $e');
      }
      return null;
    }
  }

  Future<void> _salvarDadosPerfil() async {
    // Validar nome usando o Form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    String nome = _nomeController.text.trim();

    setState(() { _isLoading = true; });

    try {
      dynamic cadastroResult = await _autenServico.cadastrarUsuario(
        email: widget.email,
        senha: widget.senha,
      );

      if (cadastroResult is String) {
        mostarSnackBar(context: context, mensagem: cadastroResult);
        setState(() { _isLoading = false; });
        return;
      }

      UserCredential userCredential = cadastroResult as UserCredential;
      User? user = userCredential.user;

      if (user == null) {
        mostarSnackBar(context: context, mensagem: 'Erro ao obter dados do utilizador após registo.');
        setState(() { _isLoading = false; });
        return;
      }

      String? imagemUrl;
      if (_imagemSelecionada != null) {
        imagemUrl = await _uploadImagem(_imagemSelecionada!, user.uid);
        if (imagemUrl == null && kDebugMode) {
           print('⚠️ Erro ao fazer upload da imagem, continuando sem foto de perfil.');
        }
      }

      await FirebaseFirestore.instance
          .collection('utilizadores')
          .doc(user.uid)
          .set({
        'nome': nome,
        'fotoPerfil': imagemUrl,
        'email': user.email,
        'uid': user.uid,
        'criadoEm': Timestamp.now(),
      });

      await user.updateDisplayName(nome);

      if (kDebugMode) {
        print('✅ Conta criada e perfil salvo com sucesso!');
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
        (Route<dynamic> route) => false,
      );

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erro no processo de completar perfil: $e');
        print(stackTrace);
      }
      mostarSnackBar(context: context, mensagem: 'Erro ao completar perfil: $e');
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Container de fundo (sem imagem por enquanto)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color.fromRGBO(255, 253, 208, 1), // Cor de fundo similar
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 150), // Ajustar espaçamento conforme necessário
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(255, 253, 208, 1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: bottomInset,
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey, // Associar a key ao Form
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                "Complete o seu Perfil",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey, // Cor similar aos botões
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Container branco para os inputs
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(225, 95, 27, .3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    // Seletor de Imagem
                                    GestureDetector(
                                      onTap: _isLoading ? null : _escolherImagem,
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: _imagemSelecionada != null
                                            ? FileImage(_imagemSelecionada!)
                                            : null,
                                        child: _imagemSelecionada == null
                                            ? Icon(Icons.camera_alt,
                                                size: 40, color: Colors.grey[600])
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text("Foto de Perfil (Opcional)", style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 10),
                                    // Input do Nome
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: Colors.grey), // Adiciona borda superior
                                          //bottom: BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _nomeController,
                                        enabled: !_isLoading,
                                        decoration: const InputDecoration(
                                          hintText: "Seu nome",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Por favor, insira o seu nome';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Botão Salvar e Continuar (estilo similar)
                              GestureDetector(
                                onTap: _isLoading ? null : _salvarDadosPerfil,
                                child: Container(
                                  height: 50,
                                  // margin: const EdgeInsets.symmetric(horizontal: 50), // Centralizar mais?
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.blueGrey, // Cor similar
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            "Salvar e Continuar",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

