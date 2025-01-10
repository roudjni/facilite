import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

// Define custom colors for light theme
const primaryColor = PdfColor(0.22, 0.42, 0.69); // Primary blue
const headerBgColor = PdfColor(0.95, 0.95, 0.95); // Light gray for headers
const successColor = PdfColor(0.13, 0.55, 0.13); // Green
const warningColor = PdfColor(0.85, 0.55, 0.13); // Orange
const dangerColor = PdfColor(0.75, 0.21, 0.21);  // Red
const borderColor = PdfColor(0.8, 0.8, 0.8); // Light gray for borders

Future<Uint8List> gerarRelatorioPdf(Map<String, dynamic> relatorio, int mesSelecionado, int anoSelecionado, String searchText, List<Emprestimo> emprestimos) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
  final ttfBold = pw.Font.ttf(boldFontData);

  final baseTextStyle = pw.TextStyle(font: ttf, fontSize: 9);
  final boldTextStyle = pw.TextStyle(font: ttfBold, fontSize: 9);
  final headerStyle = pw.TextStyle(font: ttfBold, color: primaryColor, fontSize: 16);
  final subHeaderStyle = pw.TextStyle(font: ttfBold, color: primaryColor, fontSize: 12);

  final pageTheme = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    theme: pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    ),
    margin: const pw.EdgeInsets.all(30),
  );

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      build: (pw.Context context) => [
        _buildHeader(headerStyle),
        pw.SizedBox(height: 10),
        _buildDateInfo(mesSelecionado, anoSelecionado, baseTextStyle),
        pw.SizedBox(height: 20),

        // Summary Section
        pw.Text('Resumo Geral', style: headerStyle),
        pw.SizedBox(height: 8),
        _buildSummaryTable(relatorio, baseTextStyle, boldTextStyle),
        pw.SizedBox(height: 20),

        // Trends Section
        if (relatorio['tendenciaEmprestimos'] != null && (relatorio['tendenciaEmprestimos'] as List).isNotEmpty) ...[
          pw.Text('Tendência de Empréstimos', style: headerStyle),
          pw.SizedBox(height: 8),
          _buildTrendsTable(relatorio['tendenciaEmprestimos'], baseTextStyle, boldTextStyle),
          pw.SizedBox(height: 20),
        ],

        // Loans Section
        pw.Text(
            searchText.isNotEmpty ? 'Empréstimos Filtrados por: $searchText' : 'Todos os Empréstimos',
            style: headerStyle
        ),
        pw.SizedBox(height: 8),
        _buildLoansTable(emprestimos, baseTextStyle, boldTextStyle),
        pw.SizedBox(height: 20),

        // Detailed Installments Section
        for (var emprestimo in emprestimos) ...[
          pw.Text('Detalhes das Parcelas - ${emprestimo.nome}', style: subHeaderStyle),
          pw.SizedBox(height: 4),
          _buildInstallmentsTable(emprestimo, baseTextStyle, boldTextStyle),
          pw.SizedBox(height: 15),
        ],
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildHeader(pw.TextStyle headerStyle) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
    ),
    child: pw.Center(
      child: pw.Text('Relatório Financeiro', style: headerStyle),
    ),
  );
}

pw.Widget _buildDateInfo(int mesSelecionado, int anoSelecionado, pw.TextStyle baseTextStyle) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'Período: ${mesSelecionado == 0 ? "Todos os Meses" : DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(anoSelecionado, mesSelecionado))}',
        style: baseTextStyle,
      ),
      pw.Text(
        'Data da geração: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
        style: baseTextStyle,
      ),
    ],
  );
}

pw.Widget _buildSummaryTable(Map<String, dynamic> relatorio, pw.TextStyle baseTextStyle, pw.TextStyle boldTextStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: borderColor),
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBgColor),
        children: [
          _buildTableCell('Emprestado', relatorio['totalEmprestado'], baseTextStyle, boldTextStyle),
          _buildTableCell('Recebido', relatorio['totalRecebido'], baseTextStyle, boldTextStyle),
        ],
      ),
      pw.TableRow(
        children: [
          _buildTableCell('Lucro Esperado', relatorio['lucro'], baseTextStyle, boldTextStyle),
          _buildTableCell('Pendente', relatorio['pendente'], baseTextStyle, boldTextStyle),
        ],
      ),
    ],
  );
}

pw.Widget _buildTrendsTable(List tendencias, pw.TextStyle baseTextStyle, pw.TextStyle boldTextStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: borderColor),
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBgColor),
        children: [
          _buildTableHeader('Mês', boldTextStyle),
          _buildTableHeader('Valor', boldTextStyle),
        ],
      ),
      for (var tendencia in tendencias)
        pw.TableRow(
          children: [
            _buildTableCell(tendencia['mes'], null, baseTextStyle, boldTextStyle),
            _buildTableCell(null, tendencia['valor'], baseTextStyle, boldTextStyle),
          ],
        ),
    ],
  );
}

pw.Widget _buildLoansTable(List<Emprestimo> emprestimos, pw.TextStyle baseTextStyle, pw.TextStyle boldTextStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: borderColor),
    columnWidths: const {
      0: pw.FixedColumnWidth(120),
      1: pw.FixedColumnWidth(80),
      2: pw.FixedColumnWidth(60),
      3: pw.FixedColumnWidth(70),
      4: pw.FixedColumnWidth(80),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBgColor),
        children: [
          _buildTableHeader('Cliente', boldTextStyle),
          _buildTableHeader('Valor', boldTextStyle),
          _buildTableHeader('Parcelas', boldTextStyle),
          _buildTableHeader('Status', boldTextStyle),
          _buildTableHeader('Data Venc.', boldTextStyle),
        ],
      ),
      for (var emprestimo in emprestimos)
        pw.TableRow(
          children: [
            _buildTableCell(emprestimo.nome, null, baseTextStyle, boldTextStyle),
            _buildTableCell(null, emprestimo.valor, baseTextStyle, boldTextStyle),
            _buildTableCell('${emprestimo.parcelas}x', null, baseTextStyle, boldTextStyle),
            _buildStatusCell(_getStatus(emprestimo.parcelasDetalhes), baseTextStyle),
            _buildTableCell(
                emprestimo.dataVencimento == null ? '' : DateFormat('dd/MM/yyyy').format(emprestimo.dataVencimento!),
                null,
                baseTextStyle,
                boldTextStyle
            ),
          ],
        ),
    ],
  );
}

pw.Widget _buildInstallmentsTable(Emprestimo emprestimo, pw.TextStyle baseTextStyle, pw.TextStyle boldTextStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: borderColor),
    columnWidths: const {
      0: pw.FixedColumnWidth(40),
      1: pw.FixedColumnWidth(90),
      2: pw.FixedColumnWidth(80),
      3: pw.FixedColumnWidth(60),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBgColor),
        children: [
          _buildTableHeader('Parc.', boldTextStyle),
          _buildTableHeader('Vencimento', boldTextStyle),
          _buildTableHeader('Valor', boldTextStyle),
          _buildTableHeader('Status', boldTextStyle),
        ],
      ),
      for (var parcela in emprestimo.parcelasDetalhes)
        pw.TableRow(
          children: [
            _buildTableCell('${parcela['numero']}', null, baseTextStyle, boldTextStyle),
            _buildTableCell(parcela['dataVencimento'], null, baseTextStyle, boldTextStyle),
            _buildTableCell(null, parcela['valor'], baseTextStyle, boldTextStyle),
            _buildTableCell(parcela['status'], null, baseTextStyle, boldTextStyle),
          ],
        ),
    ],
  );
}

pw.Widget _buildTableCell(String? text, num? value, pw.TextStyle baseTextStyle, pw.TextStyle boldTextStyle) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (text != null)
          pw.Text(text, style: baseTextStyle),
        if (value != null)
          pw.Text(
            NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
              decimalDigits: 2,
            ).format(value),
            style: boldTextStyle,
          ),
      ],
    ),
  );
}

pw.Widget _buildTableHeader(String label, pw.TextStyle boldTextStyle) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      label,
      style: boldTextStyle,
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildStatusCell(String status, pw.TextStyle baseTextStyle) {
  PdfColor statusColor;
  switch (status) {
    case 'Quitado':
      statusColor = successColor;
      break;
    case 'Atrasado':
      statusColor = dangerColor;
      break;
    default:
      statusColor = warningColor;
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      status,
      style: baseTextStyle.copyWith(color: statusColor),
      textAlign: pw.TextAlign.center,
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