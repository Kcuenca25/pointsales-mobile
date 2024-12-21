import 'package:flutter/material.dart';

class CustonSearch extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onTextChanged;

  const CustonSearch({
    Key? key,
    required this.controller,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(16.0),
      child: TextFormField(
        controller: controller,
        onChanged: onTextChanged,
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }
}
