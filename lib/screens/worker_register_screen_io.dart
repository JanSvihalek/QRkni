import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/credential_storage.dart';
import '../services/worker_service.dart';
import '../widgets/logo_scan_brackets.dart';

class WorkerRegisterScreen extends StatefulWidget {
  final VoidCallback onRegistered;
  const WorkerRegisterScreen({super.key, required this.onRegistered});

  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final parsed = WorkerService.parseQrData(raw);
    if (parsed == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    await CredentialStorage().pairAsWorkerDevice(
      ownerUserId: parsed.ownerUserId,
      workerName: parsed.workerName,
      pinHash: parsed.pinHash,
    );

    if (mounted) {
      widget.onRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrace zařízení'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Průhledný overlay s otvorem a instrukcí
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const LogoScanBrackets(size: 40, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Naskenujte QR kód\nzaměstnance/brigádníka od zaměstnavatele',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                if (_processing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Požádejte zaměstnavatele, aby v aplikaci otevřel nastavení → Zaměstnanci/Brigádníci a zobrazil váš QR kód.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
