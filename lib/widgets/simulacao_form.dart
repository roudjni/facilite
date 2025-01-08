// lib/widgets/emprestimo/simulacao_form.dart
import 'package:emprestafacil/app/app_state.dart';
import 'package:emprestafacil/data/models/simulacao.dart';
import 'package:emprestafacil/theme/app_theme.dart';
import 'package:emprestafacil/widgets/shared/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef SimulacaoCallback = Function(
    double totalComJuros, List<Map<String, dynamic>> parcelasDetalhadas);

class SimulacaoForm extends StatefulWidget {
  final Simulacao? simulacao;
  final SimulacaoCallback onSimulacaoCalculada;
  const SimulacaoForm({Key? key, this.simulacao, required this.onSimulacaoCalculada})
      : super(key: key);

  @override
  State<SimulacaoForm> createState() => SimulacaoFormState();
}

class SimulacaoFormState extends State<SimulacaoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _parcelasController = TextEditingController();
  final _jurosController = TextEditingController();
  String _tipoParcela = 'Mensais';
  DateTime? _dataVencimento;

  @override
  void initState() {
    super.initState();
    if (widget.simulacao != null) {
      _nomeController.text = widget.simulacao!.nome;
      _valorController.text =
          widget.simulacao!.valor.toStringAsFixed(2);
      _parcelasController.text = widget.simulacao!.parcelas.toString();
      _jurosController.text = widget.simulacao!.juros.toString();
      _tipoParcela = widget.simulacao!.tipoParcela;
      _dataVencimento = widget.simulacao!.dataVencimento;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _parcelasController.dispose();
    _jurosController.dispose();
    super.dispose();
  }

  void _calcularSimulacao() {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    double valor =
    double.parse(_valorController.text.replaceAll('.', '').replaceAll(',', '.'));
    int parcelasNum = int.parse(_parcelasController.text);
    double juros = double.parse(_jurosController.text) / 100;

    appState.setValor(valor);
    appState.setParcelas(parcelasNum);
    appState.setJuros(juros * 100);
    appState.setTipoParcela(_tipoParcela);
    appState.setDataVencimento(_dataVencimento ?? DateTime.now());
    appState.calcularSimulacao('simulacao'); // Poderia passar a origem se necessário

    // Notifica a tela pai sobre os novos valores
    widget.onSimulacaoCalculada(appState.totalComJuros, appState.parcelasDetalhadas);
  }

  void _formatarValor(TextEditingController controller, String value) {
    final appState = Provider.of<AppState>(context, listen: false);
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) {
      controller.text = '';
      return;
    }
    final parsed = double.parse(value) / 100;
    controller.text = appState.numberFormat.format(parsed).replaceAll('R\$', '');
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  // Metodo para obter os dados da simulação (será usado pela tela pai)
  Simulacao getSimulacaoData() {
    return Simulacao(
      nome: _nomeController.text,
      valor: double.parse(
          _valorController.text.replaceAll('.', '').replaceAll(',', '.')),
      parcelas: int.parse(_parcelasController.text),
      juros: double.parse(_jurosController.text),
      data: DateTime.now(), // Você pode ajustar isso se necessário
      tipoParcela: _tipoParcela,
      parcelasDetalhes:
      Provider.of<AppState>(context, listen: false).parcelasDetalhadas,
      dataVencimento: _dataVencimento ?? DateTime.now(),
    );
  }

  Map<String, dynamic> getCamposCalculados() {
    final appState = Provider.of<AppState>(context, listen: false);
    return {
      'totalComJuros': appState.totalComJuros,
      'parcelasDetalhadas': appState.parcelasDetalhadas,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _nomeController,
                  label: 'Nome do Cliente',
                  icon: Icons.person_outline,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Digite o nome do cliente' : null,
                  onChanged: (value) => appState.setNome(value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  controller: _valorController,
                  label: 'Valor do Empréstimo',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Digite o valor' : null,
                  onChanged: (value) => _formatarValor(_valorController, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _parcelasController,
                  label: 'Número de Parcelas',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Digite o número de parcelas'
                      : null,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      appState.setParcelas(int.parse(value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppDropdown(
                  value: _tipoParcela,
                  label: 'Periodicidade',
                  icon: Icons.access_time,
                  items: ['Diárias', 'Semanais', 'Quinzenais', 'Mensais']
                      .map((tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo,
                          style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _tipoParcela = value!;
                    appState.setTipoParcela(value);
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  controller: _jurosController,
                  label: 'Taxa de Juros (%)',
                  icon: Icons.percent,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Digite a taxa de juros' : null,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      appState.setJuros(double.parse(value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppDatePicker(
                  selectedDate: _dataVencimento,
                  onDateSelected: (date) {
                    setState(() => _dataVencimento = date);
                    appState.setDataVencimento(date);
                  },
                  label: 'Data de Vencimento',
                  icon: Icons.calendar_month_outlined,
                  validator: (value) => value?.isEmpty ?? true ? 'Selecione a data' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calcularSimulacao,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate_outlined, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Calcular Simulação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
