import 'package:flutter/material.dart';

class EstadoSelect extends StatefulWidget {
  final String value;
  final Function(String) onChanged;
  
  const EstadoSelect({super.key, required this.value, required this.onChanged});

  @override
  _EstadoSelectState createState() => _EstadoSelectState();
}class _EstadoSelectState extends State<EstadoSelect> {
  bool isExpanded = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final List<String> estados = ["Pendiente", "Pagada"];
  
  String? selectedEstado; // ← variable para guardar selección

  void toggleOverlay() {
    if (isExpanded) {
      _overlayEntry?.remove();
      isExpanded = false;
    } else {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      isExpanded = true;
    }
    setState(() {});
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: estados.map((estado) {
              return ListTile(
                title: Text(estado),
                onTap: () {
                  setState(() {
                    selectedEstado = estado; // ← guardar selección
                  });
                  widget.onChanged(estado);
                  toggleOverlay();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        readOnly: true,
        onTap: toggleOverlay,
        decoration: InputDecoration(
          hintText: selectedEstado ?? 'Seleccionar Estado', // ← texto por defecto
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.assignment, color: Colors.blueAccent),
          suffixIcon: IconButton(
            icon: Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.blueAccent,
            ),
            onPressed: toggleOverlay,
          ),
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
