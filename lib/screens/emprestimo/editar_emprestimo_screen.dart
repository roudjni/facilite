import 'package:facilite/widgets/shared/calendar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:facilite/data/models/simulacao.dart';
import 'package:facilite/widgets/shared/shared_widgets.dart';
import 'package:facilite/widgets/simulacao_form.dart';
import 'package:intl/intl.dart';

class EditarEmprestimoScreen extends StatefulWidget {
  final Emprestimo emprestimo;

  const EditarEmprestimoScreen({Key? key, required this.emprestimo})
      : super(key: key);

  @override
  State<EditarEmprestimoScreen> createState() => _EditarEmprestimoScreenState();
}

class _EditarEmprestimoScreenState extends State<EditarEmprestimoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _enderecoController;
  late TextEditingController _valorController;
  Simulacao? _simulacao;
  double _totalComJuros = 0.0;
  List<Map<String, dynamic>> _parcelasDetalhadas = [];
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _showSidebar = false;
  bool _isSimulationExpanded = true;
  bool _isClientExpanded = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final emprestimo = widget.emprestimo;

    _nomeController = TextEditingController(text: emprestimo.nome);
    _cpfController = TextEditingController(text: emprestimo.cpfCnpj);
    _whatsappController = TextEditingController(text: emprestimo.whatsapp);
    _emailController = TextEditingController(text: emprestimo.email ?? '');
    _enderecoController = TextEditingController(text: emprestimo.endereco ?? '');
    final appState = Provider.of<AppState>(context, listen: false);
    _valorController = TextEditingController(text: appState.numberFormat.format(emprestimo.valor).replaceAll('R\$', '').trim());
    _inicializarSimulacao();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  void _inicializarSimulacao() {
    final emprestimo = widget.emprestimo;
    _simulacao = Simulacao(
        nome: emprestimo.nome,
        valor: emprestimo.valor,
        parcelas: emprestimo.parcelas,
        juros: emprestimo.juros,
        data: emprestimo.data,
        tipoParcela: emprestimo.tipoParcela,
        parcelasDetalhes: emprestimo.parcelasDetalhes,
        dataVencimento: emprestimo.dataVencimento
    );
    _totalComJuros = emprestimo.valor * (1 + emprestimo.juros / 100);
    _parcelasDetalhadas = emprestimo.parcelasDetalhes;
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
      final simulacaoAtualizada = _simulacao!.copyWith(
        parcelasDetalhes: _parcelasDetalhadas,
      );


      final emprestimoAtualizado = widget.emprestimo.copyWith(
        nome: _nomeController.text,
        cpfCnpj: _cpfController.text,
        whatsapp: _whatsappController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        endereco: _enderecoController.text.isNotEmpty ? _enderecoController.text : null,
        valor: simulacaoAtualizada.valor,
        parcelas: simulacaoAtualizada.parcelas,
        juros: simulacaoAtualizada.juros,
        tipoParcela: simulacaoAtualizada.tipoParcela,
        parcelasDetalhes: simulacaoAtualizada.parcelasDetalhes,
        dataVencimento: simulacaoAtualizada.dataVencimento,
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

  void _handleSimulacaoCalculada(
      double totalComJuros, List<Map<String, dynamic>> parcelasDetalhadas) {
    setState(() {
      _totalComJuros = totalComJuros;
      _parcelasDetalhadas = parcelasDetalhadas;
      if (_simulacao != null) {
        _simulacao = _simulacao!.copyWith(
          parcelasDetalhes: parcelasDetalhadas,
          valor: Provider.of<AppState>(context, listen: false).valor,
          parcelas: Provider.of<AppState>(context, listen: false).parcelas,
          juros: Provider.of<AppState>(context, listen: false).juros,
          tipoParcela: Provider.of<AppState>(context, listen: false).tipoParcela,
          dataVencimento: Provider.of<AppState>(context, listen: false).dataVencimento,
        );
      }
      _isClientExpanded = true;
      _showSidebar = true;
      _animationController.forward();
    });
  }

  Future<void> _selectDate(Map<String, dynamic> parcela) async {
    final initialDate = _selectedDate ?? DateTime.now();

    final dataEscolhida = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF2D2D2D),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Escolha uma Data',
                  style: TextStyle(
                    color: Colors.blue[200],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: AppCalendarTheme.calendarTheme(context),
                  child: SizedBox(
                    height: 250,
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (DateTime date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      child: Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (dataEscolhida != null) {
      setState(() {
        parcela['dataVencimento'] =
            DateFormat('dd/MM/yyyy').format(dataEscolhida);
        _selectedDate = dataEscolhida;
      });

      _handleSimulacaoCalculada(_totalComJuros, _parcelasDetalhadas);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data alterada para: ${DateFormat('dd/MM/yyyy').format(dataEscolhida)}',
          ),
        ),
      );
    }
  }

  String _formatCurrency(double value) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.numberFormat.format(value);
  }

  Widget _buildSummaryPanel(AppState appState) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Cabeçalho com valor total
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!,
                  Colors.blue[800]!,
                  Colors.blue[700]!,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Seção principal
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título com ícone
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
                            'Total Facility+',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Valor principal
                      Text(
                        appState.numberFormat.format(_totalComJuros),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Resumo das parcelas
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.blue[100],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_parcelasDetalhadas.length}x de ',
                              style: TextStyle(
                                color: Colors.blue[100],
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              appState.numberFormat
                                  .format(_parcelasDetalhadas[0]['valor']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de parcelas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _parcelasDetalhadas.length,
                itemBuilder: (context, index) {
                  final parcela = _parcelasDetalhadas[index];
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[850]!,
                                  Colors.grey[800]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Barra de progresso
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: LinearProgressIndicator(
                                      value: (index + 1) /
                                          _parcelasDetalhadas.length,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue[700]!.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                ),
                                // Conteúdo da parcela
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Número da parcela
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[900]!
                                              .withOpacity(0.3),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${parcela['numero']}',
                                            style: TextStyle(
                                              color: Colors.blue[100],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Valor e data
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appState.numberFormat
                                                  .format(parcela['valor']),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _selectDate(parcela),
                                              child: Text(
                                                parcela['dataVencimento'],
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Rodapé com informações totais
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total de ${_parcelasDetalhadas.length} parcelas',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Última parcela em ${_parcelasDetalhadas.last['dataVencimento']}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
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
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
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
                            'Total: ${_formatCurrency(_totalComJuros)}',
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Simulação',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SimulacaoForm(
                            simulacao: _simulacao,
                            onSimulacaoCalculada: _handleSimulacaoCalculada,
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
          ),
          if (_showSidebar)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(300 * _slideAnimation.value, 0),
                  child: child,
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: _buildSummaryPanel(appState),
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