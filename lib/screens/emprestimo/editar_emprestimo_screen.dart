import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/app/app_state.dart';
import 'package:emprestafacil/data/models/emprestimo.dart';
import 'package:emprestafacil/widgets/shared/shared_widgets.dart';

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
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  late TextEditingController _enderecoController;
  late TextEditingController _valorController;
  late TextEditingController _parcelasController;
  late TextEditingController _jurosController;
  DateTime? _dataVencimento;

  @override
  void initState() {
    super.initState();
    final emprestimo = widget.emprestimo;

    _nomeController = TextEditingController(text: emprestimo.nome);
    _cpfController = TextEditingController(text: emprestimo.cpfCnpj);
    _telefoneController = TextEditingController(text: emprestimo.whatsapp);
    _emailController = TextEditingController(text: emprestimo.email ?? '');
    _enderecoController = TextEditingController(text: emprestimo.endereco ?? '');
    _valorController = TextEditingController(text: emprestimo.valor.toStringAsFixed(2));
    _parcelasController = TextEditingController(text: emprestimo.parcelas.toString());
    _jurosController = TextEditingController(text: emprestimo.juros.toString());
    _dataVencimento = emprestimo.dataVencimento;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    final emprestimoAtualizado = widget.emprestimo.copyWith(
      nome: _nomeController.text,
      cpfCnpj: _cpfController.text,
      whatsapp: _telefoneController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      endereco: _enderecoController.text.isNotEmpty ? _enderecoController.text : null,
      valor: double.parse(_valorController.text),
      parcelas: int.parse(_parcelasController.text),
      juros: double.parse(_jurosController.text),
      dataVencimento: _dataVencimento,
    );

    await appState.updateEmprestimo(emprestimoAtualizado);

    Navigator.pushReplacementNamed(
      context,
      '/detalhes-emprestimo',
      arguments: emprestimoAtualizado,
    );
  }

  Future<void> _simularAlteracoes() async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setValor(double.parse(_valorController.text));
    appState.setParcelas(int.parse(_parcelasController.text));
    appState.setJuros(double.parse(_jurosController.text));
    appState.setDataVencimento(_dataVencimento!);
    appState.calcularSimulacao('Edição');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Empréstimo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: _nomeController,
                label: 'Nome do Cliente',
                icon: Icons.person,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppTextField(
                controller: _cpfController,
                label: 'CPF/CNPJ',
                icon: Icons.badge,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppTextField(
                controller: _telefoneController,
                label: 'Telefone',
                icon: Icons.phone,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
              ),
              AppTextField(
                controller: _enderecoController,
                label: 'Endereço',
                icon: Icons.location_on,
              ),
              AppTextField(
                controller: _valorController,
                label: 'Valor do Empréstimo',
                icon: Icons.monetization_on,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppTextField(
                controller: _parcelasController,
                label: 'Número de Parcelas',
                icon: Icons.payment,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppTextField(
                controller: _jurosController,
                label: 'Taxa de Juros (%)',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              AppDatePicker(
                selectedDate: _dataVencimento,
                onDateSelected: (date) => setState(() => _dataVencimento = date),
                label: 'Data de Vencimento',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Alterações'),
                      onPressed: _salvarAlteracoes,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calculate),
                      label: const Text('Simular Alterações'),
                      onPressed: _simularAlteracoes,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
