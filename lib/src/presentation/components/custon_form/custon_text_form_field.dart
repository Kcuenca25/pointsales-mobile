import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          elevation: 2.0,
          borderRadius: BorderRadius.circular(16.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(prefixIcon, color: Colors.blueAccent),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
              errorStyle: const TextStyle(color: Colors.transparent, height: 0), // Ocultar mensajes de error dentro del campo
            ),
            obscureText: obscureText,
            validator: validator,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            if (validator != null) {
              final error = validator!(controller.text);
              if (error != null) {
                return Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
