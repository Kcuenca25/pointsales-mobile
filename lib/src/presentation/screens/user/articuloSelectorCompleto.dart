import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';



class ArticuloSelectorScreen extends StatefulWidget {
  final Function(ArticuloItem, int) onArticuloAgregado; 
  final Function(ArticuloItem) onArticuloEliminado;
  final List<ArticuloItem> articulosSeleccionadosIniciales;

  const ArticuloSelectorScreen({
    super.key, 
    required this.onArticuloAgregado,
    required this.onArticuloEliminado,
    required this.articulosSeleccionadosIniciales,
  });

  @override
  State<ArticuloSelectorScreen> createState() => _ArticuloSelectorScreenState();
}

class _ArticuloSelectorScreenState extends State<ArticuloSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, int> _cantidadesAgregadas = {};

  // Variables para productos Odoo
  late Future<List<Product>> _futureProducts;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Variables para load more
  final int _itemsPerLoad = 10;
  int _visibleItems = 10;
  bool _isLoadingMore = false;

  // Controlador para mostrar/ocultar búsqueda
  bool _mostrarBusqueda = false;

  // Variables para filtros
  String _categoriaSeleccionada = 'Todas las categorías';
  final Map<int, GlobalKey> _dismissibleKeys = {};

  @override
  void initState() {
    super.initState();
    
    // ✅ CARGAR PRODUCTOS DESDE ODDO
    _futureProducts = _loadProductsFromOdoo();
    
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });

    // ✅ INICIALIZAR CON PRODUCTOS SELECCIONADOS
    for (var articulo in widget.articulosSeleccionadosIniciales) {
      _cantidadesAgregadas[articulo.id] = articulo.cantidad;
      _dismissibleKeys[articulo.id] = GlobalKey();
    }
  }

  // ✅ CARGAR PRODUCTOS DESDE ODDO
  Future<List<Product>> _loadProductsFromOdoo() async {
    try {
      print('🔄 Cargando productos desde Odoo...');
      
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        final productService = OdooProductService(odooService);
        final products = await productService.getProducts(limit: 50);
        
        print('✅ Productos cargados: ${products.length}');
        for (var product in products) {
          print('   📦 ${product.name} - \$${product.listPrice}');
        }
        
        if (mounted) {
          setState(() {
            _allProducts = products;
            _filteredProducts = products;
          });
        }
        
        return products;
      } else {
        throw Exception('Error de autenticación con Odoo');
      }
    } catch (e) {
      print('❌ Error cargando productos de Odoo: $e');
      return [];
    }
  }

  // ✅ CONVERTIR PRODUCT ODDO A ARTICULOITEM
  // ✅ CONVERTIR PRODUCT ODDO A ARTICULOITEM CON VERIFICACIONES
ArticuloItem _productToArticuloItem(Product product) {
  return ArticuloItem(
    id: product.id,
    nombre: product.name, // ✅ name es required
    categoria: product.categoryName ?? 'Sin categoría', // ✅ USAR ??
    subcategoria: product.typeDisplay, // ✅ typeDisplay es seguro
    precio: product.listPrice, // ✅ listPrice es required
    descripcion: product.description ?? product.name, // ✅ USAR ??
    cantidad: 1,
    // Campos opcionales con valores por defecto
    imagen: 'default_product',
    rating: 4.0,
    reviews: 0,
  );
}

  // ✅ OBTENER CATEGORÍAS ÚNICAS DE PRODUCTOS ODDO
  List<String> get categorias {
    final categoriasUnicas = _allProducts
        .map((p) => p.categoryName ?? 'Sin categoría')
        .toSet()
        .toList();
    
    return ['Todas las categorías', ...categoriasUnicas];
  }

  List<ArticuloItem> get articulosFiltrados {
    final articulos = _filteredProducts.map(_productToArticuloItem).toList();
    
    return articulos.where((articulo) {
      // Filtro de búsqueda
      final matchesSearch = _searchQuery.isEmpty ||
          articulo.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          articulo.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtro de categoría
      final matchesCategoria = _categoriaSeleccionada == 'Todas las categorías' || 
          articulo.categoria == _categoriaSeleccionada;

      return matchesSearch && matchesCategoria;
    }).toList();
  }

  List<ArticuloItem> get visibleArticulos {
    return articulosFiltrados.take(_visibleItems).toList();
  }

  bool get canLoadMore => _visibleItems < articulosFiltrados.length;

  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          // ✅ BÚSQUEDA POR NOMBRE, DESCRIPCIÓN Y CÓDIGO
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                // (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (product.defaultCode?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (product.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
      _visibleItems = _itemsPerLoad; // Resetear paginación
    });
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !canLoadMore) return;

    setState(() {
      _isLoadingMore = true;
    });

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

  void _agregarArticulo(ArticuloItem articulo, [int cantidad = 1]) {
    setState(() {
      final cantidadActual = _cantidadesAgregadas[articulo.id] ?? 0;
      _cantidadesAgregadas[articulo.id] = cantidadActual + cantidad;
      widget.onArticuloAgregado(articulo, cantidad);
    });
  }

  void _quitarArticulo(int articuloId, ArticuloItem articulo) {
    setState(() {
      final cantidadActual = _cantidadesAgregadas[articuloId] ?? 0;
      
      if (cantidadActual > 1) {
        _cantidadesAgregadas[articuloId] = cantidadActual - 1;
        widget.onArticuloAgregado(articulo, -1);
      } else {
        _cantidadesAgregadas.remove(articuloId);
        widget.onArticuloEliminado(articulo);
      }
    });
  }

  void _mostrarDialogoFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filtrar por:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Categorías
                  const Text(
                    "Categorías",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _categoriaSeleccionada,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: categorias.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _categoriaSeleccionada = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Spacer(),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _categoriaSeleccionada = 'Todas las categorías';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Limpiar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {}); // Actualizar la vista principal
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Aplicar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Productos"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _mostrarBusqueda = !_mostrarBusqueda;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureProducts = _loadProductsFromOdoo();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay productos disponibles'),
            );
          }
          
          return _buildContent();
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Barra de búsqueda (condicional)
        if (_mostrarBusqueda)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar productos...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filtrarProductos,
            ),
          ),

        // Contador y filtros
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${articulosFiltrados.length} productos encontrados",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 20),
                  onPressed: _mostrarDialogoFiltros,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Filtrar productos',
                ),
              ],
            ),
          ),
        ),

        // Lista de productos
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
                final cantidadAgregada = _cantidadesAgregadas[articulo.id] ?? 0;
                final yaAgregado = cantidadAgregada > 0;

                return _buildArticuloItem(articulo, cantidadAgregada, yaAgregado);
              },
            ),
          ),
        ),
      ],
    );
  }


Widget _buildArticuloItem(ArticuloItem articulo, int cantidad, bool yaAgregado) {
  if (!_dismissibleKeys.containsKey(articulo.id)) {
    _dismissibleKeys[articulo.id] = GlobalKey();
  }
  final product = _allProducts.firstWhere(
    (p) => p.id == articulo.id, 
    orElse: () => Product(
      id: articulo.id,
      name: articulo.nombre,
      defaultCode: '',
      listPrice: articulo.precio,
      type: articulo.subcategoria == 'Servicio' ? 'service' : 'consu',
      categoryName: articulo.categoria,
    )
  );
  
  // CALCULAR PRECIO CON IMPUESTO
  final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
  final precioConImpuesto = tieneImpuestos ? 
      product.listPrice * 1.18 : product.listPrice;

  return Dismissible(
    key: _dismissibleKeys[articulo.id]!,
    direction: DismissDirection.startToEnd,
    background: Container(
      color: Colors.green,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Row(
        children: [
          Icon(Icons.add, color: Colors.white),
          SizedBox(width: 8),
          Text('Agregar', style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
    onDismissed: (direction) {
      _agregarArticulo(articulo);
    },
    child: Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (product.typeColor).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getProductIcon(product.type),
            color: product.typeColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  fontSize: 15,
                  color: yaAgregado ? Colors.green[800] : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica
            Row(
              children: [
                Icon(Icons.category, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product.categoryName ?? 'Sin categoría',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            
            // Códigos y precios
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                if (product.defaultCode != null && product.defaultCode!.isNotEmpty)
                  _buildInfoChip('Ref: ${product.defaultCode!}', Icons.code),
              ],
            ),
            
            // ✅ MODIFICADO: Información de precio e impuestos - QUITAMOS "Precio final"
            SizedBox(height: 4),
            Row(
              children: [
                // ✅ CAMBIADO: Texto "Disponible" en lugar del precio
                Icon(Icons.inventory, size: 12, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  product.isSellable ? "Disponible" : "No vendible",
                  style: TextStyle(
                    fontSize: 12,
                    color: product.isSellable ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                // ✅ MANTENEMOS: Indicador de impuestos
                if (tieneImpuestos)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "+18% IVA",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            // ✅ QUITADO: La línea que mostraba "Precio final: \$..."
          ],
        ),
        trailing: SizedBox(
          width: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ✅ CAMBIADO: Mostrar el estado de disponibilidad en lugar del precio
              Text(
                product.isSellable ? "Disponible" : "No vendible",
                style: TextStyle(
                  fontSize: 10,
                  color: product.isSellable ? Colors.green[700] : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
              SizedBox(height: 4),
              if (yaAgregado)
                _buildQuantitySelector(articulo, cantidad)
              else
                // ✅ CAMBIADO: Mostrar el precio en lugar de "Disponible"
                Column(
                  children: [
                    Text(
                      "\$${precioConImpuesto.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    if (tieneImpuestos)
                      Text(
                        "inc. impuesto",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                articulo: articulo,
                product: product,
                cantidadInicial: cantidad,
                onAgregarArticulo: (articulo, cantidad) {
                  _agregarArticulo(articulo, cantidad);
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ✅ Widget para chips de información
Widget _buildInfoChip(String text, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey),
        SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
        ),
      ],
    ),
  );
}

// ✅ Selector de cantidad mejorado
Widget _buildQuantitySelector(ArticuloItem articulo, int cantidad) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _quitarArticulo(articulo.id, articulo),
          child: Icon(
            cantidad == 1 ? Icons.delete : Icons.remove, 
            size: 12, 
            color: Colors.white
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            cantidad.toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _agregarArticulo(articulo),
          child: Icon(Icons.add, size: 12, color: Colors.white),
        ),
      ],
    ),
  );
}

// ✅ Iconos según tipo de producto
IconData _getProductIcon(String type) {
  switch (type) {
    case 'consu':
      return Icons.shopping_bag;
    case 'service':
      return Icons.design_services;
    case 'product':
      return Icons.inventory;
    default:
      return Icons.shopping_bag;
  }
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
                  "Cargar más (${articulosFiltrados.length - _visibleItems} restantes)",
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

/// ✅ Pantalla de detalle de producto  
class ProductDetailScreen extends StatefulWidget {
  final ArticuloItem articulo;
  final Product product;
  final int cantidadInicial;
  final Function(ArticuloItem, int) onAgregarArticulo;

  const ProductDetailScreen({
    super.key,
    required this.articulo,
    required this.product,
    this.cantidadInicial = 0,
    required this.onAgregarArticulo,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _cantidad = widget.cantidadInicial > 0 ? widget.cantidadInicial : 1;
  }
 //  CALCULAR PRECIO CON IMPUESTO
  double get _precioConImpuesto {
    final tieneImpuestos = widget.product.taxesIds != null && widget.product.taxesIds!.isNotEmpty;
    return tieneImpuestos ? 
        widget.articulo.precio * 1.18 : widget.articulo.precio;
  }

  //  VERIFICAR SI TIENE IMPUESTOS
  bool get _tieneImpuestos {
    return widget.product.taxesIds != null && widget.product.taxesIds!.isNotEmpty;
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Producto"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Icono del producto
            Container(
              height: 200,
              width: double.infinity,
              color: widget.product.typeColor.withOpacity(0.1),
              child: Icon(
                _getProductIcon(widget.product.type),
                color: widget.product.typeColor,
                size: 80,
              ),
            ),
            
            // Información técnica del producto
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y tipo de producto
                  Text(
                    widget.articulo.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tipo de producto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.product.typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: widget.product.typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.product.typeDisplay,
                      style: TextStyle(
                        color: widget.product.typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //  INFORMACIÓN TÉCNICA - Similar a Seleccionar Productos
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  //  SECCIÓN DE PRECIOS MEJORADA CON DETALLE DE IMPUESTOS
                  _buildPricingSection(),
                  const SizedBox(height: 20),
                 
                  // Precio de venta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sell, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Precio de Venta",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "\$${widget.articulo.precio.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                 
                 // Selector de cantidad
                  _buildQuantitySelector(),
                  const SizedBox(height: 30),
                  
                  // Botón agregar a la orden
                  _buildAddToOrderButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ WIDGET PARA FILA DE PRECIO
  Widget _buildPriceRow({
    required String label,
    required String value,
    String? description,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                color: valueColor ?? Colors.green,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
         if (description != null && description.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          description, // ✅ Ahora es seguro porque verificamos que no sea null
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );
}


  //  SECCIÓN DE INFORMACIÓN TÉCNICA
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Información del Producto",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Código de producto
         if (widget.product.defaultCode != null && widget.product.defaultCode!.isNotEmpty)
           _buildInfoRow(
             icon: Icons.code,
             label: "Código de Producto",
             value: widget.product.defaultCode!,
           ),

        // Referencia
        // if (widget.product.barcode != null && widget.product.barcode!.isNotEmpty)
        //   _buildInfoRow(
        //     icon: Icons.qr_code,
        //     label: "Referencia",
        //     value: widget.product.barcode!,
        //   ),
        
        // Costo
        // if (widget.product.standardPrice != null)
        //   _buildInfoRow(
        //     icon: Icons.attach_money,
        //     label: "Costo",
        //     value: "\$${widget.product.standardPrice!.toStringAsFixed(2)}",
        //   ),
        
        // Categoría
        _buildInfoRow(
          icon: Icons.category,
          label: "Categoría",
          value: widget.product.categoryName ?? 'Sin categoría',
        ),
        
        // Descripción
        if (widget.product.description != null && widget.product.description!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.description,
            label: "Descripción",
            value: widget.product.description!,
            multiline: true,
          ),
        
        // Estado de venta
        _buildInfoRow(
          icon: widget.product.isSellable ? Icons.check_circle : Icons.block,
          label: "Estado",
          value: widget.product.isSellable ? "Disponible para venta" : "No vendible",
          valueColor: widget.product.isSellable ? Colors.green : Colors.red,
        ),
      ],
    );
  }

    // ✅ NUEVA SECCIÓN DE PRECIOS CON DETALLE DE IMPUESTOS
  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                "Información de Precios",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Precio base
          _buildPriceRow(
            label: "Precio base:",
            value: "\$${widget.articulo.precio.toStringAsFixed(2)}",
            description: ""
          ),
          
          // Impuesto si aplica
          if (_tieneImpuestos) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Impuesto IVA (18%):",
              value: "\$${(widget.articulo.precio * 0.18).toStringAsFixed(2)}",
              description: "",
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Precio final:",
              value: "\$${_precioConImpuesto.toStringAsFixed(2)}",
              description: "",
              valueColor: Colors.green,
              isBold: true,
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Impuestos:",
              value: "Exento",
              description: "Producto no sujeto a impuestos",
              valueColor: Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Precio final:",
              value: "\$${widget.articulo.precio.toStringAsFixed(2)}",
              description: "Mismo precio base (sin impuestos)",
              valueColor: Colors.green,
              isBold: true,
            ),
          ],
          
          // Nota informativa sobre impuestos
          if (_tieneImpuestos) 
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Este producto incluye IVA del 18%. El precio final ya incluye el impuesto.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ✅ FILA DE INFORMACIÓN
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: multiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ✅ SELECTOR DE CANTIDAD
  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Cantidad:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              // Botón disminuir
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: _cantidad == 1 ? Colors.grey : Colors.blue,
                onPressed: () {
                  if (_cantidad > 1) {
                    setState(() => _cantidad--);
                  }
                },
              ),
              // Cantidad actual
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  _cantidad.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              // Botón aumentar
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: _cantidad == 99 ? Colors.grey : Colors.blue,
                onPressed: () {
                  if (_cantidad < 99) {
                    setState(() => _cantidad++);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ BOTÓN AGREGAR A ORDEN
  Widget _buildAddToOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onAgregarArticulo(widget.articulo, _cantidad);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${_cantidad} ${widget.articulo.nombre} agregado(s) a la orden"),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        },
        icon: const Icon(Icons.shopping_bag),
        label: Text(
          widget.cantidadInicial > 0 ? "Actualizar en orden" : "Agregar artículo",
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // ✅ ICONO SEGÚN TIPO DE PRODUCTO
  IconData _getProductIcon(String type) {
    switch (type) {
      case 'consu':
        return Icons.shopping_bag;
      case 'service':
        return Icons.design_services;
      case 'product':
        return Icons.inventory;
      default:
        return Icons.shopping_bag;
    }
  }
}