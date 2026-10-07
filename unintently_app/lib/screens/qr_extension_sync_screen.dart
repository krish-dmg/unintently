import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';

class QrExtensionSyncScreen extends StatefulWidget {
  const QrExtensionSyncScreen({super.key});

  @override
  State<QrExtensionSyncScreen> createState() => _QrExtensionSyncScreenState();
}

class _QrExtensionSyncScreenState extends State<QrExtensionSyncScreen> {
  final TextEditingController _pasteCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _importAssignmentJson(String rawInput) async {
    setState(() => _isLoading = true);

    String text = rawInput.trim();

    try {
      // 1. Check if input is a URL with payload parameter
      if (text.contains('data=')) {
        final uri = Uri.tryParse(text);
        if (uri != null && uri.queryParameters.containsKey('data')) {
          text = Uri.decodeComponent(uri.queryParameters['data']!);
        }
      }

      // 2. Check if input is base64 encoded
      if (!text.startsWith('{') && text.length > 20 && !text.contains(' ')) {
        try {
          final decoded = utf8.decode(base64.decode(text));
          if (decoded.startsWith('{')) {
            text = decoded;
          }
        } catch (_) {}
      }

      // 3. Check if input is a short sync code or remote URL
      if (!text.startsWith('{') && (text.startsWith('UNIN-') || text.startsWith('http'))) {
        String code = text;
        if (text.startsWith('http')) {
          final uri = Uri.parse(text);
          code = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : text;
        }

        // Attempt fetch from Cloudflare worker
        final candidateUrls = [
          'http://10.0.2.2:8787/assignments/$code',
          'http://localhost:8787/assignments/$code',
        ];

        for (final urlStr in candidateUrls) {
          try {
            final res = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 4));
            if (res.statusCode == 200) {
              final body = json.decode(res.body);
              if (body is Map && body.containsKey('assignment')) {
                text = json.encode(body['assignment']);
                break;
              }
            }
          } catch (_) {}
        }
      }

      // 4. Parse into AssignmentDoc
      final doc = AssignmentDoc.fromJson(text);
      await LocalStorageService.saveDoc(doc);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${doc.title}" with ${doc.items.length} Q&A items!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Fallback: parse as plain text general document
      final doc = AssignmentDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'ChatGPT Assignment',
        docType: 'general',
        generalContent: rawInput,
      );
      await LocalStorageService.saveDoc(doc);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imported content into a new assignment!'),
            backgroundColor: Color(0xFF0057D2),
          ),
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 36,
                      color: Color(0xFF0057D2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sync from ChatGPT Extension',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate your answers on ChatGPT using our browser extension, then paste the sync payload or scan the QR code to import all questions and answers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scan QR / Paste Payload
            TextField(
              controller: _pasteCodeController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Paste ChatGPT sync payload, JSON, or sync code here...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0057D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isLoading ? 'Importing...' : 'Import Assignment',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
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
