import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/eleve_model.dart';

/// Génération et partage des documents officiels (bulletin, carte scolaire)
/// pour que les parents / élèves puissent les imprimer et les télécharger
/// depuis leur téléphone.
class DocumentService {
  DocumentService._();

  // Palette (alignée sur l'app : indigo gàra + accent bleu, plus d'or/jaune).
  static const _indigo = PdfColor.fromInt(0xFF22315B);
  static const _bleu = PdfColor.fromInt(0xFF2E7CB8);
  static const _bleuClair = PdfColor.fromInt(0xFF5AA9DC);
  static const _vert = PdfColor.fromInt(0xFF2E7D4F);
  static const _rouge = PdfColor.fromInt(0xFFD32F2F);
  static const _grisLigne = PdfColor.fromInt(0xFF9AA0A6);

  static pw.MemoryImage? _logoCache;

  static Future<pw.MemoryImage> _logo() async {
    if (_logoCache != null) return _logoCache!;
    final bytes = await rootBundle.load('assets/brand/netaa-mark.png');
    _logoCache = pw.MemoryImage(bytes.buffer.asUint8List());
    return _logoCache!;
  }

  static String _periodeLabel(String p) {
    switch (p) {
      case 'TRIMESTRE_1':
        return '1er trimestre';
      case 'TRIMESTRE_2':
        return '2e trimestre';
      case 'TRIMESTRE_3':
        return '3e trimestre';
      case 'SEMESTRE_1':
        return '1er semestre';
      case 'SEMESTRE_2':
        return '2e semestre';
      default:
        if (p.startsWith('COMPOSITION_')) {
          return 'Composition n°${p.split('_').last}';
        }
        return p.replaceAll('_', ' ');
    }
  }

  static String _n(double v) => v.toStringAsFixed(2);
  static String _light(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? v.toStringAsFixed(0) : s;
  }

  // ---------------------------------------------------------------------------
  // BULLETIN
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildBulletinPdf(
    BulletinModel b, {
    required String etablissement,
  }) async {
    final doc = pw.Document(title: 'Bulletin ${b.eleveMatricule}');
    final logo = await _logo();

    final moyOfficielle =
        b.moyenneGenerale > 0 ? b.moyenneGenerale : b.moyenneCalculee;
    final moyColor = moyOfficielle < 10 ? _rouge : _vert;

    pw.Widget cell(String txt,
        {pw.Alignment align = pw.Alignment.center,
        bool bold = false,
        PdfColor? color,
        double size = 9}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          txt,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );
    }

    final tableHeader = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEDED)),
      children: [
        cell('Matières', align: pw.Alignment.centerLeft, bold: true),
        cell('Coef.', bold: true),
        cell('Total obtenu', bold: true),
        cell('Moy. / 20', bold: true),
        cell('Moy. × Coef.', bold: true),
        cell('Détail des notes', align: pw.Alignment.centerLeft, bold: true),
      ],
    );

    final tableRows = b.lignes.map((l) {
      final hasNotes = l.notes.isNotEmpty;
      return pw.TableRow(children: [
        cell(l.matiereNom, align: pw.Alignment.centerLeft, bold: true),
        cell(_light(l.coefficient)),
        cell(hasNotes
            ? '${_light(l.totalObtenu)} / ${_light(l.totalBareme)}'
            : '-'),
        cell(l.moyenneEleve > 0 ? _n(l.moyenneEleve) : '-',
            bold: true, color: l.moyenneEleve < 10 && l.moyenneEleve > 0 ? _rouge : null),
        cell(l.moyenneEleve > 0 ? _n(l.points) : '-', bold: true),
        cell(
          hasNotes
              ? l.notes
                  .map((n) => '${_light(n.valeur)}/${_light(n.noteMax)}')
                  .join(', ')
              : 'Aucune note',
          align: pw.Alignment.centerLeft,
          size: 8,
        ),
      ]);
    }).toList();

    final footerTotaux = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEDED)),
      children: [
        cell('TOTAUX', align: pw.Alignment.centerRight, bold: true),
        cell(_light(b.totalCoefficients), bold: true),
        cell(''),
        cell(''),
        cell(_n(b.totalPoints), bold: true),
        cell('Total des points ÷ total des coef.',
            align: pw.Alignment.centerLeft, size: 7),
      ],
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Bandeau République du Mali
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉPUBLIQUE DU MALI',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Un Peuple - Un But - Une Foi',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700)),
                    pw.Text("MINISTÈRE DE L'ÉDUCATION NATIONALE",
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('BULLETIN OFFICIEL DE NOTES',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _indigo)),
                    pw.Text('ANNÉE SCOLAIRE ${b.anneeScolaire}',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: _indigo, thickness: 1.5),
            pw.SizedBox(height: 8),

            // Établissement + logo + intitulé période
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(
                        height: 52, width: 52, child: pw.Image(logo)),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          etablissement.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: _indigo),
                        ),
                        pw.Text('Enseignement général, technique & professionnel',
                            style: pw.TextStyle(fontSize: 9, color: _bleu)),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _indigo, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('BULLETIN DE NOTES',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _indigo)),
                      pw.Text(_periodeLabel(b.periode),
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _bleu)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Bloc identité élève
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _indigo, width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
                color: const PdfColor.fromInt(0xFFFAFAFA),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                                text: 'Nom & prénom(s) : ',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(
                                text:
                                    '${b.eleveNom.toUpperCase()} ${b.elevePrenom}',
                                style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _indigo)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                                text: 'Matricule : ',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(
                                text: b.eleveMatricule,
                                style: pw.TextStyle(
                                    fontSize: 10, color: _bleu)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                                text: 'Classe : ',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(
                                text: b.classeNom,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _indigo)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (b.rang != null)
                        pw.Text(
                            'Rang : ${b.rang}${b.effectifClasse != null ? ' / ${b.effectifClasse}' : ''}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Tableau des matières
            pw.Table(
              border: pw.TableBorder.all(color: _grisLigne, width: 0.6),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.4),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.1),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(3),
              },
              children: [
                tableHeader,
                ...tableRows,
                if (b.lignes.isEmpty)
                  pw.TableRow(children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      alignment: pw.Alignment.center,
                      child: pw.Text('Aucune matière enregistrée.'),
                    ),
                    cell(''), cell(''), cell(''), cell(''), cell(''),
                  ]),
                footerTotaux,
              ],
            ),
            pw.SizedBox(height: 10),

            // Moyenne générale + calcul visible
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFE0E0E0),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('MOYENNE GÉNÉRALE',
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${_n(b.totalPoints)} ÷ ${_light(b.totalCoefficients)} = ${_n(b.moyenneCalculee)}',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text('${_n(moyOfficielle)} / 20',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: moyColor)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Appréciation + signatures
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    height: 96,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _indigo, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('APPRÉCIATION DU CONSEIL',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _indigo)),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          b.appreciationGenerale.isNotEmpty
                              ? b.appreciationGenerale
                              : '— Élève assidu, poursuivez vos efforts.',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  width: 150,
                  height: 96,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _indigo, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("LE CHEF D'ÉTABLISSEMENT",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _indigo)),
                      pw.Spacer(),
                      pw.Text('(Signature & cachet)',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),

            if (b.urlVerification != null) ...[
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  color: PdfColors.white,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: b.urlVerification!,
                    width: 48,
                    height: 48,
                    drawText: false,
                  ),
                ),
              ),
            ],

            pw.Spacer(),
            pw.Divider(color: _grisLigne, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Édité via Netaa École',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey600)),
                if (b.estVerrouille)
                  pw.Text('Bulletin verrouillé — validé en conseil de classe',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: _vert,
                          fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // CARTE SCOLAIRE
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildCartePdf({
    required String prenom,
    required String nom,
    required String matricule,
    required String classe,
    required String etablissement,
    String anneeScolaire = '2026/2027',
    String statut = 'ACTIF',
  }) async {
    final doc = pw.Document(title: 'Carte scolaire $matricule');
    final logo = await _logo();

    // Format carte agrandi (proportions CR80 : 85.6 × 54) pour rester lisible.
    const cardW = 340.0;
    const cardH = 214.0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: cardW,
                height: cardH,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _indigo,
                  borderRadius: pw.BorderRadius.circular(14),
                  border: pw.Border.all(color: _bleu, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Row(children: [
                            pw.SizedBox(
                                height: 26, width: 26, child: pw.Image(logo)),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(etablissement.toUpperCase(),
                                      maxLines: 1,
                                      overflow: pw.TextOverflow.clip,
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                          color: _bleuClair)),
                                  pw.Text("CARTE D'IDENTITÉ SCOLAIRE",
                                      style: const pw.TextStyle(
                                          fontSize: 6,
                                          color: PdfColors.white)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _vert, width: 0.8),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(statut,
                              style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _vert)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(height: 0.7, color: _bleu),
                    pw.SizedBox(height: 10),
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('$prenom ${nom.toUpperCase()}',
                                        style: pw.TextStyle(
                                            fontSize: 15,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.white)),
                                    pw.SizedBox(height: 2),
                                    pw.Text(classe,
                                        style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _bleuClair)),
                                  ],
                                ),
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    _carteLine('MATRICULE', matricule),
                                    _carteLine('ANNÉE', anneeScolaire),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                color: PdfColors.white,
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: 'NETAA-VERIFY-$matricule',
                                  width: 74,
                                  height: 74,
                                  drawText: false,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text('Scanner pour vérifier',
                                  style: const pw.TextStyle(
                                      fontSize: 6, color: PdfColors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'Carte scolaire numérique — $etablissement',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                'Document généré via Netaa École. Vérifiable par QR code.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _carteLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 46,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 6, color: PdfColors.white)),
          ),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Impression / partage (fonctionne sur web ET mobile natif)
  // ---------------------------------------------------------------------------

  /// Ouvre la boîte d'impression du système (sur le web : dialogue navigateur
  /// → « Enregistrer au format PDF » ou imprimante).
  static Future<void> imprimer(Uint8List bytes, {String? nom}) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: nom ?? 'document',
    );
  }

  /// Ouvre la feuille de partage / téléchargement du fichier.
  static Future<void> partager(Uint8List bytes, String filename) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
