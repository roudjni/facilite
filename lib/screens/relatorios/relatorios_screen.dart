import 'package:facilite/data/models/emprestimo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facilite/app/app_state.dart';
import 'package:facilite/widgets/main_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({Key? key}) : super(key: key);

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> with SingleTickerProviderStateMixin {
  int mesSelecionado = DateTime.now().month;
  int anoSelecionado = DateTime.now().year;
  int? mesAnterior;
  int? anoAnterior;
  Map<String, dynamic>? relatorio;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _zoomLevel = 1.0;
  double _initialRadius = 50.0;
  String _searchText = '';
  List<Map<String, dynamic>> _previsaoRecebimentos = [];
  bool _previsaoCarregada = false;
  bool _isLoadingPrevisao = true;
  String? _erroPrevisao;
  int _indiceInicialPrevisao = 0; // Variável para controlar o índice inicial da previsão
  final int _mesesExibidos = 4; // Número de meses exibidos na previsão
  static const int TODOS_OS_MESES = 0; // Valor especial para representar a opção "Todos"

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    mesAnterior = mesSelecionado;
    anoAnterior = anoSelecionado;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarRelatorio();
      if (!_previsaoCarregada) {
        _carregarPrevisao();
      }
    });
  }

  Future<void> _carregarPrevisao() async {
    // Só carrega a previsão se ainda não estiver carregada ou se houver mudanças
    if (_previsaoCarregada && mesAnterior == mesSelecionado && anoAnterior == anoSelecionado) return;

    setState(() {
      _isLoadingPrevisao = true;
      _erroPrevisao = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final previsao = await appState.calcularPrevisaoRecebimentos(6);
      setState(() {
        _previsaoRecebimentos = previsao;
        _previsaoCarregada = true;
        // Atualizando mesAnterior e anoAnterior após o carregamento
        mesAnterior = mesSelecionado;
        anoAnterior = anoSelecionado;
      });
    } catch (e) {
      print("Erro ao carregar previsão: $e");
      setState(() {
        _erroPrevisao = "Erro ao carregar previsão. Tente novamente.";
      });
    } finally {
      setState(() {
        _isLoadingPrevisao = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarRelatorio({List<Emprestimo>? emprestimosFiltrados}) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Obter todos os empréstimos, independentemente do período, se a opção "Todos" for selecionada
    final List<Emprestimo> emprestimos = emprestimosFiltrados ??
        (mesSelecionado == TODOS_OS_MESES
            ? await appState.databaseHelper.getAllEmprestimos()
            : await appState.databaseHelper.getEmprestimosPorMesEAno(mesSelecionado, anoSelecionado));

    double totalEmprestado = 0.0;
    double totalRecebido = 0.0;
    double lucroEsperado = 0.0;

    for (final emprestimo in emprestimos) {
      totalEmprestado += emprestimo.valor;
      final valorTotal = emprestimo.valor * (1 + emprestimo.juros / 100); // Valor total a ser recebido
      final recebido = emprestimo.parcelasDetalhes
          .where((p) => p['status'] == 'Paga')
          .fold(0.0, (sum, p) => sum + p['valor']);
      totalRecebido += recebido;
      lucroEsperado += valorTotal - emprestimo.valor; // Lucro esperado: valor total - valor emprestado
    }

    // Tendência de empréstimos (pode ser adaptado para a visualização geral, se necessário)
    List<Map<String, dynamic>> tendenciaEmprestimos = [];
    if (mesSelecionado != TODOS_OS_MESES) {
      for (int i = 5; i >= 0; i--) {
        DateTime data = DateTime(anoSelecionado, mesSelecionado - i, 1);
        double valorEmprestadoMes = 0.0;

        final emprestimosMes = await appState.databaseHelper.getEmprestimosPorMesEAno(data.month, data.year);

        for (final emprestimo in emprestimosMes) {
          valorEmprestadoMes += emprestimo.valor;
        }

        tendenciaEmprestimos.add({
          'mes': DateFormat('MMM').format(data),
          'valor': valorEmprestadoMes,
        });
      }
    }

    setState(() {
      relatorio = {
        'totalEmprestado': totalEmprestado,
        'totalRecebido': totalRecebido,
        'lucro': lucroEsperado, // Usando lucroEsperado
        'pendente': totalEmprestado - totalRecebido,
        'tendenciaEmprestimos': tendenciaEmprestimos,
      };
      _animationController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Relatórios',
      actions: [_buildFiltroMesAno()],
      child: relatorio == null
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResumo(),
                    const SizedBox(height: 16),
                    Row( // Alterando para Row para colocar as seções lado a lado
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGraficoSection(
                            title: 'Recebido vs. Pendente',
                            child: _buildGraficoDePizza(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPrevisaoRecebimentos(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[850]?.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {
                            _searchText = text;
                          });
                          final appState = Provider.of<AppState>(context, listen: false);
                          final emprestimosFiltrados = appState.emprestimosRecentes.where((emprestimo) {
                            return emprestimo.nome.toLowerCase().contains(_searchText.toLowerCase());
                          }).toList();
                          _carregarRelatorio(emprestimosFiltrados: emprestimosFiltrados);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: _buildListaDetalhada(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrevisaoRecebimentos() {
    if (_isLoadingPrevisao) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      );
    }

    if (_erroPrevisao != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _erroPrevisao!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _carregarPrevisao,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_previsaoRecebimentos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Nenhum recebimento previsto',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final previsaoExibida = _previsaoRecebimentos.sublist(
        _indiceInicialPrevisao,
        _indiceInicialPrevisao + _mesesExibidos > _previsaoRecebimentos.length
            ? _previsaoRecebimentos.length
            : _indiceInicialPrevisao + _mesesExibidos);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previsão de Recebimentos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previsaoExibida.length,
              itemBuilder: (context, index) {
                final item = previsaoExibida[index];
                return ListTile(
                  title: Text(item['mes'], style: const TextStyle(color: Colors.white)),
                  trailing: Text(
                    'R\$ ${item['valor'].toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: _indiceInicialPrevisao > 0
                    ? () {
                  setState(() {
                    _indiceInicialPrevisao--;
                  });
                }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                onPressed: _indiceInicialPrevisao + _mesesExibidos < _previsaoRecebimentos.length
                    ? () {
                  setState(() {
                    _indiceInicialPrevisao++;
                  });
                }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildResumoCard(
          'Emprestado',
          relatorio!['totalEmprestado'],
          Icons.attach_money,
          Colors.blue,
        ),
        _buildResumoCard(
          'Recebido',
          relatorio!['totalRecebido'],
          Icons.payments,
          Colors.green,
        ),
        _buildResumoCard(
          'Lucro Esperado', // Nome do card alterado
          relatorio!['lucro'], // Usando o valor de lucroEsperado
          Icons.trending_up,
          Colors.purple,
        ),
        _buildResumoCard(
          'Pendente',
          relatorio!['pendente'],
          Icons.schedule,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildResumoCard(String label, double value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32) / 2;

    return Container(
      width: cardWidth,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$',
              ).format(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGraficoDePizza() {
    // Ocultar o gráfico de pizza se a opção "Todos" for selecionada
    if (mesSelecionado == TODOS_OS_MESES) {
      return const SizedBox.shrink();
    }

    final recebido = relatorio!['totalRecebido'];
    final pendente = relatorio!['pendente'];
    final total = recebido + pendente;

    return GestureDetector(
      onTap: () {
        setState(() {
          _zoomLevel = _zoomLevel == 1.0 ? 1.5 : 1.0;
        });
      },
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        return;
                      }
                    });
                  },
                ),
                sections: [
                  PieChartSectionData(
                    value: recebido,
                    color: Colors.green[400],
                    title: '${((recebido / total) * 100).toStringAsFixed(1)}%',
                    radius: _initialRadius * _zoomLevel,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    badgeWidget: null,
                    badgePositionPercentageOffset: .98,
                  ),
                  PieChartSectionData(
                    value: pendente,
                    color: Colors.orange[400],
                    title: '${((pendente / total) * 100).toStringAsFixed(1)}%',
                    radius: _initialRadius * _zoomLevel,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    badgeWidget: null,
                    badgePositionPercentageOffset: .98,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30 * _zoomLevel,
                borderData: FlBorderData(show: false),
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendaItem('Recebido', Colors.green[400]!),
                      const SizedBox(width: 16),
                      _buildLegendaItem('Pendente', Colors.orange[400]!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildListaDetalhada() {
    final appState = Provider.of<AppState>(context, listen: false);
    final emprestimos = appState.emprestimosRecentes.where((emprestimo) {
      return emprestimo.nome.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    if (emprestimos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum empréstimo encontrado',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final emprestimo = emprestimos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: Text(
                    emprestimo.nome[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  emprestimo.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(emprestimo.valor),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: emprestimo.parcelas > 0
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emprestimo.parcelas > 0 ? 'Em andamento' : 'Quitado',
                    style: TextStyle(
                      color: emprestimo.parcelas > 0
                          ? Colors.orange[400]
                          : Colors.green[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: emprestimos.length,
      ),
    );
  }

  Widget _buildFiltroMesAno() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            // Exibir "Todos os Meses" se a opção "Todos" for selecionada
            mesSelecionado == TODOS_OS_MESES
                ? 'Todos os Meses'
                : '${DateFormat("MMMM 'de' yyyy", 'pt_BR').format(DateTime(anoSelecionado, mesSelecionado))}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white70),
          onPressed: () async {
            final filtro = await _mostrarFiltroMesAno();
            if (filtro != null) {
              setState(() {
                mesSelecionado = filtro['mes']!;
                anoSelecionado = filtro['ano']!;
              });
              await _carregarRelatorio();
              await _carregarPrevisao();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: () {
            _carregarPrevisao();
          },
        ),
      ],
    );
  }

  Future<Map<String, int>?> _mostrarFiltroMesAno() async {
    final meses = [
      'Todos', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    int mes = mesSelecionado;
    int ano = anoSelecionado;

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecionar Período',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: DropdownButton<int>(
                  value: mes,
                  isExpanded: true,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: List.generate(
                    meses.length,
                        (index) => DropdownMenuItem(
                      value: index, // Opção "Todos" tem valor 0
                      child: Text(meses[index]),
                    ),
                  ),
                  onChanged: (value) => setState(() => mes = value ?? mes),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: DropdownButton<int>(
                  value: ano,
                  isExpanded: true,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: List.generate(
                    5,
                        (index) => DropdownMenuItem(
                      value: ano - 2 + index,
                      child: Text((ano - 2 + index).toString()),
                    ),
                  ),
                  onChanged: (value) => setState(() => ano = value ?? ano),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      {'mes': mes, 'ano': ano},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirmar'),
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