import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

import 'package:ecomerce_app/src/services/cache_service.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';


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
  final Map<int, int> _cantidadesAgregadas = {};

  //  VARIABLES DE PAGINACIÓN CORREGIDAS
    List<Product> _allProducts = [];
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentSearchQuery = '';
  Timer? _searchDebounceTimer;

  // ❌ ELIMINAR VARIABLES DUPLICADAS O CONFLICTIVAS
  // String _searchQuery = ''; // ← ELIMINAR
  // late Future<List<Product>> _futureProducts; // ← ELIMINAR
  // List<Product> _filteredProducts = []; // ← ELIMINAR
  // final int _itemsPerLoad = 10; // ← ELIMINAR
  // int _visibleItems = 10; // ← ELIMINAR
  // bool _isLoadingMore = false; // ← ELIMINAR

  // Variables que SÍ se mantienen
  bool _mostrarBusqueda = false;
  String _categoriaSeleccionada = 'Todas las categorías';
  //final Map<int, GlobalKey> _dismissibleKeys = {};

  @override
  void initState() {
    super.initState();
    
    //  SOLO CARGAR PAGINACIÓN, NO FUTURE
    _loadMoreProducts(reset: true);
     
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text); 
    });

    // INICIALIZAR CON PRODUCTOS SELECCIONADOS
    for (var articulo in widget.articulosSeleccionadosIniciales) {
      _cantidadesAgregadas[articulo.id] = articulo.cantidad;
     // _dismissibleKeys[articulo.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // BÚSQUEDA CON DEBOUNCE
  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    print('🔍 Ejecutando búsqueda: "$query"');
    _loadMoreProducts(reset: true, searchQuery: query);
  }

  
  // CARGAR PRODUCTOS CON PAGINACIÓN
  Future<void> _loadMoreProducts({
    bool reset = false, 
    String searchQuery = ''
  }) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (reset) {
        _allProducts.clear();
        _currentPage = 0;
        _hasMore = true;
        _currentSearchQuery = searchQuery;
        print('🔄 Reiniciando lista - Búsqueda: "$searchQuery"');
      }
    });

    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://solutions.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      await odooService.login('admin', 'admin');
      final productService = OdooProductService(odooService);
      
      final result = await productService.getProductsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery,
      );

      if (mounted) {
        setState(() {
          _allProducts.addAll(result['products']);
          _hasMore = result['hasMore'];
          _currentPage++;
          _isLoading = false;
        });

        print('✅ Página ${_currentPage - 1} cargada: ${result['products'].length} productos');
        print('   Total en lista: ${_allProducts.length}, ¿Hay más?: $_hasMore');
        
        if (reset && result['totalCount'] > 0) {
          print('   📊 Total encontrado: ${result['totalCount']} productos');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('❌ Error cargando productos: $e');
      
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  // DETECTAR SCROLL PARA CARGAR MÁS
   void _onScroll(ScrollNotification scrollInfo) {
    if (_isLoading || !_hasMore) return;
    
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
      _loadMoreProducts(searchQuery: _currentSearchQuery);
    }
  }


// //Future<List<Product>> _loadProductsFromOdoo() async {
//   final tieneInternet = await ConnectivityService.hasInternet();
  
//   if (tieneInternet) {
//     // ✅ CON INTERNET: Cargar de Odoo + actualizar caché
//     return await _loadProductsFromOdooOnline();
//   } else {
//     // 🔴 SIN INTERNET: Usar caché local
//     return await _loadProductsFromCache(); // 
//   }
// }

// //Future<List<Product>> _loadProductsFromOdooOnline() async {
//   try {
//     print('🔵 Modo Online - Cargando productos de Odoo...');
    
//     final odooService = OdooServiceEnhanced(
//       baseUrl: 'https://pointsalesqa.tailorw.net',
//       dbName: 'pointsales_prodv18',
//     );
    
//     bool isAuthenticated = await odooService.login('admin', 'admin');
    
//     if (isAuthenticated) {
//       final productService = OdooProductService(odooService);
//       final products = await productService.getProducts(limit: 50);
      
//       // ✅ GUARDAR EN CACHÉ
//       await CacheService.saveProducts(products);
      
//       if (mounted) {
//         setState(() {
//           _allProducts = products;
//           _filteredProducts = products;
//         });
//       }
      
//       print('✅ ${products.length} productos cargados desde Odoo y guardados en caché');
      
//       for (var product in products.take(3)) {
//         print('   📦 ${product.name} - \$${product.listPrice}');
//       }
//       if (products.length > 3) {
//         print('   ... y ${products.length - 3} más');
//       }
      
//       return products; // ✅ YA ESTÁ BIEN ESTA LÍNEA
//     } else {
//       throw Exception('Error de autenticación con Odoo');
//     }
//   } catch (e) {
//     print('❌ Error cargando productos de Odoo: $e');
//     // Fallback: intentar cargar del caché
//     return await _loadProductsFromCache(); // ✅ CORREGIDO
//   }
// }

// Future<List<Product>> _loadProductsFromCache() async {
//   print('🔴 [DEBUG] _loadProductsFromCache INICIADO');
  
//   try {
//     print('${_getTimestamp()} 🔴 Modo Offline - Cargando productos del caché...');
    
//     final productosCache = await CacheService.getCachedProducts();
    
//     print('🔴 [DEBUG] Productos del caché: ${productosCache.length}');
    
//     if (productosCache.isNotEmpty && mounted) {
//       print('🔴 [DEBUG] Intentando mostrar SnackBar para productos...');
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.wifi_off, size: 20, color: Colors.orange),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text('📦 ${productosCache.length} productos cargados del caché'),
//               ),
//             ],
//           ),
//           duration: Duration(seconds: 4),
//           backgroundColor: Colors.orange[800],
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
      
//       print('🔴 [DEBUG] SnackBar de productos mostrado');
      
//       setState(() {
//         _allProducts = productosCache;
//         _filteredProducts = productosCache;
//       });
      
//       print('${_getTimestamp()} ✅ ${productosCache.length} productos cargados del caché');
//       print('🔴 [DEBUG] _loadProductsFromCache FINALIZADO - ÉXITO'); // 
      
//       return productosCache;
//     } else {
//       print('🔴 [DEBUG] No hay productos en caché o widget no mounted');
//       print('🔴 [DEBUG] _loadProductsFromCache FINALIZADO - VACÍO'); // 
//       return [];
//     }
//   } catch (e) {
//     print('❌ Error cargando productos del caché: $e');
//     print('🔴 [DEBUG] _loadProductsFromCache FINALIZADO - ERROR'); // 
//     return [];
//   }
// }


String _getTimestamp() {
  return '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]';
} 
  
 ArticuloItem _productToArticuloItem(Product product) {
    return ArticuloItem(
      id: product.id,
      nombre: product.name,
      categoria: product.categoryName ?? 'Sin categoría',
      subcategoria: product.typeDisplay,
      precio: product.listPrice,
      descripcion: product.description ?? product.name,
      cantidad: 1,
      imagen: 'default_product',
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

  // List<ArticuloItem> get articulosFiltrados {
  //   final articulos = _filteredProducts.map(_productToArticuloItem).toList();
    
  //   return articulos.where((articulo) {
  //     // Filtro de búsqueda
  //     final matchesSearch = _searchQuery.isEmpty ||
  //         articulo.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
  //         articulo.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());

  //     // Filtro de categoría
  //     final matchesCategoria = _categoriaSeleccionada == 'Todas las categorías' || 
  //         articulo.categoria == _categoriaSeleccionada;

  //     return matchesSearch && matchesCategoria;
  //   }).toList();
  // }

  // CONVERTIR PRODUCTOS A ARTÍCULOS
  List<ArticuloItem> get articulosFiltrados {
    return _allProducts.map(_productToArticuloItem).toList();
  }


  // List<ArticuloItem> get visibleArticulos {
  //   return articulosFiltrados.take(_visibleItems).toList();
  // }

  //bool get canLoadMore => _visibleItems < articulosFiltrados.length;

  // void _filtrarProductos(String query) {
  //   setState(() {
  //     if (query.isEmpty) {
  //       _filteredProducts = _allProducts;
  //     } else {
  //       _filteredProducts = _allProducts.where((product) {
  //         // ✅ BÚSQUEDA POR NOMBRE, DESCRIPCIÓN Y CÓDIGO
  //         return product.name.toLowerCase().contains(query.toLowerCase()) ||
  //               // (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
  //                (product.defaultCode?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
  //                (product.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false);
  //       }).toList();
  //     }
  //     _visibleItems = _itemsPerLoad; // Resetear paginación
  //   });
  // }

  // Future<void> _loadMoreItems() async {
  //   if (_isLoadingMore || !canLoadMore) return;

  //   setState(() {
  //     _isLoadingMore = true;
  //   });

  //   await Future.delayed(const Duration(milliseconds: 500));

  //   setState(() {
  //     _visibleItems += _itemsPerLoad;
  //     _isLoadingMore = false;
  //   });
  // }

  // void _resetPagination() {
  //   setState(() {
  //     _visibleItems = _itemsPerLoad;
  //   });
  // }

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
    body: _buildContent(), // ✅ DIRECTAMENTE EL CONTENIDO, NO FUTUREBUILDER
  );
}

  Widget _buildContent() {
    return Column(
      children: [
        // Barra de búsqueda 
        if (_mostrarBusqueda)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre, código o barras...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),


                //  INDICADOR DE ESTADO

          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentSearchQuery.isEmpty
                    ? "${_allProducts.length} productos${_hasMore ? '+' : ''}"
                    : '"$_currentSearchQuery" - ${_allProducts.length} resultados${_hasMore ? '+' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),




        // Lista de productos
         Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              _onScroll(scrollInfo);
              return false;
            },
            child: _allProducts.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _allProducts.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                    itemBuilder: (context, index) {
                      if (index == _allProducts.length) {
                        return _buildLoadMoreLoader();
                      }
                      
                      final product = _allProducts[index];
                      final articulo = _productToArticuloItem(product);
                      final cantidadAgregada = _cantidadesAgregadas[articulo.id] ?? 0;
                      final yaAgregado = cantidadAgregada > 0;

                      return _buildArticuloItem(articulo, cantidadAgregada, yaAgregado, product);
                    },
                  ),
          ),
        ),
      ],
    );
  }


  //  ESTADO VACÍO
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentSearchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _currentSearchQuery.isEmpty 
                ? "No hay productos disponibles"
                : 'No se encontraron resultados para "${_currentSearchQuery}"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_currentSearchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
              child: const Text('Limpiar búsqueda'),
            ),
        ],
      ),
    );
  }

  
 //  LOADER PARA CARGAR MÁS
  Widget _buildLoadMoreLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : OutlinedButton(
                onPressed: () => _loadMoreProducts(searchQuery: _currentSearchQuery),
                child: const Text("Cargar más productos"),
              ),
      ),
    );
  }



//  ITEM DE PRODUCTO (adaptado para 4 parámetros)
  Widget _buildArticuloItem(ArticuloItem articulo, int cantidad, bool yaAgregado, Product product) {
  //  if (!_dismissibleKeys.containsKey(articulo.id)) {
   //   _dismissibleKeys[articulo.id] = GlobalKey();
   // }
    
    // CALCULAR PRECIO CON IMPUESTO
    final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
    final precioConImpuesto = tieneImpuestos ? 
        product.listPrice * 1.18 : product.listPrice;

    return Dismissible(
       key: Key('product_${articulo.id}_${product.hashCode}'), 
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
              
              // Códigos
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  if (product.defaultCode != null && product.defaultCode!.isNotEmpty)
                    _buildInfoChip('Ref: ${product.defaultCode!}', Icons.code),
                ],
              ),
              
              // Información de disponibilidad e impuestos
              SizedBox(height: 4),
              Row(
                children: [
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
            ],
          ),
          trailing: SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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

// Selector de cantidad mejorado
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

//  Iconos según tipo de producto
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


  // Widget _buildLoadMoreButton() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 16),
  //     child: Center(
  //       child: _isLoadingMore
  //           ? const CircularProgressIndicator(strokeWidth: 2)
  //           : OutlinedButton(
  //               onPressed: _loadMoreItems,
  //               style: OutlinedButton.styleFrom(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //               ),
  //               child: Text(
  //                 "Cargar más (${articulosFiltrados.length - _visibleItems} restantes)",
  //                 style: const TextStyle(fontSize: 12),
  //               ),
  //             ),
  //     ),
  //   );
  // }
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
  late ArticuloItem _currentArticulo;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _cantidad = widget.cantidadInicial > 0 ? widget.cantidadInicial : 1;

    _actualizarProductoEnTiempoReal(); 
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


Future<void> _actualizarProductoEnTiempoReal() async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: 'https://solutions.tailorw.net',
      dbName: 'pointsales_prodv18',
    );
    
    await odooService.login('admin', 'admin');
    final productService = OdooProductService(odooService);
    
    final productoActualizado = await productService.getProductDetails(widget.product.id);
    
    if (productoActualizado != null && mounted) {
      setState(() {
        // ✅ USAR COPYWITH PARA CREAR NUEVAS INSTANCIAS ACTUALIZADAS
        _currentArticulo = widget.articulo.copyWithProduct(productoActualizado);
        _currentProduct = widget.product.copyWith(
          name: productoActualizado.name,
          listPrice: productoActualizado.listPrice,
          categoryName: productoActualizado.categoryName,
          description: productoActualizado.description,
        );
      });
      
      print('✅ Producto actualizado en detalle: ${productoActualizado.name} - \$${productoActualizado.listPrice}');
    }
  } catch (e) {
    print('⚠️ No se pudo actualizar producto, usando datos cacheados: $e');
  }
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
             Text(
            _currentArticulo.nombre, // ← USAR LA VERSIÓN ACTUALIZADA
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
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
        // ✅ PASAR LA VERSIÓN ACTUALIZADA
        widget.onAgregarArticulo(_currentArticulo, _cantidad);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_cantidad} ${_currentArticulo.nombre} agregado(s) a la orden"),
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