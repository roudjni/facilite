import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/app/app_state.dart';
import 'package:emprestafacil/widgets/main_layout.dart';
import 'package:emprestafacil/widgets/shared/shared_widgets.dart';
import 'package:emprestafacil/data/services/auth_service.dart';

class SegurancaScreen extends StatefulWidget {
  const SegurancaScreen({Key? key}) : super(key: key);

  @override
  State<SegurancaScreen> createState() => _SegurancaScreenState();
}

class _SegurancaScreenState extends State<SegurancaScreen>
    with SingleTickerProviderStateMixin {
  bool _showLoginOptions = false;
  bool _showPassword = false;
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newSecurityQuestionController = TextEditingController();
  final _newSecurityAnswerController = TextEditingController();
  final _formKeyUsername = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late String _currentUser;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _currentUser = appState.username;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _newSecurityQuestionController.dispose();
    _newSecurityAnswerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildChangeUsernameSection() {
    return Expanded(
      child: _buildSectionCard(
        title: 'Mudar nome de usuário',
        icon: Icons.person_outline,
        color: Colors.blue,
        children: [
          Form(
            key: _formKeyUsername,
            child: AppTextField(
              controller: _newUsernameController,
              label: 'Novo usuário',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite um nome de usuário';
                }
                if (value.length < 5) {
                  return 'O nome de usuário deve ter no mínimo 5 caracteres.';
                }
                if (!RegExp(r'^[a-z]+$').hasMatch(value)) {
                  return 'Apenas letras minúsculas (a-z) são permitidas.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              onPressed: () async {
                if (_formKeyUsername.currentState!.validate()) {
                  final newUser = _newUsernameController.text.trim();
                  try {
                    await _authService.alterarNomeUsuario(_currentUser, newUser);
                    setState(() {
                      _currentUser = newUser;
                      Provider.of<AppState>(context, listen: false).setUsername(newUser);
                    });
                    _showSnackBar('Nome de usuário atualizado para $newUser', Colors.blue);
                  } catch (e) {
                    _showSnackBar('Erro ao atualizar usuário: $e', Colors.red);
                  }
                }
              },
              icon: Icons.save,
              label: 'Atualizar nome de usuário',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return Expanded(
      child: _buildSectionCard(
        title: 'Mudar senha',
        icon: Icons.lock_outline,
        color: Colors.green,
        children: [
          Form(
            key: _formKeyPassword,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                AppTextField(
                  controller: _newPasswordController,
                  label: 'Nova senha',
                  icon: Icons.lock_outlined,
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite uma nova senha';
                    }
                    if (value.length < 4) {
                      return 'A senha deve ter no mínimo 4 dígitos';
                    }
                    if (value.length > 8) {
                      return 'A senha deve ter no máximo 8 dígitos';
                    }
                    return null;
                  },
                ),
                Positioned(
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              onPressed: () async {
                if (_formKeyPassword.currentState!.validate()) {
                  final newPassword = _newPasswordController.text.trim();
                  try {
                    await _authService.alterarSenhaUsuario(_currentUser, newPassword);
                    _newPasswordController.clear();
                    _showSnackBar('Senha alterada com sucesso!', Colors.green);
                  } catch (e) {
                    _showSnackBar('Erro ao atualizar senha: $e', Colors.red);
                  }
                }
              },
              icon: Icons.save,
              label: 'Atualizar senha',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeSecurityQuestionSection() {
    return _buildSectionCard(
      title: 'Pergunta de segurança',
      icon: Icons.security,
      color: Colors.orange,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _newSecurityQuestionController,
                label: 'Nova pergunta de segurança',
                icon: Icons.help_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _newSecurityAnswerController,
                label: 'Resposta da pergunta',
                icon: Icons.question_answer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: IntrinsicWidth(
            child: AppButton(
              onPressed: () async {
                final newQuestion = _newSecurityQuestionController.text.trim();
                final newAnswer = _newSecurityAnswerController.text.trim();
                if (newQuestion.isEmpty || newAnswer.isEmpty) {
                  _showSnackBar('Digite a pergunta e a resposta!', Colors.red);
                  return;
                }
                try {
                  await _authService.alterarPerguntaResposta(
                    _currentUser,
                    newQuestion,
                    newAnswer,
                  );
                  _newSecurityQuestionController.clear();
                  _newSecurityAnswerController.clear();
                  _showSnackBar('Pergunta e resposta atualizadas!', Colors.orange);
                } catch (e) {
                  _showSnackBar('Erro ao atualizar pergunta/resposta: $e', Colors.red);
                }
              },
              icon: Icons.save,
              label: 'Atualizar pergunta de segurança',
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginOptionsSection() {
    return AnimatedOpacity(
      opacity: _showLoginOptions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildChangeUsernameSection(),
                  const SizedBox(width: 16),
                  _buildChangePasswordSection(),
                ],
              ),
              const SizedBox(height: 16),
              _buildChangeSecurityQuestionSection(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Segurança',
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuickActionButton(
                      context: context,
                      icon: Icons.login,
                      label: 'LOGIN',
                      color: Colors.blue,
                      onTap: () {
                        setState(() {
                          _showLoginOptions = !_showLoginOptions;
                          if (_showLoginOptions) {
                            _animationController.forward();
                          } else {
                            _animationController.reverse();
                          }
                        });
                      },
                    ),
                    _buildQuickActionButton(
                      context: context,
                      icon: Icons.lock,
                      label: 'SENHA',
                      color: Colors.green,
                      onTap: () {
                        _showSnackBar('Botão SENHA 2 clicado!', Colors.green);
                      },
                    ),
                    _buildQuickActionButton(
                      context: context,
                      icon: Icons.security,
                      label: 'SENHA',
                      color: Colors.orange,
                      onTap: () {
                        _showSnackBar('Botão SENHA 3 clicado!', Colors.orange);
                      },
                    ),
                  ],
                ),
              ),
              if (_showLoginOptions) _buildLoginOptionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}