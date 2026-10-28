import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/visitor_api_service.dart';
import 'visitor_details_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final VisitorApiService _apiService = VisitorApiService();

  bool _processing = false;
  bool _scannerDisposed = false;
  String? _errorMessage;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_processing || !mounted) return;

    String? visitorId;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        visitorId = value;
        break;
      }
    }

    if (visitorId == null) {
      _showError('Invalid QR code. Please scan a visitor QR code.');
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    await _controller.stop();

    try {
      // The QR code contains the server-generated visitor ID.
      final visitor = await _apiService.getVisitor(visitorId);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitorDetailsScreen(visitor: visitor),
        ),
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
        _errorMessage = null;
      });

      await _controller.start();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _errorMessage =
            'Visitor not found, or the API is unavailable. Try again.';
      });

      await _controller.start();
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() => _errorMessage = message);
  }

  @override
  void dispose() {
    _scannerDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Visitor QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle camera',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            tooltip: 'Toggle flashlight',
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.no_photography_outlined, size: 56),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to access the camera.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check camera permission in your device settings '
                              'and try again.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () async {
                                await _controller.start();
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Looking up visitor...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 32),
                const SizedBox(height: 8),
                Text(
                  _processing
                      ? 'Please wait while we retrieve the visitor.'
                      : 'Align the visitor QR code inside the square.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      setState(() => _errorMessage = null);
                      await _controller.start();
                    },
                    child: const Text('Scan Again'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
