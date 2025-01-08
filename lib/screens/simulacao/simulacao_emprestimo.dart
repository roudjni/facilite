import 'package:emprestafacil/data/models/simulacao.dart';
import 'package:emprestafacil/widgets/simulacao_form.dart';
import 'package:flutter/material.dart';
import 'package:emprestafacil/app/app_state.dart';
import 'package:provider/provider.dart';
import 'package:emprestafacil/widgets/main_layout.dart';
import 'package:emprestafacil/widgets/shared/shared_widgets.dart';
import 'package:emprestafacil/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SimulacaoEmprestimoScreen extends StatefulWidget {
  final Simulacao? simulacao;

  SimulacaoEmprestimoScreen({Key? key, this.simulacao}) : super(key: key);

  @override
  _SimulacaoEmprestimoScreenState createState() =>
      _SimulacaoEmprestimoScreenState();
}

class _SimulacaoEmprestimoScreenState extends State<SimulacaoEmprestimoScreen> {
  double _totalComJuros = 0.0;
  List<Map<String, dynamic>> _parcelasDetalhadas = [];

  void _handleSimulacaoCalculada(
      double totalComJuros, List<Map<String, dynamic>> parcelasDetalhadas) {
    setState(() {
      _totalComJuros = totalComJuros;
      _parcelasDetalhadas = parcelasDetalhadas;
    });
  }

  Future<void> _salvarSimulacao() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_parcelasDetalhadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realize a simulação antes de salvar!')),
      );
      return;
    }

    // Acessa os dados diretamente do SimulacaoForm
    final simulacaoData = _simulacaoFormKey.currentState!.getSimulacaoData();
    await appState.salvarSimulacao(simulacaoData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulação salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _enviarWhatsApp() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_parcelasDetalhadas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Realize a simulação antes de compartilhar no WhatsApp!')),
        );
      }
      return;
    }
    String? numero;
    final _numeroController = TextEditingController(text: '55');
    await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Enviar para o WhatsApp'),
            content: SizedBox(
              height: 150,
              child: TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de Telefone (com DDD)',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  numero = _numeroController.text;
                  Navigator.of(context).pop();
                },
                child: const Text('Enviar'),
              )
            ],
          );
        });
    if (numero == null || numero!.isEmpty || !mounted) {
      return;
    }

    // Acessa os dados diretamente do SimulacaoForm
    final simulacaoData = _simulacaoFormKey.currentState!.getSimulacaoData();
    String mensagem = '''
📲 *Simulação de Empréstimo* 🚀

👤 *Nome do Cliente:* ${simulacaoData.nome}
💰 *Valor do Empréstimo:* ${appState.numberFormat.format(simulacaoData.valor)}
🗓️ *Número de Parcelas:* ${simulacaoData.parcelas}
🔄 *Periodicidade:* ${simulacaoData.tipoParcela}
📈 *Taxa de Juros:* ${simulacaoData.juros}%
💰 *Total a Pagar:* ${appState.numberFormat.format(_totalComJuros)}
''';
    if (_parcelasDetalhadas.isNotEmpty) {
      mensagem += "\n\n🧾 *Parcelas:*\n";
      for (var parcela in _parcelasDetalhadas) {
        mensagem += '''
➡️ *${parcela['numero']}ª Parcela:*
   💲 *Valor:* ${appState.numberFormat.format(parcela['valor'])}
   📅 *Vencimento:* ${parcela['dataVencimento']}
''';
      }
    }

    final url =
        'whatsapp://send?phone=$numero&text=${Uri.encodeComponent(mensagem)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compartilhando simulação no WhatsApp...'),
              backgroundColor: Colors.blue,
            ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp'),
              backgroundColor: Colors.red,
            ));
      }
    }
  }

  void _criarEmprestimo() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_parcelasDetalhadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Realize a simulação antes de criar o empréstimo!')),
      );
      return;
    }

    // Lógica para criar o empréstimo a partir da simulação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empréstimo criado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Correto: GlobalKey<SimulacaoFormState>
  final GlobalKey<SimulacaoFormState> _simulacaoFormKey = GlobalKey<SimulacaoFormState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MainLayout(
      title: widget.simulacao == null ? 'Nova Simulação' : 'Editar Simulação',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SimulacaoForm(
                    key: _simulacaoFormKey,
                    simulacao: widget.simulacao,
                    onSimulacaoCalculada: _handleSimulacaoCalculada,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_parcelasDetalhadas.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSimulacaoCard(appState),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: _salvarSimulacao,
                        icon: Icons.save,
                        label: widget.simulacao == null
                            ? 'Salvar Simulação'
                            : 'Salvar Edição',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        onPressed: _enviarWhatsApp,
                        icon: Icons.share,
                        label: 'Enviar no WhatsApp',
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        onPressed: _criarEmprestimo,
                        icon: Icons.add_circle_outline,
                        label: 'Criar Empréstimo',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_back,
                  label: 'Voltar',
                  color: Colors.grey,
                  outlined: true,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulacaoCard(AppState appState) {
    return AppCard(
      child: Column(
        children: [
          Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total a Pagar',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appState.numberFormat.format(_totalComJuros),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_parcelasDetalhadas.length}x de ${appState.numberFormat.format(_parcelasDetalhadas[0]['valor'])}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Mensais'.toLowerCase(), // Aqui você pode usar o valor de _tipoParcela se ele for relevante
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: AppTheme.cardPadding,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Parcela',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Valor',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Vencimento',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _parcelasDetalhadas.length,
                  itemBuilder: (context, index) {
                    final parcela = _parcelasDetalhadas[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${parcela['numero']}ª',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              appState.numberFormat.format(parcela['valor']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              parcela['dataVencimento'],
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
