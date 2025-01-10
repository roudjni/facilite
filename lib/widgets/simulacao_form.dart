import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/simulacao.dart';
import 'package:facilite/theme/app_theme.dart';
import 'package:facilite/widgets/shared/shared_widgets.dart';
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
  final _valorController = TextEditingController();
  final _parcelasController = TextEditingController();
  final _jurosController = TextEditingController();
  String _tipoParcela = 'Mensais';
  DateTime? _dataVencimento;

  @override
  void initState() {
    super.initState();
    if (widget.simulacao != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      _valorController.text = appState.numberFormat.format(widget.simulacao!.valor).replaceAll('R\$', '').trim();
      _parcelasController.text = widget.simulacao!.parcelas.toString();
      _jurosController.text = widget.simulacao!.juros.toStringAsFixed(0);
      _tipoParcela = widget.simulacao!.tipoParcela;
      _dataVencimento = widget.simulacao!.dataVencimento;
    }
  }

  @override
  void dispose() {
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
    double juros = double.parse(_jurosController.text.replaceAll('.', '').replaceAll(',', '.')) / 100;

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
    controller.text = appState.numberFormat.format(parsed).replaceAll('R\$', '').trim();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  void _formatarJuros(TextEditingController controller, String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) {
      controller.text = '';
      return;
    }
    controller.text = int.parse(value).toString();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  // Metodo para obter os dados da simulação (será usado pela tela pai)
  Simulacao getSimulacaoData() {
    return Simulacao(
      nome: '',
      valor: double.parse(
          _valorController.text.replaceAll('.', '').replaceAll(',', '.')),
      parcelas: int.parse(_parcelasController.text),
      juros: double.parse(_jurosController.text.replaceAll('.', '').replaceAll(',', '.')),
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
                      _formatarJuros(_jurosController,value);
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calculate_outlined, size: 24),
                SizedBox(width: 12),
                Text(
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