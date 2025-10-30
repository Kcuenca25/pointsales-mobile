import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';

class EmptyScreenContent extends StatefulWidget {
  final User usuario;
  const EmptyScreenContent({super.key, required this.usuario});

  @override
  _EmptyScreenContentState createState() => _EmptyScreenContentState();
}

class _EmptyScreenContentState extends State<EmptyScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Título opcional
        const Center(
          child: Text(
            'Pantalla vacía',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Aquí podrías agregar algún placeholder o mensaje
        Expanded(
          child: Center(
            child: Text(
              'No hay contenido disponible aún',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
