import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/assignment_doc.dart';

class PdfExportService {
  static Future<Uint8List> generatePdf(AssignmentDoc doc) async {
    final pdf = pw.Document();

    pw.Font handwritingFont;
    try {
      handwritingFont = await fontFromAssetBundle('assets/fonts/${doc.fontFamily}.otf');
    } catch (_) {
      try {
        handwritingFont = await fontFromAssetBundle('assets/fonts/${doc.fontFamily}.ttf');
      } catch (_) {
        handwritingFont = await fontFromAssetBundle('assets/fonts/intentlyR1.otf');
      }
    }

    pw.MemoryImage? paperImage;
    try {
      final ByteData data = await rootBundle.load(doc.paperAsset);
      paperImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      paperImage = null;
    }

    pw.MemoryImage? shadowImage;
    if (doc.hasMobileShadow) {
      try {
        final ByteData data = await rootBundle.load('assets/images/PE.jpeg');
        shadowImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        shadowImage = null;
      }
    }

    final qColor = PdfColor.fromInt(doc.questionColorValue);
    final aColor = PdfColor.fromInt(doc.answerColorValue);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Paper Background Texture
              if (paperImage != null)
                pw.Positioned.fill(
                  child: pw.Image(paperImage, fit: pw.BoxFit.fill),
                ),

              // 2. Mobile Shadow Effect (PE.jpeg)
              if (shadowImage != null)
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.35,
                    child: pw.Image(shadowImage, fit: pw.BoxFit.fill),
                  ),
                ),

              // 3. Document Content
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 55, left: 45, right: 35, bottom: 35),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (doc.heading.isNotEmpty) ...[
                      pw.Center(
                        child: pw.Text(
                          doc.heading,
                          style: pw.TextStyle(
                            font: handwritingFont,
                            fontSize: doc.fontSize + 4,
                            fontWeight: pw.FontWeight.bold,
                            color: qColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 14),
                    ],

                    if (doc.docType == 'general') ...[
                      pw.Text(
                        doc.generalContent,
                        style: pw.TextStyle(
                          font: handwritingFont,
                          fontSize: doc.fontSize,
                          lineSpacing: doc.lineSpacing * 2.0,
                          color: aColor,
                        ),
                      ),
                    ] else ...[
                      // Dynamic Q&A list from user inputs
                      ...List.generate(doc.items.length, (idx) {
                        final item = doc.items[idx];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Q${idx + 1}. ${item.question}',
                                style: pw.TextStyle(
                                  font: handwritingFont,
                                  fontSize: doc.fontSize,
                                  fontWeight: pw.FontWeight.bold,
                                  color: qColor,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Ans. ${item.answer}',
                                style: pw.TextStyle(
                                  font: handwritingFont,
                                  fontSize: doc.fontSize,
                                  lineSpacing: doc.lineSpacing * 2.0,
                                  color: aColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrSharePdf(AssignmentDoc doc) async {
    final bytes = await generatePdf(doc);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${doc.title.replaceAll(RegExp(r'\s+'), '_')}.pdf',
    );
  }
}
