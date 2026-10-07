import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';
import 'create_general_document_screen.dart';
import 'create_qa_assignment_screen.dart';

class QrExtensionSyncScreen extends StatefulWidget {
  final String? initialCode;

  const QrExtensionSyncScreen({super.key, this.initialCode});

  @override
  State<QrExtensionSyncScreen> createState() => _QrExtensionSyncScreenState();
}

class _QrExtensionSyncScreenState extends State<QrExtensionSyncScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  final TextEditingController _manualTextController = TextEditingController();

  bool _isProcessing = false;
  bool _isTorchOn = false;

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

    if (widget.initialCode != null && widget.initialCode!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _manualTextController.text = widget.initialCode!.trim();
        _processScannedData(widget.initialCode!.trim());
      });
    }
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
    if (text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      AssignmentDoc? doc;

      final bool isSyncUrlOrCode = text.startsWith('UNIN-') ||
          text.contains('unintently') ||
          text.contains('intently') ||
          text.startsWith('http://') ||
          text.startsWith('https://');

      // 1. Direct JSON check
      if (text.startsWith('{')) {
        try {
          doc = AssignmentDoc.fromJson(text);
        } catch (_) {}
      }

      // 2. Base64 payload check
      if (doc == null && !text.startsWith('{') && text.length > 20 && !text.contains(' ') && !text.startsWith('http')) {
        try {
          final decoded = utf8.decode(base64.decode(text));
          if (decoded.startsWith('{')) {
            doc = AssignmentDoc.fromJson(decoded);
          }
        } catch (_) {}
      }

      // 3. Extract Sync Code (UNIN-XXXXXX)
      String? syncCode;
      if (text.startsWith('UNIN-')) {
        syncCode = text.split('?').first.trim();
      } else if (text.contains('code=')) {
        final uri = Uri.tryParse(text);
        syncCode = uri?.queryParameters['code'];
      } else if (text.contains('/a/') || text.contains('/assignments/')) {
        final uri = Uri.tryParse(text);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          syncCode = uri.pathSegments.last;
        }
      }

      // 4. Fetch from Cloudflare Worker
      if (doc == null && syncCode != null && syncCode.isNotEmpty) {
        final candidateUrls = [
          'https://unintently-backend.brksmartkraft.workers.dev/assignments/$syncCode',
          'http://10.0.2.2:8787/assignments/$syncCode',
          'http://localhost:8787/assignments/$syncCode',
        ];

        for (final urlStr in candidateUrls) {
          try {
            final res = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 12));
            if (res.statusCode == 200) {
              final body = json.decode(res.body);
              if (body is Map && body.containsKey('assignment')) {
                final aMap = body['assignment'];
                if (aMap is Map) {
                  doc = AssignmentDoc.fromMap(Map<String, dynamic>.from(aMap));
                }
                break;
              }
            }
          } catch (_) {}
        }
      }

      // 5. Firebase Dynamic Link / Firestore fallback
      if (doc == null && (text.contains('.page.link') || text.contains('assignmentId='))) {
        String? assignmentId;
        final parsedUri = Uri.tryParse(text);
        if (parsedUri != null && parsedUri.queryParameters.containsKey('assignmentId')) {
          assignmentId = parsedUri.queryParameters['assignmentId'];
        } else if (text.contains('.page.link')) {
          try {
            final client = http.Client();
            final request = http.Request('GET', Uri.parse(text))..followRedirects = false;
            final response = await client.send(request).timeout(const Duration(seconds: 6));
            final location = response.headers['location'];
            if (location != null && location.isNotEmpty) {
              final targetUri = Uri.tryParse(location);
              assignmentId = targetUri?.queryParameters['assignmentId'];
            }
          } catch (_) {}
        }

        if (assignmentId != null && assignmentId.isNotEmpty) {
          doc = await _fetchFromFirestore(assignmentId);
        }
      }

      // 6. Raw Firestore assignment ID (e.g. kTRgsgj6Dv5Iqqm7f8SZ)
      if (doc == null && !isSyncUrlOrCode && RegExp(r'^[A-Za-z0-9_-]{16,28}$').hasMatch(text)) {
        doc = await _fetchFromFirestore(text);
      }

      // 7. If this was a sync link/code and fetching failed, DO NOT dump the URL as notes!
      if (doc == null && isSyncUrlOrCode) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                syncCode != null
                    ? 'Could not load assignment $syncCode. Please check your internet connection.'
                    : 'Could not load assignment from link. Please verify internet connection.',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      // 8. Fallback ONLY for plain text notes typed or pasted by the user
      doc ??= AssignmentDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Imported Notes',
        docType: 'general',
        heading: 'Notes',
        generalContent: rawInput,
        fontFamily: 'intentlyR1',
        fontSize: 17.0,
        lineSpacing: 1.6,
        paperAsset: 'assets/images/ruled1.jpg',
      );

      // Harmonize general content and QA items
      if (doc.generalContent.trim().isEmpty && doc.items.isNotEmpty) {
        doc.generalContent = doc.items.map((i) => 'Q: ${i.question}\n\nA: ${i.answer}').join('\n\n');
      } else if (doc.items.isEmpty && doc.generalContent.trim().isNotEmpty) {
        doc.items = [QAItem(question: doc.heading.isNotEmpty ? doc.heading : doc.title, answer: doc.generalContent)];
      }

      await LocalStorageService.saveDoc(doc);

      if (mounted) {
        HapticFeedback.lightImpact();
        // Open the editor directly for instant flow
        if (doc.docType == 'general') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGeneralDocumentScreen(initialDoc: doc),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQAAssignmentScreen(initialDoc: doc),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing scanned code: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<AssignmentDoc?> _fetchFromFirestore(String assignmentId) async {
    try {
      final fsUrl =
          'https://firestore.googleapis.com/v1/projects/intently-502ef/databases/(default)/documents/chatGPTAssignments/$assignmentId';
      final fsRes = await http.get(Uri.parse(fsUrl)).timeout(const Duration(seconds: 5));
      if (fsRes.statusCode == 200) {
        final fsData = json.decode(fsRes.body);
        final fields = fsData['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final title = fields['name']?['stringValue'] ?? 'ChatGPT Assignment';
          final isGeneral = fields['isGeneral']?['booleanValue'] ?? false;

          final qaModel = fields['questionAnswersModel']?['mapValue']?['fields'];
          final heading = qaModel?['headingText']?['stringValue'] ?? '';
          final rawQuestions = qaModel?['questions']?['arrayValue']?['values'] as List? ?? [];

          final List<QAItem> items = [];
          for (var qItem in rawQuestions) {
            if (qItem is Map) {
              final qFields = qItem['mapValue']?['fields'];
              if (qFields != null) {
                final q = qFields['question']?['stringValue'] ?? '';
                final a = qFields['answer']?['stringValue'] ?? '';
                if (q.isNotEmpty || a.isNotEmpty) {
                  items.add(QAItem(question: q, answer: a));
                }
              }
            }
          }

          final generalModel = fields['generalPageModel']?['mapValue']?['fields'];
          String generalText = generalModel?['text']?['stringValue'] ?? '';
          if (generalText.isEmpty && items.isNotEmpty) {
            generalText = items.map((i) => '${i.question}\n\n${i.answer}').join('\n\n');
          }

          return AssignmentDoc(
            id: assignmentId,
            title: title.isNotEmpty ? title : 'ChatGPT Assignment',
            docType: isGeneral ? 'general' : 'qa',
            heading: heading.isNotEmpty ? heading : title,
            items: items,
            generalContent: generalText,
            fontFamily: 'intentlyR1',
            fontSize: 17.0,
            lineSpacing: 1.6,
            paperAsset: 'assets/images/ruled1.jpg',
          );
        }
      }
    } catch (_) {}
    return null;
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
                        onPressed: _openManualPasteSheet,
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
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
                                color: const Color(0xFF0057D2).withValues(alpha: 0.8),
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
                color: Colors.black.withValues(alpha: 0.65),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
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
