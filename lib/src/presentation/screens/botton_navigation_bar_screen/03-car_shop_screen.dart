// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:ecomerce_app/src/domain/models/products_model.dart';
// import 'package:ecomerce_app/src/domain/models/users_model.dart';
// import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
// import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
// import 'package:ecomerce_app/src/presentation/components/custon_select/user_select.dart';

// class CarShopScreen extends StatefulWidget {
//   final int selectedIndex;
//   final Function(User) onProductListNavigate;

//   const CarShopScreen({
//     super.key,
//     this.selectedIndex = 2,
//     required this.onProductListNavigate,
//   });

//   @override
//   State<CarShopScreen> createState() => _CarShopScreenState();
// }

// class _CarShopScreenState extends State<CarShopScreen> with WidgetsBindingObserver {
// final MobileScannerController controller = MobileScannerController(
//   formats: [
//     BarcodeFormat.qrCode,
//     BarcodeFormat.code128,
//     BarcodeFormat.ean13,
//     BarcodeFormat.upcA,
//     // Puedes agregar más según necesites
//   ],
//     facing: CameraFacing.back, 
//   );  

//   StreamSubscription<Object?>? _subscription;
//   User? selectedUser;
//   Product? scannedProduct;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _subscription = controller.barcodes.listen(_handleBarcode);
//     controller.start();
//   }

// void _handleBarcode(BarcodeCapture capture) {
//   if (capture.barcodes.isEmpty) return;

//   final Barcode barcode = capture.barcodes.first;
//   final String? code = barcode.rawValue;
  
//   if (code == null || code.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Código no reconocido o vacío')),
//     );
//     return;
//   }

//   debugPrint('Código escaneado: $code, Tipo: ${barcode.format}');

//   try {
//     switch (barcode.format) {
//       case BarcodeFormat.qrCode:
//         _processQRCode(code);
//         break;
//       case BarcodeFormat.ean13:
//       case BarcodeFormat.upcA:
//         _processNumericBarcode(code, barcode.format);
//         break;
//       case BarcodeFormat.code128:
//         _processCode128(code);
//         break;
//       default:
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Formato no soportado: ${barcode.format}')),
//         );
//     }
//   } catch (e) {
//     debugPrint('Error procesando código: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: ${e.toString()}')),
//     );
//   }
// }

// void _processQRCode(String code) {
//     final decodedData = code.trim();
    
//     if (!decodedData.startsWith('{') || !decodedData.endsWith('}')) {
//       throw FormatException('El código QR no contiene formato JSON válido');
//     }

//     final product = Product.fromJson(decodedData);
    
//     if (product.title.isEmpty || product.price == 0.0) {
//       throw Exception('Producto QR inválido: faltan datos esenciales');
//     }
    
//     setState(() {
//       scannedProduct = product;
//     });
//   }

// void _processNumericBarcode(String code, BarcodeFormat format) {
//   // Validar longitud para EAN-13 (13 dígitos) y UPC-A (12 dígitos)
//   if ((format == BarcodeFormat.ean13 && code.length != 13) ||
//       (format == BarcodeFormat.upcA && code.length != 12)) {
//     throw FormatException('Longitud incorrecta para ${format.toString()}');
//   }

//   // Verificar que solo contiene dígitos
//   if (!RegExp(r'^[0-9]+$').hasMatch(code)) {
//     throw FormatException('El código debe contener solo números');
//   }

//   setState(() {
//     scannedProduct = Product(
//       id: int.tryParse(code.substring(0, 8)) ?? 0, // Usar parte del código como ID
//       title: "Producto ${format.toString()} $code",
//       price: _generatePriceFromBarcode(code), // Precio basado en el código
//       description: "Escaneado con ${format.toString()}",
//       category: "Generico",
//       barcode: code,
//       ratingRate: null,
//       isSelected: false,
//       quantity: 1,
//     );
//   });
// }

// void _processCode128(String code) {
//   // Intenta primero parsear como JSON
//   try {
//     final trimmedCode = code.trim();
//     if (trimmedCode.startsWith('{') && trimmedCode.endsWith('}')) {
//       final product = Product.fromJson(trimmedCode);
//       setState(() {
//         scannedProduct = product;
//       });
//       return;
//     }
//   } catch (e) {
//     debugPrint('No es JSON válido, continuando como texto simple');
//   }

//   // Si no es JSON, crear producto genérico
//   setState(() {
//     scannedProduct = Product(
//       id: _generateIdFromCode128(code),
//       title: "Producto Code128 $code",
//       price: 0.0,
//       description: "Escaneado con Code128",
//       category: "Generico",
//       barcode: code,
//       ratingRate: null,
//       isSelected: false,
//       quantity: 1,
//     );
//   });
// }

// // Funciones auxiliares
// double _generatePriceFromBarcode(String code) {
//   // Genera un precio basado en los últimos 4 dígitos del código
//   final lastDigits = int.tryParse(code.substring(code.length - 4)) ?? 1000;
//   return (lastDigits % 1000) / 100.0; // Precio entre 0.00 y 9.99
// }

// int _generateIdFromCode128(String code) {
//   // Genera un ID basado en el hash del código
//   return code.hashCode.abs();
// }
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!controller.value.hasCameraPermission) return;

//     switch (state) {
//       case AppLifecycleState.resumed:
//         _subscription = controller.barcodes.listen(_handleBarcode);
//         controller.start();
//         break;
//       case AppLifecycleState.inactive:
//         _subscription?.cancel();
//         controller.stop();
//         break;
//       default:
//         break;
//     }
//   }

//   @override
//   Future<void> dispose() async {
//     WidgetsBinding.instance.removeObserver(this);
//     _subscription?.cancel();
//     _subscription = null;
//     await controller.dispose();
//     super.dispose();
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(18.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),
//             CustomBarRow(
//               title: 'Escanear productos',
//               onBackButtonPressed: () => Navigator.pop(context),
//               backgroundColor: Colors.blueAccent,
//               textColor: Colors.black,
//             ),
//             const SizedBox(height: 10),
//             UserSelect(
//               onUserSelected: (user) {
//                 setState(() {
//                   selectedUser = user;
//                 });
//               },
//             ),
//             const SizedBox(height: 10),
//             SizedBox(
//               height: 300,
//               child: MobileScanner(
//                 controller: controller,
//                 fit: BoxFit.cover,
//                 onDetect: (barcode) {
//                   if (barcode.barcodes.isNotEmpty) {
//                     _handleBarcode(barcode);
//                   }
//                 },
//                 errorBuilder: (context, error, child) {
//                   return Text('Error de cámara: ${error.toString()}');
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Center(
//               child: Column(
//                 children: [
//                   Text(
//                     'Alinee el código de barras o QR dentro del',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                   Text(
//                     'marco para escanear automáticamente',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             CustomElevatedButton(
//               text: 'Añadir producto manual',
//               onPressed: () {
//                 if (selectedUser != null) {
//                   widget.onProductListNavigate(selectedUser!);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Por favor, selecciona un usuario')),
//                   );
//                 }
//               },
//             ),
//             const SizedBox(height: 20),
//             if (scannedProduct != null) ...[
//               const Text(
//                 'Producto escaneado:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         scannedProduct!.title,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No. ${scannedProduct!.id}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         scannedProduct!.category,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         scannedProduct!.description,
//                         style: const TextStyle(color: Colors.grey),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         '\$${scannedProduct!.price.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blueAccent,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: IconButton(
//                                   icon: const Icon(Icons.remove, color: Colors.white),
//                                   onPressed: () {
//                                     if (scannedProduct!.quantity > 1) {
//                                       setState(() {
//                                         scannedProduct!.quantity--;
//                                       });
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 scannedProduct!.quantity.toString(),
//                                 style: const TextStyle(fontSize: 18),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 decoration: const BoxDecoration(
//                                   color: Colors.blueAccent,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: IconButton(
//                                   icon: const Icon(Icons.add, color: Colors.white),
//                                   onPressed: () {
//                                     setState(() {
//                                       scannedProduct!.quantity++;
//                                     });
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                           ElevatedButton(
//                             onPressed: () {
//                               // Lógica para añadir el producto escaneado al carrito
//                             },
//                             child: const Text('Añadir al carrito'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),

   
//     );
//   }
// }
