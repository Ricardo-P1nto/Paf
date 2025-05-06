import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teste/Telas/TelaCompletarPerfil.dart';
import 'package:teste/Telas/paginaPrincipal.dart';
import '../Comun/meu_snackbar.dart';
import '../servicos/autenticacao_servico.dart';
import 'Tela_LoginOuSignin.dart';

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

class PaginaRegistar extends StatefulWidget {
  const PaginaRegistar({super.key});

  @override
  State<PaginaRegistar> createState() => _PaginaRegistarState();
}

class _PaginaRegistarState extends State<PaginaRegistar> {
  bool queroEntrar = true;
  final _formKey = GlobalKey<FormState>();
  String? password;

  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _senhacontroller = TextEditingController();
  final TextEditingController _confirmacaocontroller = TextEditingController();

  final AutenticacaoServico _autenServico = AutenticacaoServico();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

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
                                          bottom:
                                          BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _emailcontroller,
                                        decoration: const InputDecoration(
                                          hintText: "Email",
                                          hintStyle:
                                          TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Por favor insira um email';
                                          } else if ((value?.length ?? 0) < 6) {
                                            return 'O email deve ter pelo menos 6 caracteres';
                                          } else if (!(value?.contains('@') ??
                                              false)) {
                                            return 'Email inválido (falta o @)';
                                          } else if (!(value?.contains('.') ??
                                              false)) {
                                            return 'Email inválido (falta o .)';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom:
                                          BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _senhacontroller,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          hintText: "Password",
                                          hintStyle:
                                          TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            password = value;
                                          });
                                        },
                                        validator: passwordValidator,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: _confirmacaocontroller,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          hintText: "Confirmar Password",
                                          hintStyle:
                                          TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Por favor insira a sua confirmação de password';
                                          }
                                          if (value != password) {
                                            return 'As passwords não coincidem';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const EscolhaLogInSignIn(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(50),
                                          color: Colors.blueGrey,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Voltar Atrás",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          botaoSeguinteClicado();
                                        }
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(50),
                                          color: Colors.blueGrey,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "criar conta",
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
                                "Criar conta com outras plataformas",
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

  void botaoSeguinteClicado() {
    String email = _emailcontroller.text;
    String senha = _senhacontroller.text;

    if (_formKey.currentState!.validate()) {
      // Navega para a tela de completar perfil, passando email e senha
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaCompletarPerfil(email: email, senha: senha),
        ),
      );
    } else {
      if (kDebugMode) {
        print("Formulário inválido");
      }
    }
  }

}