import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:facilite/widgets/shared/shared_widgets.dart';

class EditarEmprestimoScreen extends StatefulWidget {
  final Emprestimo emprestimo;

  const EditarEmprestimoScreen({Key? key, required this.emprestimo})
      : super(key: key);

  @override
  State<EditarEmprestimoScreen> createState() => _EditarEmprestimoScreenState();
}

class _EditarEmprestimoScreenState extends State<EditarEmprestimoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _enderecoController;

  @override
  void initState() {
    super.initState();
    final emprestimo = widget.emprestimo;

    _nomeController = TextEditingController(text: emprestimo.nome);
    _cpfController = TextEditingController(text: emprestimo.cpfCnpj);
    _whatsappController = TextEditingController(text: emprestimo.whatsapp);
    _emailController = TextEditingController(text: emprestimo.email ?? '');
    _enderecoController = TextEditingController(text: emprestimo.endereco ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setLoading(true);

    try {
      final emprestimoAtualizado = widget.emprestimo.copyWith(
        nome: _nomeController.text,
        cpfCnpj: _cpfController.text,
        whatsapp: _whatsappController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        endereco: _enderecoController.text.isNotEmpty ? _enderecoController.text : null,
      );

      await appState.updateEmprestimo(emprestimoAtualizado);

      if (mounted) {
        _showSnackBar('Dados atualizados com sucesso!', isSuccess: true);
        Navigator.pushReplacementNamed(
          context,
          '/detalhes-emprestimo',
          arguments: emprestimoAtualizado,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao atualizar dados: $e', isSuccess: false);
      }
    } finally {
      appState.setLoading(false);
    }
  }

  String _formatCurrency(double value) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.numberFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Editar Empréstimo',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Seção de Informações do Empréstimo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[900]!,
                          Colors.blue[800]!,
                          Colors.blue[700]!,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Informações do Empréstimo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total: ${_formatCurrency(widget.emprestimo.valor)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Parcelas: ${widget.emprestimo.parcelas}x de ${_formatCurrency(widget.emprestimo.valor / widget.emprestimo.parcelas)}',
                          style: TextStyle(
                            color: Colors.blue[100],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seção de Dados do Cliente
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Dados do Cliente',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _nomeController,
                          label: 'Nome Completo',
                          icon: Icons.person_outline,
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Digite o nome' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _cpfController,
                                label: 'CPF',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  MaskedInputFormatter('###.###.###-##'),
                                ],
                                validator: (value) =>
                                value?.isEmpty ?? true ? 'Digite o CPF' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _whatsappController,
                                label: 'WhatsApp',
                                icon: Icons.phone_android,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  MaskedInputFormatter('(##) #####-####'),
                                ],
                                validator: (value) =>
                                value?.isEmpty ?? true ? 'Digite o WhatsApp' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Email não é obrigatório
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Digite um Email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _enderecoController,
                          label: 'Endereço',
                          icon: Icons.location_on_outlined,
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Digite o Endereço' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (appState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[900],
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _salvarAlteracoes,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue[600],
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.blueAccent,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Salvar Alterações',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}