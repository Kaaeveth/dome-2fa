import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/view/util.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<StatefulWidget> createState() => QrScannerPageState();
}

class QrScannerPageState extends State<QrScannerPage> {

  static const int scannerTimeout = 1000; //ms
  final MobileScannerController scannerController = MobileScannerController(
    detectionTimeoutMs: scannerTimeout
  );
  static const Duration msgDisplayDuration = Duration(milliseconds: scannerTimeout - 100);

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            MobileScanner(
              onDetect: _onDetect,
              controller: scannerController,
              fit: BoxFit.cover,
            )
          ],
        ),
      )
    );
  }

  void _onDetect(BarcodeCapture? barcode) {
    var content = barcode?.barcodes.first.rawValue;
    if(content == null) {
      return;
    }

    try{
      var acc = Account.fromUrl(content);
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop(acc);
      });
    } catch (e) {
      showMessageSnackbar(
        e.toString(),
        context,
        duration: msgDisplayDuration
      );
    }
  }
}