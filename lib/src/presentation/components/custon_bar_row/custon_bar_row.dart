import 'package:flutter/material.dart';

class CustomBarRow extends StatelessWidget {
  final String title;
  final VoidCallback? onBackButtonPressed;
  final Color backgroundColor;
  final Color textColor;

  const CustomBarRow({
    super.key,
    required this.title,
    this.onBackButtonPressed,
    this.backgroundColor = const Color.fromARGB(255, 31, 182, 56),
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackButtonPressed ?? () {
            Navigator.pop(context);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(backgroundColor),
          ),
          padding: EdgeInsets.zero,
          iconSize: 20.0,
          alignment: Alignment.center,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
