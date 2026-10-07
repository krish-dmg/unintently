import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/assignment_model.dart';

class PdfExportService {
  /// Generate a print-ready PDF document with background paper texture and handwriting font
  static Future<Uint8List> generatePdf(AssignmentModel assignment) async {
    final pdf = pw.Document();

    // Load handwriting font
    pw.Font handwritingFont;
    try {
      handwritingFont = await fontFromAssetBundle('assets/fonts/${assignment.fontFamily}.otf');
    } catch (_) {
      try {
        handwritingFont = await fontFromAssetBundle('assets/fonts/${assignment.fontFamily}.ttf');
      } catch (_) {
        handwritingFont = await fontFromAssetBundle('assets/fonts/intentlyR1.otf');
      }
    }

    // Load background image bytes
    pw.MemoryImage? paperImage;
    try {
      final ByteData data = await rootBundle.load(assignment.paperAsset);
      paperImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      paperImage = null;
    }

    // Color conversion
    final inkColor = PdfColor.fromInt(assignment.fontColorValue);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (paperImage != null)
                pw.Positioned.fill(
                  child: pw.Image(paperImage, fit: pw.BoxFit.cover),
                ),
              pw.Padding(
                padding: pw.EdgeInsets.only(
                  top: assignment.topMargin,
                  left: assignment.leftMargin,
                  right: assignment.rightMargin,
                  bottom: assignment.bottomMargin,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (assignment.heading.isNotEmpty) ...[
                      pw.Text(
                        assignment.heading,
                        style: pw.TextStyle(
                          font: handwritingFont,
                          fontSize: assignment.fontSize + 6,
                          fontWeight: pw.FontWeight.bold,
                          color: inkColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    pw.Text(
                      assignment.content,
                      style: pw.TextStyle(
                        font: handwritingFont,
                        fontSize: assignment.fontSize,
                        lineSpacing: assignment.lineSpacing * 2.0,
                        letterSpacing: assignment.letterSpacing,
                        color: inkColor,
                      ),
                    ),
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

  /// Trigger system print or save PDF dialog
  static Future<void> printOrSharePdf(AssignmentModel assignment) async {
    final bytes = await generatePdf(assignment);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${assignment.title.replaceAll(RegExp(r'\s+'), '_')}.pdf',
    );
  }
}
