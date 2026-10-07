import 'package:flutter/material.dart';
import '../models/assignment_doc.dart';
import '../services/layout_engine.dart';
import '../services/pdf_export_service.dart';
import '../widgets/ruled_page_preview.dart';

class AssignmentPreviewScreen extends StatefulWidget {
  final AssignmentDoc doc;

  const AssignmentPreviewScreen({super.key, required this.doc});

  @override
  State<AssignmentPreviewScreen> createState() => _AssignmentPreviewScreenState();
}

class _AssignmentPreviewScreenState extends State<AssignmentPreviewScreen> {
  late PaperMetrics _metrics;
  late List<List<RuledLineItem>> _pages;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _metrics = PaperMetrics.forAsset(widget.doc.paperAsset);
    _pages = AssignmentLayoutEngine.paginateDoc(widget.doc, _metrics);
  }

  void _showGenerateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Assignment is Ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_pages.length} ${_pages.length == 1 ? "page" : "pages"} formatted with ${widget.doc.fontFamily}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  icon: Icons.download_outlined,
                  color: const Color(0xFF1D4ED8),
                  title: 'Download PDF',
                  subtitle: 'Save high-resolution PDF directly to device storage',
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = true);
                    try {
                      final path = await PdfExportService.savePdfToDevice(widget.doc);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF saved successfully to $path'),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save PDF: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
                const Divider(height: 12),
                _buildActionTile(
                  icon: Icons.share_outlined,
                  color: const Color(0xFF2563EB),
                  title: 'Share PDF',
                  subtitle: 'Send via WhatsApp, Gmail, Drive, or AirDrop',
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = true);
                    try {
                      await PdfExportService.sharePdf(widget.doc);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to share PDF: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
                const Divider(height: 12),
                _buildActionTile(
                  icon: Icons.print_outlined,
                  color: const Color(0xFF0F766E),
                  title: 'Print Document',
                  subtitle: 'Print pages directly on A4 printer paper',
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = true);
                    try {
                      await PdfExportService.printPdf(widget.doc);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to print document: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Assignment',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Vertically Scrollable List of Ruled Page Previews
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _pages.length,
                  itemBuilder: (context, pIdx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          // Page Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AspectRatio(
                              aspectRatio: 1 / 1.414,
                              child: RuledPagePreview(
                                doc: widget.doc,
                                pageIndex: pIdx,
                                pages: _pages,
                                metrics: _metrics,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Page ${pIdx + 1} of ${_pages.length}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Full-Width "Generate" Button (Matching Screenshot 01ebaa12)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: _isProcessing ? null : _showGenerateOptions,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Generate',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                  ),
                ),
              ),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
              ),
            ),
        ],
      ),
    );
  }
}
