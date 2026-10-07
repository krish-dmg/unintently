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

        final fontCal = FontCalibration.forFont(doc.fontFamily);
        final double baseFontSize = lineSpacing * 0.82;
        final double fontSize = (baseFontSize * fontCal.scale).clamp(14.0, 28.0);

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
                        fontSize: (fontSize * 0.95).clamp(13.0, 22.0),
                        fontWeight: FontWeight.bold,
                        color: Color(doc.questionColorValue),
                      ),
                    ),
                  ),
                ),

              // 4. Positioned Ruled Lines matching paper rulings
              ...List.generate(pageLines.length, (lineIdx) {
                final lineItem = pageLines[lineIdx];
                if (lineItem.isBlank && lineItem.marginLabel.isEmpty) {
                  return const SizedBox.shrink();
                }

                final double baselineY = firstLineY + (lineIdx * lineSpacing);
                final double topPos = baselineY - (fontSize * fontCal.ascentRatio);
                final inkColor = lineItem.isQuestion
                    ? Color(doc.questionColorValue)
                    : Color(doc.answerColorValue);

                return Stack(
                  children: [
                    // Margin indicator (Q.1, Ans.) placed in the left margin column
                    if (lineItem.marginLabel.isNotEmpty)
                      Positioned(
                        top: topPos,
                        left: 4.0,
                        width: (leftMargin - 8.0).clamp(12.0, leftMargin),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            lineItem.marginLabel,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontFamily: doc.fontFamily,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: inkColor,
                            ),
                          ),
                        ),
                      ),

                    // Ruled body text placed to the right of the vertical margin rule
                    if (lineItem.text.isNotEmpty)
                      Positioned(
                        top: topPos,
                        left: leftMargin + (w * 0.015),
                        width: (availableW - (w * 0.015)).clamp(40.0, w),
                        child: Text(
                          lineItem.text,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: doc.fontFamily,
                            fontSize: fontSize,
                            fontWeight: lineItem.isQuestion ? FontWeight.bold : FontWeight.normal,
                            color: inkColor,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
