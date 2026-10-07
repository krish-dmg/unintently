import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/assignment_doc.dart';
import 'layout_engine.dart';

class PdfExportService {
  static Future<Uint8List> generatePdf(AssignmentDoc doc) async {
    final pdf = pw.Document();

    // 1. Load Handwriting Font
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

    // 2. Load Paper Background Image
    pw.MemoryImage? paperImage;
    try {
      final ByteData data = await rootBundle.load(doc.paperAsset);
      paperImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      paperImage = null;
    }

    // 3. Load Mobile Shadow Overlay Image (PE.jpeg) if enabled
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

    // 4. Calculate Ruling Geometry & Paginate
    final metrics = PaperMetrics.forAsset(doc.paperAsset);
    final List<List<RuledLineItem>> pages = AssignmentLayoutEngine.paginateDoc(doc, metrics);

    const double pageW = 595.28; // PdfPageFormat.a4.width
    const double pageH = 841.89; // PdfPageFormat.a4.height

    final double leftMargin = pageW * metrics.leftMarginRatio;
    final double rightMargin = pageW * metrics.rightMarginRatio;
    final double firstLineY = pageH * metrics.firstLineTopRatio;
    final double lineSpacing = pageH * metrics.lineSpacingRatio;
    final double headerY = pageH * metrics.headerTopRatio;

    for (int pIdx = 0; pIdx < pages.length; pIdx++) {
      final pageLines = pages[pIdx];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                // Layer 1: Background paper template
                if (paperImage != null)
                  pw.Positioned.fill(
                    child: pw.Image(paperImage, fit: pw.BoxFit.fill),
                  ),

                // Layer 2: Mobile Shadow overlay (PE.jpeg)
                if (shadowImage != null)
                  pw.Positioned.fill(
                    child: pw.Opacity(
                      opacity: 0.32,
                      child: pw.Image(shadowImage, fit: pw.BoxFit.fill),
                    ),
                  ),

                // Layer 3: Top Header Box (Subject / Heading)
                if (doc.heading.isNotEmpty && pIdx == 0)
                  pw.Positioned(
                    top: headerY,
                    left: leftMargin,
                    right: rightMargin,
                    child: pw.Center(
                      child: pw.Text(
                        doc.heading,
                        style: pw.TextStyle(
                          font: handwritingFont,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: qColor,
                        ),
                      ),
                    ),
                  ),

                // Layer 4: Text lines placed with sub-pixel baseline alignment on each ruled line
                ...List.generate(pageLines.length, (lineIdx) {
                  final lineItem = pageLines[lineIdx];
                  if (lineItem.isBlank || lineItem.text.isEmpty) {
                    return pw.SizedBox.shrink();
                  }

                  final double baselineY = firstLineY + (lineIdx * lineSpacing);
                  final double fontSize = lineItem.isQuestion ? 13.0 : 12.5;
                  // Baseline correction so handwriting strokes land on top of the ruling
                  final double topPos = baselineY - (fontSize * 0.80);

                  return pw.Positioned(
                    top: topPos,
                    left: leftMargin,
                    right: rightMargin,
                    child: pw.Text(
                      lineItem.text,
                      maxLines: 1,
                      style: pw.TextStyle(
                        font: handwritingFont,
                        fontSize: fontSize,
                        fontWeight: lineItem.isQuestion ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: lineItem.isQuestion ? qColor : aColor,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Compatibility alias for direct printing
  static Future<void> printOrSharePdf(AssignmentDoc doc) async {
    await printPdf(doc);
  }

  /// Saves the generated PDF locally to device storage and returns the file path
  static Future<String> savePdfToDevice(AssignmentDoc doc) async {
    final bytes = await generatePdf(doc);
    final String cleanTitle = doc.title.trim().isEmpty
        ? 'Assignment_${DateTime.now().millisecondsSinceEpoch}'
        : doc.title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');

    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/$cleanTitle.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  /// Opens the system share sheet for the PDF
  static Future<void> sharePdf(AssignmentDoc doc) async {
    final bytes = await generatePdf(doc);
    final String cleanTitle = doc.title.trim().isEmpty
        ? 'Assignment'
        : doc.title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: '$cleanTitle.pdf');
  }

  /// Opens the system print preview
  static Future<void> printPdf(AssignmentDoc doc) async {
    final bytes = await generatePdf(doc);
    final String cleanTitle = doc.title.trim().isEmpty
        ? 'Assignment'
        : doc.title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '$cleanTitle.pdf',
    );
  }
}
