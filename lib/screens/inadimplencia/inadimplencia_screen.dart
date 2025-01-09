import 'package:facilite/app/app_state.dart';
import 'package:facilite/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InadimplenciaScreen extends StatefulWidget {
  const InadimplenciaScreen({Key? key}) : super(key: key);

  @override
  State<InadimplenciaScreen> createState() => _InadimplenciaScreenState();
}

class _InadimplenciaScreenState extends State<InadimplenciaScreen> {
  int mesSelecionado = DateTime.now().month;
  int anoSelecionado = DateTime.now().year;
  Map<String, dynamic> _dadosInadimplencia = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final dados = await appState.calcularInadimplenciaPorPeriodo(mesSelecionado, anoSelecionado);
    setState(() {
      _dadosInadimplencia = dados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Análise de Inadimplência',
      actions: [
        _buildFiltroMesAno(),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildAnaliseInadimplencia(),
      ),
    );
  }

  Widget _buildFiltroMesAno() {
    return IconButton(
      icon: const Icon(Icons.calendar_today, color: Colors.white70),
      onPressed: () async {
        final filtro = await _mostrarFiltroMesAno();
        if (filtro != null) {
          setState(() {
            mesSelecionado = filtro['mes']!;
            anoSelecionado = filtro['ano']!;
          });
          _carregarDados();
        }
      },
    );
  }

  Future<Map<String, int>?> _mostrarFiltroMesAno() async {
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
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
              Text(
                'Selecionar Período',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
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
                  style: TextStyle(color: Colors.white),
                  underline: SizedBox(),
                  items: List.generate(
                    12,
                        (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(meses[index]),
                    ),
                  ),
                  onChanged: (value) => setState(() => mes = value ?? mes),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
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
                  style: TextStyle(color: Colors.white),
                  underline: SizedBox(),
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
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context, {'mes': mes, 'ano': ano});

                      setState(() {
                        mesSelecionado = mes;
                        anoSelecionado = ano;
                      });

                      _carregarDados();
                    },
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

  Widget _buildAnaliseInadimplencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: Provider.of<AppState>(context, listen: false).calcularInadimplenciaPorPeriodo(mesSelecionado, anoSelecionado),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Erro ao carregar a análise', style: TextStyle(color: Colors.red)),
              );
            } else if (snapshot.hasData) {
              _dadosInadimplencia = snapshot.data!;
              return Column(
                children: [
                  ListTile(
                    title: const Text('Total Devido', style: TextStyle(color: Colors.white)),
                    trailing: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_dadosInadimplencia['totalDevido']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text('Total Pago', style: TextStyle(color: Colors.white)),
                    trailing: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_dadosInadimplencia['totalPago']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text('Total Inadimplente', style: TextStyle(color: Colors.white)),
                    trailing: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_dadosInadimplencia['totalInadimplente']),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Taxa de Inadimplência: ${_dadosInadimplencia['taxaInadimplencia'].toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: _dadosInadimplencia['taxaInadimplencia'] > 10 ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
}