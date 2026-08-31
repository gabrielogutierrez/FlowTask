import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.auth,
    required this.onAuthenticated,
  });

  final AuthService auth;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool register = false;
  bool busy = false;
  String? error;

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      if (register) {
        await widget.auth.register(
          name.text.trim(),
          email.text.trim(),
          password.text,
        );
      } else {
        await widget.auth.login(
          email.text.trim(),
          password.text,
        );
      }

      widget.onAuthenticated();
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível entrar. Confira os dados.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.task_alt_rounded,
                      size: 72,
                      color: Colors.indigo,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'FlowTask',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 28),

                    if (register) ...[
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                        ),
                        validator: (value) {
                          if ((value?.trim().length ?? 0) < 2) {
                            return 'Informe seu nome';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: email,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (!(value?.contains('@') ?? false)) {
                          return 'E-mail inválido';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                        ),
                      ),
                      validator: (value) {
                        if ((value?.length ?? 0) < 6) {
                          return 'Mínimo de 6 caracteres';
                        }

                        return null;
                      },
                    ),

                    if (error != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          busy
                              ? 'Aguarde...'
                              : register
                                  ? 'Criar conta'
                                  : 'Entrar',
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() {
                                register = !register;
                                error = null;
                              });
                            },
                      child: Text(
                        register
                            ? 'Já tenho uma conta'
                            : 'Criar minha conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}