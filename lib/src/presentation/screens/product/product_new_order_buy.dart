import 'dart:async';

import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_select/user_select.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(const ProductNewOrderBuy());

class ProductNewOrderBuy extends StatefulWidget {
  const ProductNewOrderBuy({super.key});

  @override
  State<ProductNewOrderBuy> createState() => _ProductNewOrderBuyState();
}

class _ProductNewOrderBuyState extends State<ProductNewOrderBuy> with WidgetsBindingObserver {
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
      body: SingleChildScrollView( // Permite el desplazamiento
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const CustonAppBar(),
            const SizedBox(height: 20),
            CustomBarRow( 
                title: 'Nueva orden de compra',
                onBackButtonPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: Colors.blueAccent, textColor: Colors.black,
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
              height: 300, // Altura fija para el escáner
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
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blueAccent)),
              iconSize: 20.0,
              alignment: Alignment.center,
            ),
            CustomElevatedButton(
              text: 'Añadir producto manual',
              onPressed: () {
                if (selectedUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductList(selectedUser: selectedUser!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, selecciona un usuario')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 2, // Cambia según la posición de esta pantalla
        onItemTapped: (index) {
          // Lógica para navegar a la pantalla correspondiente
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/users');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/products');
          }
          // Agrega más navegación según tus pantallas
        },
      ),
    );
  }
}