import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;


Future<Uint8List> gerarRelatorioPdf(Map<String, dynamic> relatorio, int mesSelecionado, int anoSelecionado, String searchText,  List<Emprestimo> emprestimos) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
  final ttfBold = pw.Font.ttf(boldFontData);


  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(16),
      build: (pw.Context context) => [
        pw.Header(
          level: 0,
          child: pw.Center(
            child: pw.Text(
              'Relatório Financeiro',
              style: pw.TextStyle(font: ttfBold, fontSize: 24),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Período: ${mesSelecionado == 0 ? "Todos os Meses" : DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(anoSelecionado, mesSelecionado))}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              'Data da geração: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),

        pw.SizedBox(height: 24),
        pw.Text('Resumo Geral',style: pw.TextStyle(font: ttfBold, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('Emprestado', relatorio['totalEmprestado'], ttf, ttfBold),
                _buildTableCell('Recebido', relatorio['totalRecebido'], ttf, ttfBold),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Lucro Esperado', relatorio['lucro'], ttf, ttfBold),
                _buildTableCell('Pendente', relatorio['pendente'], ttf, ttfBold),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 24),
        if (relatorio['tendenciaEmprestimos'] != null && (relatorio['tendenciaEmprestimos'] as List).isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Tendência de Empréstimos',style: pw.TextStyle(font: ttfBold, fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  for (var tendencia in (relatorio['tendenciaEmprestimos'] as List))
                    pw.TableRow(
                        children: [
                          _buildTableCell(tendencia['mes'], tendencia['valor'], ttf, ttfBold)
                        ]
                    ),
                ],
              ),
            ],
          ),
        pw.SizedBox(height: 24),
        if(searchText.isNotEmpty)
          pw.Text('Empréstimos Filtrados por: $searchText', style: pw.TextStyle(font: ttfBold, fontSize: 16)),
        pw.SizedBox(height: 8),

        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: const {
            0: pw.FixedColumnWidth(120),
            1: pw.FixedColumnWidth(70),
            2: pw.FixedColumnWidth(70),
            3: pw.FixedColumnWidth(80),
            4: pw.FixedColumnWidth(80),
          },
          children: [
            pw.TableRow(
              children: [
                _buildTableHeader('Cliente', ttfBold),
                _buildTableHeader('Valor', ttfBold),
                _buildTableHeader('Parcelas', ttfBold),
                _buildTableHeader('Status', ttfBold),
                _buildTableHeader('Data Venc.', ttfBold)
              ],
            ),
            for (var emprestimo in emprestimos)
              pw.TableRow(
                  children: [
                    _buildTableCell(emprestimo.nome, null , ttf, ttfBold),
                    _buildTableCell(emprestimo.valor.toString(), null, ttf, ttfBold),
                    _buildTableCell('${emprestimo.parcelas}x', null, ttf, ttfBold),
                    _buildTableCell(_getStatus(emprestimo.parcelasDetalhes),null, ttf, ttfBold),
                    _buildTableCell(emprestimo.dataVencimento == null ? null: DateFormat('dd/MM/yyyy').format(emprestimo.dataVencimento!), null, ttf, ttfBold),
                  ]
              ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildTableCell(String? text, num? value, pw.Font ttf, pw.Font ttfBold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if(text != null)
            pw.Text(text, style: pw.TextStyle(font: ttf, fontSize: 11)),
          if(value != null)
            pw.Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value),
                style: pw.TextStyle(font: ttfBold, fontSize: 12)),

        ]
    ),
  );
}


pw.Widget _buildTableHeader(String label, pw.Font ttfBold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Center(
      child: pw.Text(label, style: pw.TextStyle(font: ttfBold, fontSize: 12)),
    ),
  );
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