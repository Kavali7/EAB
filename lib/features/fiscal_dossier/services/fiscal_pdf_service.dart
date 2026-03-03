/// Service de génération PDF multi-pages pour le dossier fiscal SYSCEBNL.
///
/// Produit un PDF "prêt à déposer" avec :
/// - Page COVER (page de garde)
/// - Page IDENTITY (identification de l'entité)
/// - Page BILAN_ACTIF (actif du bilan)
/// - Page BILAN_PASSIF (passif du bilan)
/// - Page RESULTAT (compte de résultat)
///
/// Chaque page est rendue dynamiquement depuis les champs template
/// et les valeurs saisies/calculées du dossier.
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';

import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';

// Lazy-initialized formatters (safely after locale init)
NumberFormat get _fmt => NumberFormat('#,##0', 'fr_FR');
DateFormat get _dateFmt => DateFormat('dd/MM/yyyy', 'fr_FR');

class FiscalPdfService {
  // ═══════════════════════════════════════════════════════════════════════
  // Point d'entrée : génère le PDF complet du dossier fiscal.
  // ═══════════════════════════════════════════════════════════════════════

  /// Génère le document PDF complet (async pour charger les polices Unicode).
  static Future<pw.Document> buildDossierPdf({
    required String orgName,
    required List<FiscalTemplatePage> pages,
    required Map<String, dynamic> values,
    String? watermark,
  }) async {
    // Sécurité : initialiser la locale fr_FR si pas encore fait
    await initializeDateFormatting('fr_FR');

    // Charger une police Google qui supporte les accents français
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final doc = pw.Document(
      title: 'Dossier Fiscal SYSCEBNL — $orgName',
      author: orgName,
      creator: 'EAB — Gestion Comptable',
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final generatedAt = DateTime.now();

    for (final page in pages) {
      switch (page.code) {
        case 'COVER':
          _addCoverPage(doc, orgName, page, values, generatedAt, watermark);
        case 'IDENTITY':
          _addIdentityPage(doc, orgName, page, values, generatedAt, pages.length);
        case 'BILAN_ACTIF':
          _addFinancialPage(doc, orgName, page, values, generatedAt, pages.length,
              sectionTitle: 'BILAN — ACTIF',
              highlightColor: PdfColors.blue800);
        case 'BILAN_PASSIF':
          _addFinancialPage(doc, orgName, page, values, generatedAt, pages.length,
              sectionTitle: 'BILAN — PASSIF',
              highlightColor: PdfColors.indigo800);
        case 'RESULTAT':
          _addFinancialPage(doc, orgName, page, values, generatedAt, pages.length,
              sectionTitle: 'COMPTE DE RÉSULTAT',
              highlightColor: PdfColors.green800);
        default:
          _addGenericPage(doc, orgName, page, values, generatedAt, pages.length);
      }
    }

    return doc;
  }

  /// Affiche la prévisualisation d'impression.
  static Future<void> preview(pw.Document doc, String title) async {
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: title,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAGE DE GARDE (COVER)
  // ═══════════════════════════════════════════════════════════════════════

  static void _addCoverPage(
    pw.Document doc,
    String orgName,
    FiscalTemplatePage page,
    Map<String, dynamic> values,
    DateTime generatedAt,
    String? watermark,
  ) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) {
          final exerciceLabel = _val(values, 'exercice.label') ?? 'Exercice fiscal';
          final dateDebut = _val(values, 'exercice.date_debut');
          final dateFin = _val(values, 'exercice.date_fin');
          final periode = (dateDebut != null && dateFin != null)
              ? 'Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}'
              : '';
          final responsable = _val(values, 'responsable.nom') ?? '';
          final currency = _val(values, 'currency') ?? 'FCFA';

          return pw.Stack(
            children: [
              // Watermark
              if (watermark != null)
                pw.Center(
                  child: pw.Transform.rotateBox(
                    angle: -0.5,
                    child: pw.Text(
                      watermark,
                      style: pw.TextStyle(
                        fontSize: 72,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey200,
                      ),
                    ),
                  ),
                ),
              // Content
              pw.Padding(
                padding: const pw.EdgeInsets.all(60),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 80),
                    // Badge SYSCEBNL
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'SYSCEBNL',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    // Title
                    pw.Text(
                      'DOSSIER FISCAL',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      width: 80,
                      height: 3,
                      color: PdfColors.amber700,
                    ),
                    pw.SizedBox(height: 30),
                    // Organization name
                    pw.Text(
                      orgName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 40),
                    // Exercice
                    pw.Container(
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: PdfColors.blueGrey300, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            exerciceLabel,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (periode.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Text(
                              periode,
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Devise : $currency',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    // Bottom
                    if (responsable.isNotEmpty)
                      pw.Text(
                        'Responsable : $responsable',
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700),
                      ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Document généré le ${_dateFmt.format(generatedAt)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAGE IDENTIFICATION (IDENTITY)
  // ═══════════════════════════════════════════════════════════════════════

  static void _addIdentityPage(
    pw.Document doc,
    String orgName,
    FiscalTemplatePage page,
    Map<String, dynamic> values,
    DateTime generatedAt,
    int totalPages,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) =>
            _pageHeader(orgName, page.title, generatedAt),
        footer: (ctx) => _pageFooter(ctx, generatedAt),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          _sectionTitle('Identification de l\'entité'),
          _infoRow('Dénomination', _val(values, 'org.name') ?? orgName),
          _infoRow('Exercice', _val(values, 'exercice.label') ?? '—'),
          _infoRow('Date début', _formatDate(_val(values, 'exercice.date_debut'))),
          _infoRow('Date fin', _formatDate(_val(values, 'exercice.date_fin'))),
          _infoRow('Devise', _val(values, 'currency') ?? 'FCFA'),
          _infoRow('Mode de production', _val(values, 'mode_production') ?? '—'),
          _infoRow('Responsable', _val(values, 'responsable.nom') ?? '—'),
          pw.SizedBox(height: 16),
          // Render any additional fields from the template
          ..._renderAdditionalFields(page, values, [
            'org.name', 'exercice.label', 'exercice.date_debut',
            'exercice.date_fin', 'currency', 'mode_production',
            'responsable.nom',
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAGES FINANCIÈRES (BILAN_ACTIF, BILAN_PASSIF, RESULTAT)
  // ═══════════════════════════════════════════════════════════════════════

  static void _addFinancialPage(
    pw.Document doc,
    String orgName,
    FiscalTemplatePage page,
    Map<String, dynamic> values,
    DateTime generatedAt,
    int totalPages, {
    required String sectionTitle,
    PdfColor highlightColor = PdfColors.blueGrey800,
  }) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) =>
            _pageHeader(orgName, sectionTitle, generatedAt),
        footer: (ctx) => _pageFooter(ctx, generatedAt),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.SizedBox(height: 4));

          // Group fields by section
          final sections = <String?, List<FiscalTemplateField>>{};
          for (final f in page.fields) {
            sections.putIfAbsent(f.section, () => []);
            sections[f.section]!.add(f);
          }

          for (final entry in sections.entries) {
            final sectionName = entry.key;
            final fields = entry.value;

            if (sectionName != null && sectionName.isNotEmpty) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(
                      left: pw.BorderSide(color: highlightColor, width: 3),
                    ),
                  ),
                  child: pw.Text(
                    sectionName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: highlightColor,
                    ),
                  ),
                ),
              );
            }

            // Render fields as table rows
            widgets.add(
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(120),
                },
                children: fields.map((field) {
                  final rawValue = values[field.fieldKey];
                  final displayValue =
                      _formatFieldValue(field, rawValue);

                  return pw.TableRow(
                    decoration: field.isBold || field.isHighlighted
                        ? const pw.BoxDecoration(color: PdfColors.grey50)
                        : null,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: pw.Text(
                          field.label,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: field.isBold
                                ? pw.FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            displayValue,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: field.isBold
                                  ? pw.FontWeight.bold
                                  : null,
                              color: field.isHighlighted
                                  ? highlightColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          }

          return widgets;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAGE GÉNÉRIQUE (fallback pour pages V2+)
  // ═══════════════════════════════════════════════════════════════════════

  static void _addGenericPage(
    pw.Document doc,
    String orgName,
    FiscalTemplatePage page,
    Map<String, dynamic> values,
    DateTime generatedAt,
    int totalPages,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) =>
            _pageHeader(orgName, page.title, generatedAt),
        footer: (ctx) => _pageFooter(ctx, generatedAt),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.SizedBox(height: 4));

          for (final field in page.fields) {
            final rawValue = values[field.fieldKey];
            final displayValue = _formatFieldValue(field, rawValue);
            widgets.add(_infoRow(field.label, displayValue));
          }

          return widgets;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS — Header / Footer
  // ═══════════════════════════════════════════════════════════════════════

  static pw.Widget _pageHeader(
    String orgName,
    String pageTitle,
    DateTime generatedAt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(orgName,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('Dossier Fiscal SYSCEBNL',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
            pw.Text(pageTitle,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800)),
          ],
        ),
        pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx, DateTime generatedAt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Généré le ${_dateFmt.format(generatedAt)} à ${DateFormat('HH:mm').format(generatedAt)}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS — Content rendering
  // ═══════════════════════════════════════════════════════════════════════

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(' :  ', style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Rend les champs supplémentaires (non déjà affichés manuellement).
  static List<pw.Widget> _renderAdditionalFields(
    FiscalTemplatePage page,
    Map<String, dynamic> values,
    List<String> exclude,
  ) {
    final widgets = <pw.Widget>[];
    for (final field in page.fields) {
      if (exclude.contains(field.fieldKey)) continue;
      final rawValue = values[field.fieldKey];
      final displayValue = _formatFieldValue(field, rawValue);
      if (displayValue.isNotEmpty && displayValue != '—') {
        widgets.add(_infoRow(field.label, displayValue));
      }
    }
    return widgets;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS — Value formatting
  // ═══════════════════════════════════════════════════════════════════════

  /// Extrait une valeur du map (gère JSONB wrapping).
  static String? _val(Map<String, dynamic> values, String key) {
    final v = values[key];
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// Formate une date ISO en dd/MM/yyyy.
  static String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      return _dateFmt.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// Formate la valeur d'un champ template pour affichage PDF.
  static String _formatFieldValue(FiscalTemplateField field, dynamic value) {
    if (value == null) return '—';

    switch (field.fieldType) {
      case 'money':
        final num = _toDouble(value);
        return '${_fmt.format(num)} FCFA';
      case 'date':
        return _formatDate(value.toString());
      case 'bool':
        return (value == true || value == 'true') ? 'Oui' : 'Non';
      case 'percent':
        return '${_toDouble(value).toStringAsFixed(1)} %';
      case 'integer':
        return _toDouble(value).toInt().toString();
      default:
        final s = value.toString();
        // Clean JSON string wrapping (from JSONB)
        if (s.startsWith('"') && s.endsWith('"')) {
          return s.substring(1, s.length - 1);
        }
        return s;
    }
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
