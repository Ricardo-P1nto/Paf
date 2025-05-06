import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teste/Comun/meu_snackbar.dart';
import './TelaEditarNome.dart'; 
import './TelaEditarFoto.dart';
import './TelaEditarEmail.dart';
import './TelaAlterarSenha.dart'; // Keep existing change password screen

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVerifyingPassword = false; // State for verification process
  final TextEditingController _senhaAtualDialogController = TextEditingController(); // Controller for dialog

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Function to reload data, useful if returning from edit screens
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _user = _auth.currentUser;
    // Re-fetch user data from Auth in case email or photoURL changed
    await _user?.reload();
    _user = _auth.currentUser;

    if (_user == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Utilizador não autenticado.";
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('utilizadores').doc(_user!.uid).get();

      if (!mounted) return;

      if (userDoc.exists) {
        _userData = userDoc.data();
      } else {
        // Fallback if Firestore doc doesn't exist
        _userData = {
          'nome': _user!.displayName ?? 'Nome não definido',
          'email': _user!.email ?? 'Email não disponível',
          'fotoPerfil': _user!.photoURL,
        };
        _errorMessage = "Documento do utilizador não encontrado. Exibindo dados básicos.";
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = "Erro ao carregar dados do perfil: $e";
      // Show snackbar for critical loading errors
      mostarSnackBar(context: context, mensagem: "Erro ao carregar perfil: $e", erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Navigation Functions --- 
  void _navigateToEditNome() {
     Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEditarNome()))
       .then((_) => _loadUserData()); // Reload data after potential change
  }

  void _navigateToEditFoto() {
     Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEditarFoto()))
       .then((_) => _loadUserData()); // Reload data after potential change
  }

  void _navigateToEditEmail() {
     Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEditarEmail()))
       .then((_) => _loadUserData()); // Reload data after potential change
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaAlterarSenha()),
    );
  }

  // --- Password Verification Logic --- 

  // Re-authentication function (copied from edit screens)
  Future<bool> _reautenticarUsuario(String senha) async {
    if (_user == null || _user!.email == null) {
      mostarSnackBar(context: context, mensagem: "Utilizador não encontrado.", erro: true);
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
      // Show error in the dialog context if possible, otherwise use main context
      mostarSnackBar(context: context, mensagem: mensagemErro, erro: true);
      return false;
    } catch (e) {
      mostarSnackBar(context: context, mensagem: "Erro inesperado ao reautenticar: $e", erro: true);
      return false;
    }
  }

  // MODIFICADO: Function to show the verified password in a dialog
  Future<void> _showVerifiedPasswordDialog(String password) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Senha Atual Verificada'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('A sua senha atual é:'),
                const SizedBox(height: 10),
                // Display the password clearly
                SelectableText(
                  password, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // MODIFICADO: Function to show dialog, verify password, and then show it
  Future<void> _verifyAndShowCurrentPassword() async {
    _senhaAtualDialogController.clear(); // Clear previous input
    // MODIFICADO: Dialog now returns the verified password (String?) or null
    String? verifiedPassword = await showDialog<String?>(
      context: context,
      barrierDismissible: false, // User must explicitly cancel or confirm
      builder: (BuildContext dialogContext) {
        // Use a StatefulWidget builder to manage the obscure state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool obscureText = true;
            return AlertDialog(
              title: const Text('Verificar Senha Atual'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Para confirmar que é você, por favor insira a sua senha atual.'),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _senhaAtualDialogController,
                      obscureText: obscureText,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Senha Atual',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null); // Indicate cancellation
                  },
                ),
                ElevatedButton(
                  // Disable button while verifying
                  onPressed: _isVerifyingPassword ? null : () async {
                    final senha = _senhaAtualDialogController.text;
                    if (senha.isEmpty) {
                      mostarSnackBar(context: dialogContext, mensagem: "Por favor, insira a senha.", erro: true);
                      return; // Don't close dialog
                    }
                    
                    // Set loading state within dialog if needed, or manage globally
                    if (mounted) setState(() { _isVerifyingPassword = true; });
                    
                    bool reauthSuccess = await _reautenticarUsuario(senha);
                    
                    // Always reset loading state
                    if(mounted){
                      setState(() { _isVerifyingPassword = false; });
                    }

                    if (reauthSuccess && dialogContext.mounted) {
                      // MODIFICADO: Pop with the verified password
                      Navigator.of(dialogContext).pop(senha); 
                    } 
                    // If reauth failed, snackbar is shown by _reautenticarUsuario, dialog stays open
                  },
                  child: _isVerifyingPassword 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verificar'),
                ),
              ],
            );
          }
        );
      },
    );

    // MODIFICADO: If password was verified (not null), show it in a new dialog
    if (verifiedPassword != null) {
      // No need for the success snackbar anymore
      // mostarSnackBar(context: context, mensagem: "Senha atual verificada com sucesso!", erro: false);
      await _showVerifiedPasswordDialog(verifiedPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conta'),
        backgroundColor: Colors.blueGrey, // Match theme
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show more prominent error if user data is completely unavailable
    if (_user == null || (_userData == null && _errorMessage != null)) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text(_errorMessage ?? "Utilizador não autenticado.", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)
         )
       );
    }
    // If we have some data (even fallback), show the profile view
    return _buildProfileView();
  }

  Widget _buildProfileView() {
    // Prioritize Firestore data, fallback to Auth data
    String? fotoUrl = _userData?['fotoPerfil'] ?? _user?.photoURL;
    String nome = _userData?['nome'] ?? _user?.displayName ?? 'Nome não disponível';
    String email = _user?.email ?? 'Email não disponível'; // Get email directly from refreshed _user

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Display non-critical error message at the top (e.g., Firestore doc not found)
        if (_errorMessage != null && _userData != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(_errorMessage!, style: TextStyle(color: Colors.orange[800]), textAlign: TextAlign.center,)
          ),

        // Profile Picture Section
        Center(
          child: GestureDetector(
             onTap: _navigateToEditFoto, // Tap picture to edit photo
             child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                        ? NetworkImage(fotoUrl)
                        : null,
                    child: (fotoUrl == null || fotoUrl.isEmpty)
                        ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                        : null,
                  ),
                  Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: Colors.blueGrey.withOpacity(0.8),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.edit, color: Colors.white, size: 20),
                   )
                ],
             ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(child: Text("Toque na foto para alterar", style: TextStyle(color: Colors.grey))),
        const SizedBox(height: 25),

        // --- Profile Information & Edit Links --- 
        const Text("Informações da Conta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const Divider(height: 20),

        ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.blueGrey),
          title: const Text('Nome'),
          subtitle: Text(nome),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToEditNome,
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined, color: Colors.blueGrey),
          title: const Text('Email'),
          subtitle: Text(email),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToEditEmail,
        ),

        const SizedBox(height: 20),

        // --- Security Section --- 
        const Text("Segurança", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const Divider(height: 20),
        
        // MODIFICADO: ListTile title and subtitle, and onTap function
        ListTile(
          leading: const Icon(Icons.visibility_outlined, color: Colors.blueGrey), // Changed icon
          title: const Text('Ver Senha Atual'), // Changed title
          subtitle: const Text('Confirme para visualizar a sua senha'), // Changed subtitle
          trailing: const Icon(Icons.chevron_right),
          onTap: _verifyAndShowCurrentPassword, // Call the modified verification function
        ),

        ListTile(
          leading: const Icon(Icons.lock_outline, color: Colors.blueGrey),
          title: const Text('Alterar Senha'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToChangePassword,
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  @override
  void dispose() {
    _senhaAtualDialogController.dispose(); // Dispose the dialog controller
    super.dispose();
  }
}

