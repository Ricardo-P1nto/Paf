import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:teste/Comun/meu_snackbar.dart'; //Importar snackbar

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

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationError = 'Ative os serviços de localização');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationError = 'Permissão negada');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationError = 'Permissão permanentemente negada');
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _gettingLocation = true;
        _locationError = '';
      });
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) {
      if (mounted) setState(() => _locationError = 'Erro ao obter localização: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<String?> _uploadImagem() async {
    if (_imagemSelecionada == null) {
      if (kDebugMode) print('❌ Nenhuma imagem selecionada para upload');
      return null;
    }

    try {
      if (kDebugMode) print('📤 Iniciando upload para Firebase Storage...');
      final nomeArquivo = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('reports/$nomeArquivo');

      if (kDebugMode) print('🔄 Fazendo upload do arquivo: ${_imagemSelecionada!.path}');
      await ref.putFile(_imagemSelecionada!);

      final url = await ref.getDownloadURL();
      if (kDebugMode) print('✅ Upload concluído. URL: $url');
      return url;
    } catch (e) {
      if (kDebugMode) print('❌ Erro no upload da imagem: $e');
      return null;
    }
  }

  Future<void> _enviarReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_imagemSelecionada == null) {
       mostarSnackBar(context: context, mensagem: 'Por favor, adicione uma foto.', erro: true);
       return;
    }

    if (_currentPosition == null && _locationError.isEmpty && !_gettingLocation) {
      // Tenta obter localização novamente se não houver e não houver erro/carregamento
      await _checkLocationPermission();
    }

    if (_currentPosition == null) {
      mostarSnackBar(context: context, mensagem: _locationError.isNotEmpty ? _locationError : 'Localização não disponível. Tente atualizar.', erro: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      mostarSnackBar(context: context, mensagem: 'Usuário não autenticado.', erro: true);
      return;
    }

    if (mounted) setState(() => _isUploading = true);
    if (kDebugMode) print('▶️ Iniciando envio do report...');

    try {
      final imageUrl = await _uploadImagem();
      if (imageUrl == null || imageUrl.isEmpty) {
        mostarSnackBar(context: context, mensagem: 'Erro ao enviar a imagem.', erro: true);
        if (mounted) setState(() => _isUploading = false);
        return;
      }

      // MODIFICADO: Remover nomeUsuario e userEmail. Apenas userId é necessário.
      final reportData = {
        'data': Timestamp.now(),
        'imagemURL': imageUrl,
        'localizacao': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'userId': user.uid, // Armazenar apenas o ID do utilizador
        // 'userEmail': user.email ?? '', // REMOVIDO
        // 'nomeUsuario': user.displayName ?? '', // REMOVIDO
        'status': 'Pendente', // Manter o status inicial
        'descricao': _descricaoController.text.trim(),
      };

      final docRef = await FirebaseFirestore.instance.collection('reports').add(reportData);

      if (kDebugMode) print('🎉 Documento criado com ID: ${docRef.id}');
      mostarSnackBar(context: context, mensagem: 'Report enviado com sucesso!', erro: false);

      if (mounted) Navigator.pop(context); // Voltar para a tela anterior

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('‼️ ERRO CRÍTICO AO ENVIAR REPORT ‼️\n$e\n$stackTrace');
      }
      mostarSnackBar(context: context, mensagem: 'Erro ao enviar report: ${e.toString()}', erro: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (mounted) setState(() => _imagemSelecionada = File(pickedFile.path));
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // Manter AppBar simples ou remover se preferir integrar título no corpo
      appBar: AppBar(
        title: const Text('Criar Nova Denúncia'),
        backgroundColor: Colors.white60, // Cor similar à paginaPrincipal
        elevation: 0, // Remover sombra se preferir
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      // Aplicar cor de fundo bege globalmente
      backgroundColor: const Color.fromRGBO(255, 253, 208, 1),
      body: SafeArea(
        child: Padding(
          // Usar Padding em vez de Stack/Expanded para simplificar
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: bottomInset + 20, // Adicionar padding inferior
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Container branco para agrupar os elementos
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
                        // Seção da Imagem (Reorganizada)
                        GestureDetector(
                          onTap: _isUploading ? null : _selecionarImagem,
                          child: Container(
                            height: 180, // Ajustar altura
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: _imagemSelecionada == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[600]),
                                      const SizedBox(height: 8),
                                      const Text('Adicionar Foto *', style: TextStyle(color: Colors.grey)),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imagemSelecionada!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Text('Erro ao carregar imagem'));
                                      },
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Descrição (Estilo similar aos inputs de login/registo)
                        TextFormField(
                          controller: _descricaoController,
                          enabled: !_isUploading,
                          decoration: InputDecoration(
                            hintText: "Descrição *",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder( // Usar OutlineInputBorder para consistência
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400)
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blueGrey) // Cor de foco
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          ),
                          maxLines: 4, // Aumentar linhas para descrição
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira uma descrição';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),

                        // Localização (Integrada no container branco)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                           decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                           ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Localização *', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _gettingLocation
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : IconButton(
                                        icon: const Icon(Icons.refresh, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Atualizar Localização',
                                        onPressed: _isUploading ? null : _getCurrentLocation,
                                      ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_currentPosition != null)
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                )
                              else if (_locationError.isNotEmpty)
                                Text(_locationError, style: const TextStyle(color: Colors.red, fontSize: 12))
                              else
                                Text('A obter localização...', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botão de Envio (Estilo similar aos botões de login/registo)
                  GestureDetector(
                    onTap: _isUploading ? null : _enviarReport,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: _isUploading ? Colors.grey : Colors.blueGrey, // Cor desabilitada
                      ),
                      child: Center(
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Criar Denúncia",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Espaço extra no final
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

