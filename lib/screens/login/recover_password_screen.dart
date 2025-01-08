import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/app/app_state.dart';
import 'package:emprestafacil/widgets/shared/shared_widgets.dart';
import 'package:emprestafacil/data/services/auth_service.dart';
import 'package:emprestafacil/data/models/usuario.dart';

class RecoverPasswordScreen extends StatefulWidget {
  @override
  _RecoverPasswordScreenState createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _answerController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _perguntaSeguranca;
  String? _respostaSeguranca;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityInfo();
  }

  Future<void> _loadSecurityInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final usuario = 'admin';
      final Usuario? userData = await _authService.databaseHelper.getUsuario(usuario); // Usando Usuario?
      setState(() {
        _perguntaSeguranca = userData?.perguntaSeguranca; // Acesso seguro com ?.
        _respostaSeguranca = userData?.respostaSeguranca; // Acesso seguro com ?.
      });
    } catch (e) {
      debugPrint("Erro ao carregar info: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyAnswer() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua resposta')),
      );
      return;
    }

    appState.setLoading(true);

    try {
      if (_answerController.text.trim() == _respostaSeguranca) {
        Navigator.pushNamed(context, '/reset-password');
      } else {
        setState(() {
          _answerController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resposta incorreta')),
        );
      }
    } finally {
      appState.setLoading(false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recuperar Senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _perguntaSeguranca != null
                        ? _perguntaSeguranca!
                        : 'Carregando pergunta...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _answerController,
                    label: 'Resposta',
                    icon: Icons.question_answer_outlined,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: () {
                      if (!_isLoading && !appState.isLoading) {
                        _verifyAnswer();
                      }
                    },
                    icon: Icons.arrow_forward,
                    label: 'Continuar',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}