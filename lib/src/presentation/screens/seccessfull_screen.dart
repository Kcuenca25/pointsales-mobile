import 'package:flutter/material.dart';

class SuccessfullScreen extends StatelessWidget {
  final List<Map<String, dynamic>> purchaseHistory;

  const SuccessfullScreen({super.key, required this.purchaseHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/success.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, 
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0), 
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/purchase_history',
                    arguments: purchaseHistory,
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, 
                  minimumSize: const Size(double.infinity, 65), 
                ),
                child: const Text(
                  'Ir a Historial de Compras',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
