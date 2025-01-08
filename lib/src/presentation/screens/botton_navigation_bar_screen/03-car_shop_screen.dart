import 'dart:async';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_select/user_select.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';

class CarShopScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(User) onProductListNavigate;

  const CarShopScreen({super.key, this.selectedIndex = 2, required this.onProductListNavigate});

  @override
  State<CarShopScreen> createState() => _CarShopScreenState();
}

class _CarShopScreenState extends State<CarShopScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  StreamSubscription<Object?>? _subscription;
  String qrCode = '';
  User? selectedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = controller.barcodes.listen(_handleBarcode);
    controller.start();
  }

  void _handleBarcode(BarcodeCapture capture) {
    final Barcode barcode = capture.barcodes.first;
    final String code = barcode.rawValue ?? '---';
    setState(() {
      qrCode = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código QR detectado: $qrCode')),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleBarcode);
        controller.start();
        break;
      case AppLifecycleState.inactive:
        _subscription?.cancel();
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    await controller.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const CustonAppBar(),
            const SizedBox(height: 20),
            CustomBarRow(
              title: 'Escanear productos',
              onBackButtonPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: Colors.blueAccent,
              textColor: Colors.black,
            ),
            const SizedBox(height: 10),
            UserSelect(
              onUserSelected: (user) {
                setState(() {
                  selectedUser = user;
                });
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: MobileScanner(
                controller: controller,
                fit: BoxFit.cover,
                onDetect: (barcode) {
                  if (barcode.barcodes.isNotEmpty) {
                    _handleBarcode(barcode);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alinee el código de barras o QR dentro del',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Text(
              'marco para escanear automáticamente',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            CustomElevatedButton(
              text: 'Añadir producto manual',
              onPressed: () {
                if (selectedUser != null) {
                  widget.onProductListNavigate(selectedUser!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, selecciona un usuario')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: widget.selectedIndex,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home_screen');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/client_screen');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/car_shop_screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/purchase_history');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile_screen');
              break;
          }
        },
      ),
    );
  }
}
