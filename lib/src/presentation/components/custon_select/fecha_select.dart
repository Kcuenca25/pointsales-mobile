import 'package:flutter/material.dart';

class FechaOrdenSelect extends StatefulWidget {
  final String initialValue;
  final Function(String) onOrdenSelected;

  const FechaOrdenSelect({
    super.key,
    required this.initialValue,
    required this.onOrdenSelected,
  });

  @override
  _FechaOrdenSelectState createState() => _FechaOrdenSelectState();
}class _FechaOrdenSelectState extends State<FechaOrdenSelect> {
  bool isExpanded = false;
  String? selectedOrden; // ← ahora puede ser null inicialmente

  final List<Map<String, dynamic>> ordenes = [
    {"value": "ASC", "label": "Más antiguas primero", "icon": Icons.arrow_upward},
    {"value": "DESC", "label": "Más recientes primero", "icon": Icons.arrow_downward},
  ];

  @override
  void initState() {
    super.initState();
    // Inicialmente null para mostrar "Ordenar por"
    selectedOrden = null;
  }

  void toggleList() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determinar texto a mostrar
    final displayLabel = selectedOrden == null
        ? 'Ordenar por'
        : ordenes.firstWhere((o) => o["value"] == selectedOrden)["label"];

    return Column(
      children: [
        Material(
          elevation: 2.0,
          borderRadius: BorderRadius.circular(16.0),
          child: TextFormField(
            readOnly: true,
            onTap: toggleList,
            decoration: InputDecoration(
              hintText: displayLabel,
              prefixIcon: const Icon(Icons.date_range, color: Colors.blueAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.blueAccent,
                ),
                onPressed: toggleList,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: ordenes
                  .map(
                    (o) => ListTile(
                      leading: Icon(o["icon"], color: Colors.blueAccent),
                      title: Text(o["label"]),
                      onTap: () {
                        setState(() {
                          selectedOrden = o["value"];
                          isExpanded = false;
                        });
                        widget.onOrdenSelected(o["value"]);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
