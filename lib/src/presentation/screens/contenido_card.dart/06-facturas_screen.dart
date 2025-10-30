import 'package:flutter/material.dart';

class FacturaScreen extends StatelessWidget {
  const FacturaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factura')),
      body: const Center(
        child: Text('Pantalla de Factura'),
      ),
    );
  }
}
