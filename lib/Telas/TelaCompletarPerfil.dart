import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Telas/paginaPrincipal.dart';

class TelaCompletarPerfil extends StatefulWidget {
  const TelaCompletarPerfil({super.key});

  @override
  State<TelaCompletarPerfil> createState() => _TelaCompletarPerfilState();
}

class _TelaCompletarPerfilState extends State<TelaCompletarPerfil> {
  final TextEditingController _nomeController = TextEditingController();
  File? _imagemSelecionada;

  Future<void> _escolherImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<String?> _uploadImagem(File imagem) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ref = FirebaseStorage.instance.ref().child('fotos_perfil/$uid.jpg');
    await ref.putFile(imagem);
    return await ref.getDownloadURL();
  }

  Future<void> _salvarDadosPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira seu nome.')),
      );
      return;
    }

    try {
      String? imagemUrl;
      if (_imagemSelecionada != null) {
        imagemUrl = await _uploadImagem(_imagemSelecionada!);
      }

      // Aqui usamos a mesma instância do Firestore que o CriarReportScreen usa
      await FirebaseFirestore.instance
          .collection('utilizadores') // <- Alterado para "utilizadores"
          .doc(user.uid)
          .set({
        'nome': nome,
        'fotoPerfil': imagemUrl,
        'email': user.email,
        'uid': user.uid, // opcional: facilita futuras consultas
        'criadoEm': Timestamp.now(), // opcional: marcação de tempo
      });

      print('✅ Perfil salvo na coleção "utilizadores"');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
      );
    } catch (e, stackTrace) {
      print('❌ Erro ao salvar perfil: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _escolherImagem,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                _imagemSelecionada != null ? FileImage(_imagemSelecionada!) : null,
                child: _imagemSelecionada == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Seu nome'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarDadosPerfil,
              child: const Text("Salvar e continuar"),
            ),
          ],
        ),
      ),
    );
  }
}
