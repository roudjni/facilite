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

    print('Mês selecionado: $mesSelecionado');
    print('Ano selecionado: $anoSelecionado');

    // Obter a lista de empréstimos filtrados ou todos os empréstimos
    List<Emprestimo> emprestimos = emprestimosFiltrados ?? await appState.databaseHelper.getAllEmprestimos();

    print('Número de empréstimos encontrados (todos): ${emprestimos.length}');

    // Filtrar por nome do cliente, se aplicável
    if (_searchText.isNotEmpty) {
      emprestimos = emprestimos.where((emprestimo) {
        return emprestimo.nome.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
      print('Número de empréstimos após filtro por nome: ${emprestimos.length}');
    }

    // Filtrar por ano, se "Todos os Meses" estiver selecionado
    if (mesSelecionado == TODOS_OS_MESES) {
      emprestimos = emprestimos.where((emprestimo) {
        return emprestimo.parcelasDetalhes.any((parcela) {
          final dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
          return dataVencimento.year == anoSelecionado;
        });
      }).toList();
      print('Número de empréstimos após filtro por ano: ${emprestimos.length}');
    }

    double totalEmprestado = 0.0;
    double totalRecebido = 0.0;
    double lucroEsperado = 0.0;
    double pendente = 0.0;

    for (final emprestimo in emprestimos) {
      // Buscar os detalhes do empréstimo atualizado
      final emprestimoAtualizado = await appState.databaseHelper.getEmprestimoById(emprestimo.id!);

      if (emprestimoAtualizado != null) {
        totalEmprestado += emprestimoAtualizado.valor;
        final valorTotal = emprestimoAtualizado.valor * (1 + emprestimoAtualizado.juros / 100);

        // Filtrar as parcelas do empréstimo pelo mês e ano selecionados, se não for "Todos os Meses"
        bool temParcelaNoMes = true;
        if (mesSelecionado != TODOS_OS_MESES) {
          temParcelaNoMes = emprestimoAtualizado.parcelasDetalhes.any((p) {
            final dataVencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
            return dataVencimento.month == mesSelecionado && dataVencimento.year == anoSelecionado;
          });
        }

        // Se não tiver parcela no mês, pula para o próximo empréstimo
        if (!temParcelaNoMes) continue;

        // Calcular o valor recebido no mês selecionado com base na DATA DE VENCIMENTO
        double recebido = 0.0;
        if (mesSelecionado != TODOS_OS_MESES) {
          final recebidoNoMes = emprestimoAtualizado.parcelasDetalhes
              .where((p) => p['status'] == 'Paga')
              .where((p) {
            final dataVencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
            return dataVencimento.month == mesSelecionado && dataVencimento.year == anoSelecionado; // Filtra pela data de VENCIMENTO
          }).fold(0.0, (sum, p) => sum + p['valor']);
          recebido = recebidoNoMes;
        } else {
          recebido = emprestimoAtualizado.parcelasDetalhes
              .where((p) => p['status'] == 'Paga')
              .fold(0.0, (sum, p) => sum + p['valor']);
        }
        totalRecebido += recebido;

        lucroEsperado += valorTotal - emprestimoAtualizado.valor;

        // Cálculo do valor pendente (não mudou)
        if (mesSelecionado != TODOS_OS_MESES) {
          final parcelasPendentesMes = emprestimoAtualizado.parcelasDetalhes.where((p) {
            if (p['status'] == 'Paga') return false;
            final dataVencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
            return dataVencimento.month == mesSelecionado && dataVencimento.year == anoSelecionado;
          });

          for (final parcela in parcelasPendentesMes) {
            pendente += parcela['valor'];
          }
        } else {
          pendente += valorTotal - recebido;
        }
      }
    }

    // Tendência de empréstimos (considerando apenas empréstimos com parcelas no mês)
    List<Map<String, dynamic>> tendenciaEmprestimos = [];
    if (mesSelecionado != TODOS_OS_MESES) {
      for (int i = 5; i >= 0; i--) {
        DateTime data = DateTime(anoSelecionado, mesSelecionado - i, 1);
        double valorEmprestadoMes = 0.0;

        for (final emprestimo in emprestimos) {
          final emprestimoAtualizado = await appState.databaseHelper.getEmprestimoById(emprestimo.id!);
          if (emprestimoAtualizado != null) {
            final temParcelaNoMes = emprestimoAtualizado.parcelasDetalhes.any((p) {
              final dataVencimento = DateFormat('dd/MM/yyyy').parse(p['dataVencimento']);
              return dataVencimento.month == data.month && dataVencimento.year == data.year;
            });

            if (temParcelaNoMes) {
              valorEmprestadoMes += emprestimoAtualizado.valor;
            }
          }
        }

        // Só adiciona o mês se houver valor emprestado
        if (valorEmprestadoMes > 0) {
          tendenciaEmprestimos.add({
            'mes': DateFormat('MMM').format(data),
            'valor': valorEmprestadoMes,
          });
        }
      }
    }

    setState(() {
      relatorio = {
        'totalEmprestado': totalEmprestado,
        'totalRecebido': totalRecebido,
        'lucro': lucroEsperado,
        'pendente': pendente,
        'tendenciaEmprestimos': tendenciaEmprestimos,
      };
      _animationController.forward(from: 0.0);
    });
  }

  Widget _buildPrevisaoRecebimentos() {
    if (_isLoadingPrevisao) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
      );
    }

    if (_erroPrevisao != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _erroPrevisao!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _carregarPrevisao,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_previsaoRecebimentos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum recebimento previsto',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previsaoExibida = _previsaoRecebimentos.sublist(
      _indiceInicialPrevisao,
      _indiceInicialPrevisao + _mesesExibidos > _previsaoRecebimentos.length
          ? _previsaoRecebimentos.length
          : _indiceInicialPrevisao + _mesesExibidos,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Previsão de Recebimentos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Próximos ${_mesesExibidos} meses',
                  style: TextStyle(
                    color: Colors.blueAccent.shade100,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previsaoExibida.length,
              separatorBuilder: (context, index) => const Divider(
                height: 16,
                color: Colors.white10,
              ),
              itemBuilder: (context, index) {
                final item = previsaoExibida[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              item['mes'].substring(0, 3),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['mes'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(item['valor']),
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _indiceInicialPrevisao > 0
                    ? () {
                  setState(() {
                    _indiceInicialPrevisao--;
                  });
                }
                    : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Anterior'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _indiceInicialPrevisao + _mesesExibidos < _previsaoRecebimentos.length
                    ? () {
                  setState(() {
                    _indiceInicialPrevisao++;
                  });
                }
                    : null,
                label: const Text('Próximo'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                    SizedBox(
                      height: 400, // Altura fixa para ambos os cards
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pie_chart,
                      color: Colors.purple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Toque para zoom',
                      style: TextStyle(
                        color: Colors.purple.shade100,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGraficoDePizza() {
    double recebido = 0.0;
    double pendente = 0.0;

    if (relatorio != null) {
      if (_searchText.isNotEmpty) {
        recebido = relatorio!['totalRecebido'] ?? 0.0;
        pendente = relatorio!['pendente'] ?? 0.0;
      } else if (mesSelecionado == TODOS_OS_MESES) {
        recebido = relatorio!['totalRecebido'] ?? 0.0;
        pendente = relatorio!['pendente'] ?? 0.0;
      } else {
        recebido = relatorio!['totalRecebido'] ?? 0.0;
        pendente = relatorio!['pendente'] ?? 0.0;
      }
    }

    final total = recebido + pendente;
    final recebidoPercentual = total > 0 ? (recebido / total) * 100 : 0.0;
    final pendentePercentual = total > 0 ? (pendente / total) * 100 : 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _zoomLevel = _zoomLevel == 1.0 ? 1.5 : 1.0;
        });
      },
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55 * _zoomLevel,
                    sections: [
                      PieChartSectionData(
                        value: recebido,
                        color: Colors.green[400],
                        title: '${recebidoPercentual.toStringAsFixed(1)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: _initialRadius * _zoomLevel,
                        titlePositionPercentageOffset: 0.6,
                        showTitle: true,
                      ),
                      PieChartSectionData(
                        value: pendente,
                        color: Colors.orange[400],
                        title: '${pendentePercentual.toStringAsFixed(1)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: _initialRadius * _zoomLevel,
                        titlePositionPercentageOffset: 0.6,
                        showTitle: true,
                      ),
                    ],
                    borderData: FlBorderData(show: false),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendaItemAtualizado(
                'Recebido',
                Colors.green[400]!,
                recebido,
                recebidoPercentual,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildLegendaItemAtualizado(
                'Pendente',
                Colors.orange[400]!,
                pendente,
                pendentePercentual,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItemAtualizado(
      String label,
      Color color,
      double valor,
      double percentual,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(valor),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${percentual.toStringAsFixed(1)}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildListaDetalhada() {
    final appState = Provider.of<AppState>(context, listen: false);

    // Filtrar a lista de empréstimos recentes com base no período e no texto de busca
    final emprestimos = appState.emprestimosRecentes.where((emprestimo) {
      final nomeCliente = emprestimo.nome.toLowerCase();
      final textoBusca = _searchText.toLowerCase();
      final possuiTextoBusca = nomeCliente.contains(textoBusca);

      if (mesSelecionado == TODOS_OS_MESES) {
        // "Todos os Meses" e um ano específico está selecionado
        return possuiTextoBusca && emprestimo.parcelasDetalhes.any((parcela) {
          final dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
          return dataVencimento.year == anoSelecionado;
        });
      } else {
        // Um mês e um ano específico estão selecionados
        return possuiTextoBusca && emprestimo.parcelasDetalhes.any((parcela) {
          final dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
          return dataVencimento.month == mesSelecionado && dataVencimento.year == anoSelecionado;
        });
      }
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
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/detalhes-emprestimo',
                  arguments: emprestimo,
                );
              },
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
                    _getStatusEmprestimo(emprestimo),
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
                      color: _getStatusColor(emprestimo.parcelasDetalhes).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatus(emprestimo.parcelasDetalhes),
                      style: TextStyle(
                        color: _getStatusColor(emprestimo.parcelasDetalhes),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _getStatusEmprestimo(Emprestimo emprestimo) {
    final totalParcelas = emprestimo.parcelasDetalhes.length;
    final parcelasPagas = emprestimo.parcelasDetalhes.where((p) => p['status'] == 'Paga').length;

    if (parcelasPagas == totalParcelas) {
      return 'Quitado';
    } else if (parcelasPagas == 0) {
      return '0/$totalParcelas parcelas';
    } else {
      return '$parcelasPagas/$totalParcelas parcelas';
    }
  }

  String _getStatus(List<Map<String, dynamic>> parcelasDetalhes) {
    final todasPagas = parcelasDetalhes.every((parcela) => parcela['status'] == 'Paga');
    final temParcelasAtrasadas = parcelasDetalhes.any((parcela) {
      final dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
      return DateTime.now().isAfter(dataVencimento) && parcela['status'] != 'Paga';
    });

    if (todasPagas) {
      return 'Quitado';
    } else if (temParcelasAtrasadas) {
      return 'Atrasado';
    } else {
      return 'Em andamento';
    }
  }

  Color _getStatusColor(List<Map<String, dynamic>> parcelasDetalhes) {
    final todasPagas = parcelasDetalhes.every((parcela) => parcela['status'] == 'Paga');
    final temParcelasAtrasadas = parcelasDetalhes.any((parcela) {
      final dataVencimento = DateFormat('dd/MM/yyyy').parse(parcela['dataVencimento']);
      return DateTime.now().isAfter(dataVencimento) && parcela['status'] != 'Paga';
    });

    if (todasPagas) {
      return Colors.green;
    } else if (temParcelasAtrasadas) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
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
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Selecionar Período',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Mês',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (context, setState) => DropdownButton<int>(
                    value: mes,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                    underline: const SizedBox(),
                    items: List.generate(
                      meses.length,
                          (index) => DropdownMenuItem(
                        value: index,
                        child: Text(meses[index]),
                      ),
                    ),
                    onChanged: (value) => setState(() => mes = value ?? mes),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ano',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (context, setState) => DropdownButton<int>(
                    value: ano,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
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
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      {'mes': mes, 'ano': ano},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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