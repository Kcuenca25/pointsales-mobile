import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';

class ArticuloSelect extends StatefulWidget {
  final Function(ArticuloItem)? onArticuloSeleccionado;
  final List<ArticuloItem> articulosSeleccionados; // ✅ Nueva propiedad

  const ArticuloSelect({super.key, this.onArticuloSeleccionado, required this.articulosSeleccionados,});

  @override
  State<ArticuloSelect> createState() => _ArticuloSelectState();
}

class _ArticuloSelectState extends State<ArticuloSelect> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Todos";
  bool _showSearchBar = false;

  // Variables para load more
  final int _itemsPerLoad = 10;
  int _visibleItems = 10;
  bool _isLoadingMore = false;

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
      nombre: "Tablet Android 10''",
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
      nombre: "Cámara Digital DSLR",
      categoria: "Electrónica",
      subcategoria: "Cámaras",
      precio: 449.99,
      descripcion: "Cámara profesional",
      imagen: "camara_digital",
      rating: 4.9,
      reviews: 180,
    ),
    ArticuloItem(
      id: 11,
      nombre: "Smart TV 55'' 4K",
      categoria: "Electrónica",
      subcategoria: "TV",
      precio: 599.99,
      descripcion: "Smart TV Ultra HD",
      imagen: "smart_tv",
      rating: 4.7,
      reviews: 220,
    ),
    ArticuloItem(
      id: 12,
      nombre: "Consola Gaming",
      categoria: "Electrónica",
      subcategoria: "Gaming",
      precio: 499.99,
      descripcion: "Consola de última generación",
      imagen: "consola_gaming",
      rating: 4.8,
      reviews: 190,
    ),
    ArticuloItem(
    id: 13,
    nombre: "Smartwatch Pro",
    categoria: "Electrónica",
    subcategoria: "Wearables",
    precio: 159.99,
    descripcion: "Reloj inteligente con monitor de salud",
    rating: 4.4,
    reviews: 95,
  ),
  ArticuloItem(
    id: 14,
    nombre: "Teclado Mecánico RGB",
    categoria: "Computación",
    subcategoria: "Periféricos",
    precio: 89.99,
    descripcion: "Teclado gaming con iluminación RGB",
    rating: 4.6,
    reviews: 130,
  ),
  ArticuloItem(
    id: 15,
    nombre: "Mouse Inalámbrico",
    categoria: "Computación",
    subcategoria: "Periféricos",
    precio: 45.99,
    descripcion: "Mouse ergonómico inalámbrico",
    rating: 4.3,
    reviews: 88,
  ),
  ArticuloItem(
    id: 16,
    nombre: "Monitor 27'' 4K",
    categoria: "Computación",
    subcategoria: "Monitores",
    precio: 349.99,
    descripcion: "Monitor UHD para gaming y diseño",
    rating: 4.7,
    reviews: 150,
  ),
  ArticuloItem(
    id: 17,
    nombre: "Impresora Multifunción",
    categoria: "Oficina",
    subcategoria: "Impresoras",
    precio: 199.99,
    descripcion: "Impresora láser todo en uno",
    rating: 4.2,
    reviews: 75,
  ),
  ArticuloItem(
    id: 18,
    nombre: "Altavoz Bluetooth",
    categoria: "Audio",
    subcategoria: "Altavoces",
    precio: 79.99,
    descripcion: "Altavoz portátil resistente al agua",
    rating: 4.5,
    reviews: 110,
  ),
  ArticuloItem(
    id: 19,
    nombre: "Auriculares Gaming",
    categoria: "Audio",
    subcategoria: "Auriculares",
    precio: 129.99,
    descripcion: "Auriculares con sonido surround 7.1",
    rating: 4.6,
    reviews: 140,
  ),
  ArticuloItem(
    id: 20,
    nombre: "Disco Duro Externo 1TB",
    categoria: "Computación",
    subcategoria: "Almacenamiento",
    precio: 69.99,
    descripcion: "Disco duro portátil USB 3.0",
    rating: 4.4,
    reviews: 90,
  ),
  ArticuloItem(
    id: 21,
    nombre: "SSD 500GB NVMe",
    categoria: "Computación",
    subcategoria: "Almacenamiento",
    precio: 59.99,
    descripcion: "Disco sólido de alta velocidad",
    rating: 4.8,
    reviews: 120,
  ),
  ArticuloItem(
    id: 22,
    nombre: "Router WiFi 6",
    categoria: "Redes",
    subcategoria: "Routers",
    precio: 129.99,
    descripcion: "Router de última generación",
    rating: 4.3,
    reviews: 85,
  ),
  ArticuloItem(
    id: 23,
    nombre: "Cámara Web 4K",
    categoria: "Computación",
    subcategoria: "Accesorios",
    precio: 89.99,
    descripcion: "Webcam para streaming y videollamadas",
    rating: 4.5,
    reviews: 95,
  ),
  ArticuloItem(
    id: 24,
    nombre: "Micrófono USB",
    categoria: "Audio",
    subcategoria: "Micrófonos",
    precio: 79.99,
    descripcion: "Micrófono para podcast y streaming",
    rating: 4.4,
    reviews: 80,
  ),
  ArticuloItem(
    id: 25,
    nombre: "Silla Gaming Ergonómica",
    categoria: "Gaming",
    subcategoria: "Mobiliario",
    precio: 249.99,
    descripcion: "Silla ergonómica para gamers",
    rating: 4.6,
    reviews: 110,
  ),
  ArticuloItem(
    id: 26,
    nombre: "Escritorio Gaming",
    categoria: "Gaming",
    subcategoria: "Mobiliario",
    precio: 199.99,
    descripcion: "Escritorio con soporte para PC",
    rating: 4.5,
    reviews: 75,
  ),
  ArticuloItem(
    id: 27,
    nombre: "Kit de Herramientas",
    categoria: "Hogar",
    subcategoria: "Herramientas",
    precio: 49.99,
    descripcion: "Set completo de herramientas",
    rating: 4.7,
    reviews: 130,
  ),
  ArticuloItem(
    id: 28,
    nombre: "Aspiradora Robot",
    categoria: "Hogar",
    subcategoria: "Limpieza",
    precio: 299.99,
    descripcion: "Robot aspirador inteligente",
    rating: 4.4,
    reviews: 95,
  ),
  ArticuloItem(
    id: 29,
    nombre: "Cafetera Automática",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 89.99,
    descripcion: "Cafetera programable",
    rating: 4.6,
    reviews: 120,
  ),
  ArticuloItem(
    id: 30,
    nombre: "Batidora Profesional",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 129.99,
    descripcion: "Batidora de alta potencia",
    rating: 4.5,
    reviews: 85,
  ),
  ArticuloItem(
    id: 31,
    nombre: "Licuadora de Vaso",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 59.99,
    descripcion: "Licuadora para smoothies",
    rating: 4.3,
    reviews: 70,
  ),
  ArticuloItem(
    id: 32,
    nombre: "Horno Tostador",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 79.99,
    descripcion: "Horno tostador de convección",
    rating: 4.4,
    reviews: 65,
  ),
  ArticuloItem(
    id: 33,
    nombre: "Freidora de Aire",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 99.99,
    descripcion: "Freidora sin aceite",
    rating: 4.7,
    reviews: 150,
  ),
  ArticuloItem(
    id: 34,
    nombre: "Microondas Digital",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 129.99,
    descripcion: "Microondas con funciones digitales",
    rating: 4.5,
    reviews: 90,
  ),
  ArticuloItem(
    id: 35,
    nombre: "Ventilador de Torre",
    categoria: "Hogar",
    subcategoria: "Climatización",
    precio: 69.99,
    descripcion: "Ventilador silencioso",
    rating: 4.2,
    reviews: 60,
  ),
  ArticuloItem(
    id: 36,
    nombre: "Purificador de Aire",
    categoria: "Hogar",
    subcategoria: "Climatización",
    precio: 159.99,
    descripcion: "Purificador con filtro HEPA",
    rating: 4.6,
    reviews: 85,
  ),
  ArticuloItem(
    id: 37,
    nombre: "Humidificador Ultrasónico",
    categoria: "Hogar",
    subcategoria: "Climatización",
    precio: 49.99,
    descripcion: "Humidificador para habitaciones",
    rating: 4.3,
    reviews: 55,
  ),
  ArticuloItem(
    id: 38,
    nombre: "Set de Sartenes Antiadherentes",
    categoria: "Hogar",
    subcategoria: "Cocina",
    precio: 89.99,
    descripcion: "Set de 5 sartenes premium",
    rating: 4.7,
    reviews: 110,
  ),
  ArticuloItem(
    id: 39,
    nombre: "Olla Arrocera",
    categoria: "Hogar",
    subcategoria: "Electrodomésticos",
    precio: 59.99,
    descripcion: "Olla automática para arroz",
    rating: 4.4,
    reviews: 75,
  ),
  ArticuloItem(
    id: 40,
    nombre: "Báscula Digital",
    categoria: "Hogar",
    subcategoria: "Cocina",
    precio: 29.99,
    descripcion: "Báscula de cocina precisa",
    rating: 4.6,
    reviews: 95,
  ),
  ArticuloItem(
    id: 41,
    nombre: "Juego de Cuchillos",
    categoria: "Hogar",
    subcategoria: "Cocina",
    precio: 79.99,
    descripcion: "Set de cuchillos profesionales",
    rating: 4.8,
    reviews: 130,
  ),
  ArticuloItem(
    id: 42,
    nombre: "Tabla de Cortar",
    categoria: "Hogar",
    subcategoria: "Cocina",
    precio: 24.99,
    descripcion: "Tabla de bambú ecológica",
    rating: 4.5,
    reviews: 65,
  ),
];
  

  List<ArticuloItem> get filteredArticulos {
    return articulosEjemplo.where((articulo) {
      final matchesSearch = articulo.nombre
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      final matchesCategory =
          _selectedCategory == "Todos" || articulo.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<ArticuloItem> get visibleArticulos {
    return filteredArticulos.take(_visibleItems).toList();
  }

  bool get canLoadMore => _visibleItems < filteredArticulos.length;

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !canLoadMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simular carga de más datos
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _visibleItems += _itemsPerLoad;
      _isLoadingMore = false;
    });
  }

  void _resetPagination() {
    setState(() {
      _visibleItems = _itemsPerLoad;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ["Todos"] +
        articulosEjemplo.map((e) => e.categoria).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Buscar artículo...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                onChanged: (_) {
                  setState(() {
                    _resetPagination();
                  });
                },
              )
            : const Text(
                "Seleccionar artículo",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
                _resetPagination();
              });
            },
            itemBuilder: (context) {
              return categories.map((c) {
                return PopupMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: c == _selectedCategory ? Colors.blue : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Text(c),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _resetPagination();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de categoría activo
          if (_selectedCategory != "Todos")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    "Filtro: $_selectedCategory",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = "Todos";
                        _resetPagination();
                      });
                    },
                    child: const Text(
                      "Limpiar",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "${filteredArticulos.length} artículos encontrados",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollEndNotification &&
                    scrollNotification.metrics.pixels ==
                        scrollNotification.metrics.maxScrollExtent &&
                    canLoadMore) {
                  _loadMoreItems();
                }
                return false;
              },
              child: ListView.separated(
                itemCount: visibleArticulos.length + (canLoadMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  if (index == visibleArticulos.length) {
                    return _buildLoadMoreButton();
                  }
                  
                  final articulo = visibleArticulos[index];
                  return _buildArticuloItem(articulo);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticuloItem(ArticuloItem articulo) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_bag, color: Colors.grey),
      ),
      title: Text(
        articulo.nombre,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${articulo.categoria} • ${articulo.subcategoria}",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 2),
              Text(
                articulo.rating.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Text(
                "(${articulo.reviews} reviews)",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "\$${articulo.precio.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Disponible",
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onTap: () {
        if (widget.onArticuloSeleccionado != null) {
          widget.onArticuloSeleccionado!(articulo);
          Navigator.pop(context); // Cerrar la pantalla después de seleccionar
        }
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(strokeWidth: 2)
            : OutlinedButton(
                onPressed: _loadMoreItems,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Cargar más (${filteredArticulos.length - _visibleItems} restantes)",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}