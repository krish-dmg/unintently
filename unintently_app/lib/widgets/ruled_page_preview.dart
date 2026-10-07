import 'package:flutter/material.dart';
import '../models/assignment_doc.dart';
import '../services/layout_engine.dart';

class RuledPagePreview extends StatelessWidget {
  final AssignmentDoc doc;
  final int pageIndex;
  final List<List<RuledLineItem>> pages;
  final PaperMetrics metrics;

  const RuledPagePreview({
    super.key,
    required this.doc,
    required this.pageIndex,
    required this.pages,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        // Standard A4 aspect ratio 1 : 1.414
        final double h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (w * 1.414);

        final pageLines = (pageIndex < pages.length) ? pages[pageIndex] : <RuledLineItem>[];
        final double leftMargin = w * metrics.leftMarginRatio;
        final double rightMargin = w * metrics.rightMarginRatio;
        final double availableW = w - leftMargin - rightMargin;
        final double firstLineY = h * metrics.firstLineTopRatio;
        final double lineSpacing = h * metrics.lineSpacingRatio;
        final double headerY = h * metrics.headerTopRatio;

        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Paper Template Background
              Positioned.fill(
                child: Image.asset(
                  doc.paperAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (ctx, err, stack) => Container(color: Colors.white),
                ),
              ),

              // 2. Real Mobile Shadow (PE.jpeg)
              if (doc.hasMobileShadow)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.42,
                    child: Image.asset(
                      'assets/images/PE.jpeg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

              // 3. Top Header Box
              if (doc.heading.isNotEmpty && pageIndex == 0)
                Positioned(
                  top: headerY,
                  left: leftMargin,
                  right: rightMargin,
                  child: Center(
                    child: Text(
                      doc.heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: doc.fontFamily,
                        fontSize: (w * 0.036).clamp(11.0, 18.0),
                        fontWeight: FontWeight.bold,
                        color: Color(doc.questionColorValue),
                      ),
                    ),
                  ),
                ),

              // 4. Positioned Ruled Lines matching paper rulings
              ...List.generate(pageLines.length, (lineIdx) {
                final lineItem = pageLines[lineIdx];
                if (lineItem.isBlank || lineItem.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                final double baselineY = firstLineY + (lineIdx * lineSpacing);
                final double fontSize = lineItem.isQuestion
                    ? (w * 0.030).clamp(10.0, 15.0)
                    : (w * 0.028).clamp(9.5, 14.5);
                final double topPos = baselineY - (fontSize * 0.82);

                return Positioned(
                  top: topPos,
                  left: leftMargin,
                  width: availableW,
                  child: Text(
                    lineItem.text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: doc.fontFamily,
                      fontSize: fontSize,
                      fontWeight: lineItem.isQuestion ? FontWeight.bold : FontWeight.normal,
                      color: lineItem.isQuestion
                          ? Color(doc.questionColorValue)
                          : Color(doc.answerColorValue),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
