import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:facilite/data/models/emprestimo.dart';
import 'package:intl/intl.dart';

Future<void> gerarPdfEmprestimo(Emprestimo emprestimo) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('dd/MM/yyyy');
  final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Calculate loan values
  final valorTotal = emprestimo.valor * (1 + emprestimo.juros / 100);
  final valorParcela = valorTotal / emprestimo.parcelas;
  final lucro = valorTotal - emprestimo.valor;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          // Header with company info
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EMPRÉSTIMO FÁCIL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    )),
                pw.Text('Contrato de Empréstimo',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    )),
                pw.Divider(color: PdfColors.blue800),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Cliente Information Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INFORMAÇÕES DO CLIENTE',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    )),
                pw.SizedBox(height: 12),
                _buildInfoRow('Nome', emprestimo.nome),
                _buildInfoRow('CPF/CNPJ', emprestimo.cpfCnpj),
                _buildInfoRow('Telefone', emprestimo.whatsapp),
                if (emprestimo.email != null)
                  _buildInfoRow('Email', emprestimo.email!),
                if (emprestimo.endereco != null)
                  _buildInfoRow('Endereço', emprestimo.endereco!),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Loan Details Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DETALHES DO EMPRÉSTIMO',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    )),
                pw.SizedBox(height: 12),
                _buildInfoRow('Data do Contrato', dateFormat.format(emprestimo.data)),
                _buildInfoRow('Valor Principal', numberFormat.format(emprestimo.valor)),
                _buildInfoRow('Taxa de Juros', '${emprestimo.juros.toStringAsFixed(1)}%'),
                _buildInfoRow('Valor Total', numberFormat.format(valorTotal)),
                _buildInfoRow('Número de Parcelas', '${emprestimo.parcelas}x'),
                _buildInfoRow('Valor da Parcela', numberFormat.format(valorParcela)),
                _buildInfoRow('Periodicidade', emprestimo.tipoParcela),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Parcelas Table
          pw.Table.fromTextArray(
            context: context,
            border: null,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.blue800,
            ),
            headerHeight: 25,
            cellHeight: 40,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            headers: ['Nº', 'Vencimento', 'Valor', 'Status'],
            data: emprestimo.parcelasDetalhes.map((parcela) {
              return [
                '${parcela['numero']}',
                parcela['dataVencimento'],
                numberFormat.format(parcela['valor']),
                parcela['status'],
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 40),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide()),
                    ),
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text('Assinatura do Cliente',
                        textAlign: pw.TextAlign.center),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide()),
                    ),
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text('Assinatura do Credor',
                        textAlign: pw.TextAlign.center),
                  ),
                ],
              ),
            ],
          ),
        ];
      },
    ),
  );

  // Diretório do usuário no Windows
  final outputDir = Directory('${Platform.environment['USERPROFILE']}\\Documents\\Facilite');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Salvar PDF no diretório do usuário
  final file = File("${outputDir.path}\\emprestimo_${emprestimo.id}.pdf");
  await file.writeAsBytes(await pdf.save());

  // Abrir ou compartilhar o PDF
  await Printing.sharePdf(
      bytes: await pdf.save(), filename: 'emprestimo_${emprestimo.id}.pdf');
}

pw.Widget _buildInfoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(),
          ),
        ),
      ],
    ),
  );
}

Future<void> gerarContratoEmprestimo(Emprestimo emprestimo) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('dd/MM/yyyy');
  final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final valorTotal = emprestimo.valor * (1 + emprestimo.juros / 100);
  final valorParcela = valorTotal / emprestimo.parcelas;

  // Estilo padrão para títulos
  final titleStyle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue900,
  );

  // Estilo para subtítulos
  final subtitleStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue800,
  );

  // Estilo para texto normal
  final normalStyle = pw.TextStyle(
    fontSize: 11,
    color: PdfColors.black,
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (context) => pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.blue900,
                ),
                child: pw.Text(
                  'EMPRÉSTIMO FÁCIL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'Contrato: #${emprestimo.id}',
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 20),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Emitido em: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              'CONTRATO DE EMPRÉSTIMO',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 30),

          // Preâmbulo
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Pelo presente instrumento particular, as partes abaixo identificadas celebram este contrato de empréstimo, que se regerá pelas cláusulas e condições seguintes.',
              style: normalStyle,
              textAlign: pw.TextAlign.justify,
            ),
          ),
          pw.SizedBox(height: 20),

          // Seção 1 - Partes
          _buildSection(
            '1. PARTES',
            titleStyle,
            [
              _buildSubsection(
                'CREDOR:',
                subtitleStyle,
                'Facilite+, inscrita no CNPJ sob o nº 24.020.240/0001-24, com sede na Rua das Palmeiras, 123 - Bairro Jardim Florido, São Paulo - SP, CEP 01234-567.',
                normalStyle,
              ),
              pw.SizedBox(height: 10),
              _buildSubsection(
                'DEVEDOR:',
                subtitleStyle,
                '${emprestimo.nome}, inscrito(a) no CPF/CNPJ sob o nº ${emprestimo.cpfCnpj}, ${emprestimo.endereco != null ? 'residente em ${emprestimo.endereco}' : 'com endereço a ser informado'}.',
                normalStyle,
              ),
            ],
          ),

          // Seção 2 - Objeto
          _buildSection(
            '2. OBJETO DO CONTRATO',
            titleStyle,
            [
              _buildTable([
                ['Valor Principal:', numberFormat.format(emprestimo.valor)],
                ['Taxa de Juros:', '${emprestimo.juros.toStringAsFixed(2)}%'],
                ['Valor Total:', numberFormat.format(valorTotal)],
                ['Número de Parcelas:', '${emprestimo.parcelas}x de ${numberFormat.format(valorParcela)}'],
                ['Periodicidade:', emprestimo.tipoParcela],
              ], normalStyle),
            ],
          ),

          // Seção 3 - Pagamento
          _buildSection(
            '3. CONDIÇÕES DE PAGAMENTO',
            titleStyle,
            [
              pw.Paragraph(
                style: normalStyle,
                text: 'O valor será pago em ${emprestimo.parcelas} parcelas, conforme cronograma abaixo:',
              ),
              pw.SizedBox(height: 10),
              _buildParcelasTable(emprestimo.parcelasDetalhes, normalStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'Em caso de atraso, incidirá multa de 2% sobre o valor da parcela e juros de mora de 0,33% ao dia.',
                  style: normalStyle,
                ),
              ),
            ],
          ),

          // Seção 4 - Disposições
          _buildSection(
            '4. DISPOSIÇÕES GERAIS',
            titleStyle,
            [
              pw.Paragraph(
                style: normalStyle,
                text: 'Este contrato é regido pela Lei nº 10.406/2002 (Código Civil Brasileiro) e demais legislações aplicáveis.\n\n'
                    'O foro eleito para dirimir quaisquer questões relativas ao presente contrato será o da comarca de São Paulo - SP, com renúncia expressa a qualquer outro, por mais privilegiado que seja.',
              ),
            ],
          ),

          pw.SizedBox(height: 50),

          // Assinaturas
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildAssinatura('Credor - Facilite+', normalStyle),
                _buildAssinatura('Devedor - ${emprestimo.nome}', normalStyle),
              ],
            ),
          ),

          // Testemunhas
          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildAssinatura('Testemunha 1', normalStyle),
              _buildAssinatura('Testemunha 2', normalStyle),
            ],
          ),
        ];
      },
    ),
  );

  final outputDir = Directory('${Platform.environment['USERPROFILE']}\\Documents\\Facilite');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final file = File("${outputDir.path}\\contrato_${emprestimo.id}.pdf");
  await file.writeAsBytes(await pdf.save());

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'contrato_${emprestimo.id}.pdf',
  );
}

// Widgets auxiliares
pw.Widget _buildSection(String title, pw.TextStyle titleStyle, List<pw.Widget> content) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: titleStyle),
      pw.SizedBox(height: 10),
      ...content,
      pw.SizedBox(height: 20),
    ],
  );
}

pw.Widget _buildSubsection(String title, pw.TextStyle titleStyle, String content, pw.TextStyle contentStyle) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: titleStyle),
      pw.SizedBox(height: 4),
      pw.Text(content, style: contentStyle),
    ],
  );
}

pw.Widget _buildTable(List<List<String>> rows, pw.TextStyle style) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    children: rows.map((row) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: rows.indexOf(row) % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
        ),
        children: row.map((cell) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(cell, style: style),
          );
        }).toList(),
      );
    }).toList(),
  );
}

pw.Widget _buildParcelasTable(List<Map<String, dynamic>> parcelas, pw.TextStyle style) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FlexColumnWidth(1),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(2),
    },
    children: [
      // Cabeçalho
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.blue100),
        children: [
          _buildTableCell('Nº', style, header: true),
          _buildTableCell('Data de Vencimento', style, header: true),
          _buildTableCell('Valor', style, header: true),
        ],
      ),
      // Dados
      ...parcelas.map((parcela) => pw.TableRow(
        decoration: pw.BoxDecoration(
          color: parcelas.indexOf(parcela) % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
        ),
        children: [
          _buildTableCell(parcela['numero'].toString(), style),
          _buildTableCell(parcela['dataVencimento'], style),
          _buildTableCell(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
              .format(parcela['valor']), style),
        ],
      )),
    ],
  );
}

pw.Widget _buildTableCell(String text, pw.TextStyle style, {bool header = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: header ? style.copyWith(fontWeight: pw.FontWeight.bold) : style,
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildAssinatura(String texto, pw.TextStyle style) {
  return pw.Column(
    children: [
      pw.Container(
        width: 200,
        height: 1,
        color: PdfColors.black,
      ),
      pw.SizedBox(height: 5),
      pw.Text(texto, style: style),
    ],
  );
}