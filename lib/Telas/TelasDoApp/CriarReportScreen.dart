import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Importe o Firebase Auth

class CriarReportScreen extends StatefulWidget {
  const CriarReportScreen({Key? key}) : super(key: key);

  @override
  _CriarReportScreenState createState() => _CriarReportScreenState();
}

class _CriarReportScreenState extends State<CriarReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descricaoController = TextEditingController();
  File? _imagemSelecionada;
  bool _isUploading = false;
  Position? _currentPosition;
  String _locationError = '';
  bool _gettingLocation = false;

  // Verifica e solicita permissões de localização
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationError = 'Ative os serviços de localização');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationError = 'Permissão negada');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationError = 'Permissão permanentemente negada');
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _gettingLocation = true;
      _locationError = '';
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _locationError = 'Erro: ${e.toString()}');
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Future<String?> _uploadImagem() async {
    if (_imagemSelecionada == null) {
      print('❌ Nenhuma imagem selecionada para upload');
      return null;
    }

    try {
      print('📤 Iniciando upload para Firebase Storage...');
      final nomeArquivo = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('reports')
          .child(nomeArquivo); // Usando child() para criar o caminho

      print('🔄 Fazendo upload do arquivo: ${_imagemSelecionada!.path}');
      await ref.putFile(_imagemSelecionada!);

      final url = await ref.getDownloadURL();
      print('✅ Upload concluído. URL: $url');
      return url; // Adicionado return url;
    } catch (e) {
      print('❌ Erro no upload: $e');
      return null;
    }
  }

  Future<void> _enviarReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUploading = true);
    print('▶️ Iniciando envio do report...');

    try {
      final imageUrl = await _uploadImagem();
      if (imageUrl == null || imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar a imagem.')),
        );
        setState(() => _isUploading = false);
        return;
      }

      if (_currentPosition == null) {
        await _checkLocationPermission();
        if (_currentPosition == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Localização não disponível.')),
          );
          setState(() => _isUploading = false);
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado.')),
        );
        setState(() => _isUploading = false);
        return;
      }

      final reportData = {
        'data': Timestamp.now(),
        'imagemURL': imageUrl,
        'localizacao': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'nomeUsuario': user.displayName ?? '',
        'status': 'Pendente',
        'descricao': _descricaoController.text,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('reports')
          .add(reportData);

      print('🎉 Documento criado com ID: ${docRef.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report enviado com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('‼️ ERRO CRÍTICO ‼️\n$e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }



  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagemSelecionada = File(pickedFile.path));
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Seção da Imagem
                GestureDetector(
                  onTap: _selecionarImagem,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imagemSelecionada == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50),
                        Text('Adicionar Foto'),
                      ],
                    )
                        : Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(height: 20),

                // Descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma descrição';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Localização
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Localização Atual',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_gettingLocation)
                          const LinearProgressIndicator(),
                        if (_currentPosition != null)
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                                'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          ),
                        if (_locationError.isNotEmpty)
                          Text(_locationError,
                              style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: _getCurrentLocation,
                          child: const Text('Atualizar Localização'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botão de Envio
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _enviarReport,
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Criar Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
