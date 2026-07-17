import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';

class articuloSelectSimple extends StatefulWidget {
  final Function(String)? onArticuloChanged;
  final Function(ArticuloItem)? onArticuloSeleccionado;

  const articuloSelectSimple({
    super.key,
    this.onArticuloChanged,
    this.onArticuloSeleccionado,
  });

  @override
  State<articuloSelectSimple> createState() => _ArticuloSelectSimpleState();
}

class _ArticuloSelectSimpleState extends State<articuloSelectSimple> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Todos";

  // Datos de ejemplo locales
  final List<ArticuloItem> articulosEjemplo = [
    ArticuloItem(
      id: 1,
      nombre: "Camiseta Básica Negra",
      categoria: "Ropa",
      subcategoria: "Camisetas",
      precio: 19.99,
      descripcion: "Camiseta de algodón 100%",
      imagen: "camiseta_negra",
      rating: 4.5,
      reviews: 120,
    ),
    ArticuloItem(
      id: 2,
      nombre: "Jeans Slim Fit",
      categoria: "Ropa",
      subcategoria: "Pantalones",
      precio: 49.99,
      descripcion: "Jeans de corte slim",
      imagen: "jeans_slim",
      rating: 4.2,
      reviews: 85,
    ),
    ArticuloItem(
      id: 3,
      nombre: "Zapatos Deportivos",
      categoria: "Calzado",
      subcategoria: "Deportivos",
      precio: 79.99,
      descripcion: "Zapatos para running",
      imagen: "zapatos_deportivos",
      rating: 4.7,
      reviews: 200,
    ),
    ArticuloItem(
      id: 4,
      nombre: "iPhone 14 Pro",
      categoria: "Electrónica",
      subcategoria: "Teléfonos",
      precio: 999.99,
      descripcion: "Último modelo iPhone",
      imagen: "iphone_14",
      rating: 4.8,
      reviews: 300,
    ),
    ArticuloItem(
      id: 5,
      nombre: "Laptop Gaming",
      categoria: "Electrónica",
      subcategoria: "Laptops",
      precio: 1299.99,
      descripcion: "Laptop para gaming",
      imagen: "laptop_gaming",
      rating: 4.6,
      reviews: 150,
    ),
    ArticuloItem(
      id: 6,
      nombre: "Audífonos Bluetooth",
      categoria: "Electrónica",
      subcategoria: "Audio",
      precio: 89.99,
      descripcion: "Audífonos inalámbricos",
      imagen: "audifonos_bluetooth",
      rating: 4.3,
      reviews: 95,
    ),
    ArticuloItem(
      id: 7,
      nombre: "Mochila para Laptop",
      categoria: "Accesorios",
      subcategoria: "Bolsos",
      precio: 39.99,
      descripcion: "Mochila resistente para laptop",
      imagen: "mochila_laptop",
      rating: 4.4,
      reviews: 80,
    ),
    ArticuloItem(
      id: 8,
      nombre: "Reloj Inteligente",
      categoria: "Electrónica",
      subcategoria: "Wearables",
      precio: 199.99,
      descripcion: "Reloj smart con GPS",
      imagen: "reloj_inteligente",
      rating: 4.1,
      reviews: 110,
    ),
    ArticuloItem(
      id: 9,
      nombre: "Tablet Android",
      categoria: "Electrónica",
      subcategoria: "Tablets",
      precio: 299.99,
      descripcion: "Tablet de 10 pulgadas",
      imagen: "tablet_android",
      rating: 4.0,
      reviews: 75,
    ),
    ArticuloItem(
      id: 10,
      nombre: "Cámara Digital",
      categoria: "Electrónica",
      subcategoria: "Cámaras",
      precio: 449.99,
      descripcion: "Cámara DSLR profesional",
      imagen: "camara_digital",
      rating: 4.9,
      reviews: 180,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ["Todos"] +
        articulosEjemplo.map((e) => e.categoria).toSet().toList();

    final filteredArticulos = articulosEjemplo.where((articulo) {
      final matchesSearch = articulo.nombre
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      final matchesCategory =
          _selectedCategory == "Todos" || articulo.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // 🔍 Barra de búsqueda
        Material(
          elevation: 2.0,
          borderRadius: BorderRadius.circular(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar artículo...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            onChanged: (value) {
              if (widget.onArticuloChanged != null) {
                widget.onArticuloChanged!(value);
              }
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 16),

        // 📂 Filtro de categorías
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((category) {
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : "Todos";
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // 📋 Lista simplificada (solo nombre + categoría)
        Expanded(
          child: ListView.builder(
            itemCount: filteredArticulos.length,
            itemBuilder: (context, index) {
              final articulo = filteredArticulos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    articulo.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text("Categoría: ${articulo.categoria}"),
                  trailing: Text(
                    "\$${articulo.precio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  onTap: () {
                    if (widget.onArticuloSeleccionado != null) {
                      widget.onArticuloSeleccionado!(articulo);
                    }
                    if (widget.onArticuloChanged != null) {
                      widget.onArticuloChanged!(articulo.nombre);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
