/// Service d'export PDF pour les états financiers SYCEBNL.
///
/// Génère des PDF professionnels pour : Balance, Résultat, Bilan, Grand livre.
/// Utilise le package `pdf` + `printing` pour prévisualisation et impression.
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:eab/features/etats_financiers/data/reports_repository.dart';

final _fmt = NumberFormat('#,##0', 'fr_FR');

/// Service de génération PDF.
class PdfExportService {
  /// Affiche la prévisualisation d'impression du PDF.
  static Future<void> preview(
    dynamic context,
    pw.Document doc,
    String title,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: title,
    );
  }

  // ══════════════════════════════════════════
  // BALANCE GÉNÉRALE
  // ══════════════════════════════════════════

  static pw.Document buildBalancePdf({
    required String orgName,
    required String periode,
    required List<LigneBalance> lignes,
  }) {
    final doc = pw.Document();

    final totalD = lignes.fold(0.0, (s, l) => s + l.totalDebit);
    final totalC = lignes.fold(0.0, (s, l) => s + l.totalCredit);
    final totalSD = lignes.fold(0.0, (s, l) => s + l.soldeDebiteur);
    final totalSC = lignes.fold(0.0, (s, l) => s + l.soldeCrediteur);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => _header(orgName, 'Balance Générale', periode),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(80),
              5: const pw.FixedColumnWidth(80),
            },
            children: [
              _tableHeader(['N°', 'Intitulé', 'Débit', 'Crédit', 'Solde D', 'Solde C']),
              ...lignes.map((l) => pw.TableRow(
                children: [
                  _cell(l.numero, bold: true),
                  _cell(l.intitule),
                  _cellNum(l.totalDebit),
                  _cellNum(l.totalCredit),
                  _cellNum(l.soldeDebiteur > 0 ? l.soldeDebiteur : null),
                  _cellNum(l.soldeCrediteur > 0 ? l.soldeCrediteur : null),
                ],
              )),
              // Totaux
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('', bold: true),
                  _cell('TOTAL', bold: true),
                  _cellNum(totalD, bold: true),
                  _cellNum(totalC, bold: true),
                  _cellNum(totalSD, bold: true),
                  _cellNum(totalSC, bold: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  // ══════════════════════════════════════════
  // COMPTE DE RÉSULTAT
  // ══════════════════════════════════════════

  static pw.Document buildResultatPdf({
    required String orgName,
    required String periode,
    required List<LigneResultat> lignes,
  }) {
    final doc = pw.Document();

    final produits = lignes.where((l) => l.section == 'produits').toList();
    final charges = lignes.where((l) => l.section == 'charges').toList();
    final totalP = produits.fold(0.0, (s, l) => s + l.montant);
    final totalC = charges.fold(0.0, (s, l) => s + l.montant);
    final resultat = totalP - totalC;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _header(orgName, 'Compte de Résultat', periode),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          // Résultat net
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: resultat >= 0 ? PdfColors.green50 : PdfColors.red50,
              border: pw.Border.all(
                color: resultat >= 0 ? PdfColors.green200 : PdfColors.red200,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                '${resultat >= 0 ? "BÉNÉFICE NET" : "PERTE NETTE"} : ${_fmt.format(resultat.abs())} FCFA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: resultat >= 0 ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Produits
          pw.Text('PRODUITS — ${_fmt.format(totalP)} FCFA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _simpleTable(produits),
          pw.SizedBox(height: 16),

          // Charges
          pw.Text('CHARGES — ${_fmt.format(totalC)} FCFA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _simpleTable(charges),
        ],
      ),
    );
    return doc;
  }

  // ══════════════════════════════════════════
  // BILAN
  // ══════════════════════════════════════════

  static pw.Document buildBilanPdf({
    required String orgName,
    required String dateFin,
    required List<LigneBilan> lignes,
  }) {
    final doc = pw.Document();

    final actif = lignes.where((l) => l.section == 'actif').toList();
    final passif = lignes.where((l) => l.section == 'passif').toList();
    final totalA = actif.fold(0.0, (s, l) => s + l.solde);
    final totalP = passif.fold(0.0, (s, l) => s + l.solde);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => _header(orgName, 'Bilan', 'Au $dateFin'),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _bilanColumn('ACTIF', totalA, actif)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _bilanColumn('PASSIF', totalP, passif)),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  // ══════════════════════════════════════════
  // GRAND LIVRE
  // ══════════════════════════════════════════

  static pw.Document buildGrandLivrePdf({
    required String orgName,
    required String periode,
    required List<LigneGrandLivre> lignes,
  }) {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (ctx) => _header(orgName, 'Grand Livre', periode),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(50),
              1: const pw.FixedColumnWidth(65),
              2: const pw.FixedColumnWidth(30),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FlexColumnWidth(3),
              5: const pw.FixedColumnWidth(70),
              6: const pw.FixedColumnWidth(70),
              7: const pw.FixedColumnWidth(70),
            },
            children: [
              _tableHeader(['Compte', 'Date', 'Jnl', 'Réf', 'Libellé', 'Débit', 'Crédit', 'Solde']),
              ...lignes.map((l) => pw.TableRow(
                children: [
                  _cell(l.compteNumero, fontSize: 7),
                  _cell(dateFmt.format(l.ecritureDate), fontSize: 7),
                  _cell(l.journalCode, fontSize: 7),
                  _cell(l.referencePiece ?? '', fontSize: 7),
                  _cell(l.ligneLibelle ?? l.ecritureLibelle, fontSize: 7),
                  _cellNum(l.debit > 0 ? l.debit : null, fontSize: 7),
                  _cellNum(l.credit > 0 ? l.credit : null, fontSize: 7),
                  _cellNum(l.soldeCumule, fontSize: 7, color: l.soldeCumule >= 0 ? PdfColors.green800 : PdfColors.red800),
                ],
              )),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  // ══════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════

  static pw.Widget _header(String org, String title, String periode) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(org,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(periode, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
        pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.TableRow _tableHeader(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      children: labels.map((l) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(l, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      )).toList(),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, double fontSize = 8, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _cellNum(double? value, {bool bold = false, double fontSize = 8, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          value != null ? _fmt.format(value) : '',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
            color: color,
          ),
        ),
      ),
    );
  }

  static pw.Widget _simpleTable(List<LigneResultat> lignes) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(100),
      },
      children: [
        _tableHeader(['N°', 'Intitulé', 'Montant']),
        ...lignes.map((l) => pw.TableRow(children: [
          _cell(l.numero),
          _cell(l.intitule),
          _cellNum(l.montant),
        ])),
      ],
    );
  }

  static pw.Widget _bilanColumn(String title, double total, List<LigneBilan> lignes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('${_fmt.format(total)} FCFA',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        ...lignes.map((l) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 4),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 40, child: pw.Text(l.numero, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(child: pw.Text(l.intitule, style: const pw.TextStyle(fontSize: 8))),
              pw.Text('${_fmt.format(l.solde)} FCFA', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        )),
      ],
    );
  }
}

/// Service d'export CSV (pour Excel).
class CsvExportService {
  /// Exporte la balance en CSV.
  static String balanceToCsv(List<LigneBalance> lignes) {
    final rows = [
      ['N°', 'Intitulé', 'Nature', 'Débit', 'Crédit', 'Solde Débiteur', 'Solde Créditeur'],
      ...lignes.map((l) => [
        l.numero,
        l.intitule,
        l.nature,
        l.totalDebit.toStringAsFixed(2),
        l.totalCredit.toStringAsFixed(2),
        l.soldeDebiteur.toStringAsFixed(2),
        l.soldeCrediteur.toStringAsFixed(2),
      ]),
    ];
    return rows.map((r) => r.join(';')).join('\n');
  }

  /// Exporte le grand livre en CSV.
  static String grandLivreToCsv(List<LigneGrandLivre> lignes) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final rows = [
      ['Compte', 'Intitulé', 'Date', 'Journal', 'Réf', 'Libellé', 'Débit', 'Crédit', 'Solde'],
      ...lignes.map((l) => [
        l.compteNumero,
        l.compteIntitule,
        dateFmt.format(l.ecritureDate),
        l.journalCode,
        l.referencePiece ?? '',
        l.ligneLibelle ?? l.ecritureLibelle,
        l.debit.toStringAsFixed(2),
        l.credit.toStringAsFixed(2),
        l.soldeCumule.toStringAsFixed(2),
      ]),
    ];
    return rows.map((r) => r.join(';')).join('\n');
  }

  /// Exporte le compte de résultat en CSV.
  static String resultatToCsv(List<LigneResultat> lignes) {
    final rows = [
      ['Section', 'N°', 'Intitulé', 'Montant'],
      ...lignes.map((l) => [
        l.section,
        l.numero,
        l.intitule,
        l.montant.toStringAsFixed(2),
      ]),
    ];
    return rows.map((r) => r.join(';')).join('\n');
  }
}
