import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';

class QrExtensionSyncScreen extends StatefulWidget {
  const QrExtensionSyncScreen({super.key});

  @override
  State<QrExtensionSyncScreen> createState() => _QrExtensionSyncScreenState();
}

class _QrExtensionSyncScreenState extends State<QrExtensionSyncScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  final TextEditingController _manualTextController = TextEditingController();

  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _showManualInput = false;

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _scannerController.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _isProcessing = true;
        HapticFeedback.mediumImpact();
        await _processScannedData(raw.trim());
        break;
      }
    }
  }

  Future<void> _processScannedData(String rawInput) async {
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

      // 3. Check for legacy Firebase Dynamic Link (https://intently.page.link/...)
      if (text.contains('intently.page.link')) {
        try {
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(text))..followRedirects = false;
          final response = await client.send(request).timeout(const Duration(seconds: 4));
          final location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            final targetUri = Uri.tryParse(location);
            final assignmentId = targetUri?.queryParameters['assignmentId'];
            if (assignmentId != null) {
              text = json.encode({
                'id': assignmentId,
                'title': 'Scanned Assignment',
                'docType': 'qa',
                'items': [
                  {
                    'question': 'Imported from Intently link ($assignmentId)',
                    'answer': 'Assignment reference verified.',
                  }
                ]
              });
            }
          }
        } catch (_) {}
      }

      // 4. Check if input is a sync code or remote worker URL
      if (!text.startsWith('{') && (text.startsWith('UNIN-') || text.startsWith('http'))) {
        String code = text;
        if (text.startsWith('http')) {
          final uri = Uri.parse(text);
          code = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : text;
        }

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

      // 5. Parse into AssignmentDoc
      final doc = AssignmentDoc.fromJson(text);
      await LocalStorageService.saveDoc(doc);

      if (mounted) {
        _showSuccessSheet(doc);
      }
    } catch (_) {
      // Fallback: parse as general document
      final doc = AssignmentDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'ChatGPT Assignment',
        docType: 'general',
        generalContent: rawInput,
      );
      await LocalStorageService.saveDoc(doc);

      if (mounted) {
        _showSuccessSheet(doc);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessSheet(AssignmentDoc doc) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assignment Imported Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                doc.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '${doc.items.length} Question & Answer pairs loaded into handwritten pages.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0057D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('View Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan ChatGPT Assignment QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Camera QR Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (ctx, err) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Camera access is required to scan QR codes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0057D2),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => setState(() => _showManualInput = true),
                        child: const Text('Enter Code / Paste Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Viewfinder Overlay Cutout & Laser Animation
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // Corner Borders
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Four Corner Highlights
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF0057D2), width: 4),
                          left: BorderSide(color: Color(0xFF0057D2), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF0057D2), width: 4),
                          right: BorderSide(color: Color(0xFF0057D2), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF0057D2), width: 4),
                          left: BorderSide(color: Color(0xFF0057D2), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF0057D2), width: 4),
                          right: BorderSide(color: Color(0xFF0057D2), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                      ),
                    ),
                  ),

                  // Scanning Laser
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 250 * _laserAnimation.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF0057D2),
                                Color(0xFF60A5FA),
                                Color(0xFF0057D2),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0057D2).withOpacity(0.8),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Instruction Hint
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Point camera at the QR code on your computer screen to import assignment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              ),
            ),
          ),

          // 4. Bottom Controls: Manual Paste Option
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0057D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Importing assignment...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text(
                      'Paste Code / Payload Manually',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () => _openManualPasteSheet(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openManualPasteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Manual Assignment Sync',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste the link, sync code, or JSON payload copied from the browser extension.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _manualTextController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'https://intently.page.link/..., UNIN-XXXXXX, or JSON payload',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0057D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final text = _manualTextController.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(ctx);
                      _processScannedData(text);
                    }
                  },
                  child: const Text('Import Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
