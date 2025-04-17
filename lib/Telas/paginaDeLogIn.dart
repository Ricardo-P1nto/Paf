import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teste/Telas/paginaPrincipal.dart';
import '../Comun/meu_snackbar.dart';
import '../servicos/autenticacao_servico.dart';
import 'Tela_LoginOuSignin.dart';

class Paginadelogin extends StatefulWidget {
  const Paginadelogin({super.key});

  @override
  _PaginadeloginState createState() => _PaginadeloginState();
}

class _PaginadeloginState extends State<Paginadelogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final AutenticacaoServico _autenServico = AutenticacaoServico();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/imagens/FotoDeLisboa2.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 250),
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
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
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
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          hintText: "Email",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Por favor insira um email';
                                          } else if ((value?.length ?? 0) < 6) {
                                            return 'O email deve ter pelo menos 6 caracteres';
                                          } else if (!(value?.contains('@') ?? false)) {
                                            return 'Email inválido (falta o @)';
                                          } else if (!(value?.contains('.') ?? false)) {
                                            return 'Email inválido (falta o .)';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: _senhaController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          hintText: "Password",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Por favor insira uma senha';
                                          } else if ((value?.length ?? 0) < 6) {
                                            return 'A senha deve ter pelo menos 6 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                "Forgot Password",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const EscolhaLogInSignIn(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        margin: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.blueGrey,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Voltar atrás",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _login,
                                      child: Container(
                                        height: 50,
                                        margin: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.blueGrey,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Login",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                "Continuar com outras plataformas",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey,
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.facebook,
                                          color: Colors.blue,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          await _autenServico.criarUsuarioComGoogle();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => PaginaPrincipal()),
                                          );
                                        } catch (e) {
                                          mostarSnackBar(context: context, mensagem: 'Erro ao fazer login com o Google: $e');
                                        }
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: FaIcon(
                                            FontAwesomeIcons.google,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 30),
                              if (_isLoading)
                                const CircularProgressIndicator(),
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

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text;
      String senha = _senhaController.text;

      _autenServico.logarUsuarios(
        email: email,
        senha: senha,
        context: context,
      ).then(
            (String? erro) {
          setState(() {
            _isLoading = false;
          });

          if (erro != null) {
            mostarSnackBar(context: context, mensagem: erro);
          } else {
            // Login successful
          }
        },
      );
    }
  }
}