import 'package:flutter/material.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';

class QrExtensionSyncScreen extends StatefulWidget {
  const QrExtensionSyncScreen({super.key});

  @override
  State<QrExtensionSyncScreen> createState() => _QrExtensionSyncScreenState();
}

class _QrExtensionSyncScreenState extends State<QrExtensionSyncScreen> {
  final TextEditingController _pasteCodeController = TextEditingController();

  void _importAssignmentJson(String rawText) async {
    try {
      final doc = AssignmentDoc.fromJson(rawText);
      await LocalStorageService.saveDoc(doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ChatGPT assignment imported successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Fallback: parse as simple text assignment
      final doc = AssignmentDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'ChatGPT Assignment',
        docType: 'general',
        generalContent: rawText,
      );
      await LocalStorageService.saveDoc(doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ChatGPT text imported successfully!')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ChatGPT to Assignment Sync'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/chatgpt-icon.svg',
                    width: 64,
                    height: 64,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Color(0xFF10A37F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sync from ChatGPT Extension',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate your answers on ChatGPT using our extension, then scan QR code or paste sync payload to import all Q&A instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scan QR / Paste Payload
            TextField(
              controller: _pasteCodeController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste ChatGPT sync payload or assignment JSON here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download),
                label: const Text('Import Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final text = _pasteCodeController.text.trim();
                  if (text.isNotEmpty) {
                    _importAssignmentJson(text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
