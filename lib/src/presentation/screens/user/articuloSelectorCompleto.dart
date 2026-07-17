import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

//import 'package:ecomerce_app/src/services/cache_service.dart';
//import 'package:ecomerce_app/src/services/connectivity_service.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

class ArticuloSelectorScreen extends StatefulWidget {
  final Function(ArticuloItem, int) onArticuloAgregado; 
  final Function(ArticuloItem) onArticuloEliminado;
  final List<ArticuloItem> articulosSeleccionadosIniciales;
  final bool esParaVenta; // [NEW] Flag para controlar impuestos

  const ArticuloSelectorScreen({
    super.key, 
    required this.onArticuloAgregado,
    required this.onArticuloEliminado,
    required this.articulosSeleccionadosIniciales,
    this.esParaVenta = true, // Default true para compatibilidad
  });

  @override
  State<ArticuloSelectorScreen> createState() => _ArticuloSelectorScreenState();
}

class _ArticuloSelectorScreenState extends State<ArticuloSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _cantidadesAgregadas = {};
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
    facing: CameraFacing.back,
  );

  List<Product> _allProducts = [];
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentSearchQuery = '';
  Timer? _searchDebounceTimer;
  bool _mostrarBusqueda = false;
  String _categoriaSeleccionada = 'Todas las categorías';
  bool _mostrarScanner = false;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    
    _loadMoreProducts(reset: true);
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text); 
    });

    for (var articulo in widget.articulosSeleccionadosIniciales) {
      _cantidadesAgregadas[articulo.id] = articulo.cantidad;
     // _dismissibleKeys[articulo.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
     _scannerController.dispose();
    super.dispose();
  }


// ✅ MÉTODO PARA MANEJAR EL ESCANEO (ACTUALIZADO)
void _handleScan(BarcodeCapture capture) async {
  if (_isProcessingScan || capture.barcodes.isEmpty) return;
  
  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  _isProcessingScan = true;
  
  try {
    // ✅ BUSCAR EN TIEMPO REAL EN ODDO
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    final productService = OdooProductService(odooService);
    
    Product? productRealTime = await productService.getProductByBarcode(code);
    
    if (productRealTime != null) {
      print('✅ Producto escaneado en Selector: ${productRealTime.name}');
      
      // ✅ OBTENER DETALLES COMPLETOS
      final productDetails = await productService.getProductDetails(productRealTime.id);
      
      if (productDetails != null) {
        productRealTime = productDetails;
      }
      
      // ✅ USAR LAS FUNCIONES PARA CALCULAR IMPUESTOS
      final precioConImpuesto = _getPrecioConImpuesto(productRealTime);
      final tieneImpuestos = _tieneImpuestos(productRealTime);

      final articuloActualizado = ArticuloItem(
        id: productRealTime.id,
        nombre: productRealTime.name,
        categoria: productRealTime.categoryName ?? 'Sin categoría',
        subcategoria: productRealTime.typeDisplay,
        precio: precioConImpuesto, // ✅ INCLUIR IMPUESTO
        descripcion: productRealTime.description ?? productRealTime.name,
        cantidad: 1,
        tieneImpuestos: tieneImpuestos,
      );
      
      _mostrarDetalleProductoEscaneado(articuloActualizado);
    } else {
      // ✅ Fallback a búsqueda local
      final productoCached = _allProducts.firstWhere(
        (p) => p.barcode == code || p.defaultCode == code,
        orElse: () => Product(
          id: -1,
          name: '',
          listPrice: 0.0,
          type: 'consu',
        ),
      );
      
      if (productoCached.id != -1) {
        // ✅ USAR LAS FUNCIONES PARA CALCULAR IMPUESTOS
        final precioConImpuesto = _getPrecioConImpuesto(productoCached);
        final tieneImpuestos = _tieneImpuestos(productoCached);
        
        final articulo = ArticuloItem(
          id: productoCached.id,
          nombre: productoCached.name,
          categoria: productoCached.categoryName ?? 'Sin categoría',
          subcategoria: productoCached.typeDisplay,
          precio: precioConImpuesto, // ✅ INCLUIR IMPUESTO
          descripcion: productoCached.description ?? productoCached.name,
          cantidad: 1,
          tieneImpuestos: tieneImpuestos,
        );
        _mostrarDetalleProductoEscaneado(articulo);
      } else {
        _mostrarMensajeError('Producto no encontrado con código: $code');
      }
    }
  } catch (e) {
    print('❌ Error en escaneo: $e');
    _mostrarMensajeError('Error al escanear: $e');
  } finally {
    _isProcessingScan = false;
    setState(() => _mostrarScanner = false);
  }
}

  // ✅ MÉTODO AUXILIAR PARA MOSTRAR MENSAJES DE ERROR
  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ MÉTODO PARA MOSTRAR DETALLE DEL PRODUCTO ESCANEADO
  void _mostrarDetalleProductoEscaneado(ArticuloItem producto) {
    final cantidadExistente = _cantidadesAgregadas[producto.id] ?? 0;

    // ✅ BUSCAR EL PRODUCTO CORRESPONDIENTE EN LA LISTA
    final product = _allProducts.firstWhere(
      (p) => p.id == producto.id,
      orElse: () => Product(
        id: producto.id,
        name: producto.nombre,
        defaultCode: '',
        listPrice: producto.precio,
        type: producto.subcategoria == 'Servicio' ? 'service' : 'consu',
        categoryName: producto.categoria,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          articulo: producto,
          product: product,
          cantidadInicial: cantidadExistente,
          onAgregarArticulo: (articulo, cantidad) {
            _agregarArticulo(articulo, cantidad);
          },
          esParaVenta: widget.esParaVenta, // ✅ Pasar el flag
        ),
      ),
    );
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
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      
      await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
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



String _getTimestamp() {
  return '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]';
} 
  
 ArticuloItem _productToArticuloItem(Product product) {
 final esParaVentas = widget.esParaVenta; // ✅ Usar el flag del widget 
 final precioFinal = esParaVentas ? _getPrecioConImpuesto(product) : product.listPrice;
  final tieneImpuestos = esParaVentas && _tieneImpuestos(product);
  
  print('💰 Convirtiendo Product a ArticuloItem:');
  print('   Nombre: ${product.name}');
  print('   Precio base: \$${product.listPrice}');
  print('   Precio final: \$${precioFinal.toStringAsFixed(2)}');
  print('   Tiene impuestos: $tieneImpuestos');
  
  return ArticuloItem(
    id: product.id,
    nombre: product.name,
    categoria: product.categoryName ?? 'Sin categoría',
    subcategoria: product.typeDisplay,
     precio: precioFinal, // ✅ USAR PRECIO CON IMPUESTOS
    descripcion: product.description ?? product.name,
    cantidad: 1,
    imagen: 'default_product',
    tieneImpuestos: tieneImpuestos, // ✅ GUARDAR ESTADO DE IMPUESTOS
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
    return _allProducts.map(_productToArticuloItem).toList();
  }



  void _agregarArticulo(ArticuloItem articulo, [int cantidad = 1]) {
  setState(() {
    final cantidadActual = _cantidadesAgregadas[articulo.id] ?? 0;
    _cantidadesAgregadas[articulo.id] = cantidadActual + cantidad;
    widget.onArticuloAgregado(articulo, cantidad);
  });
  
  // ✅ FEEDBACK VISUAL INMEDIATO
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${articulo.nombre} agregado'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ),
  );
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
      title: const Text(" Productos"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
            tooltip: 'Escanear código de barras',
          ),

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
        // ✅ SCANNER (igual que en NuevaOrdenPage)
        if (_mostrarScanner)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MobileScanner(
              controller: _scannerController, 
              onDetect: _handleScan
            ),
          ),

        // Barra de búsqueda 
        if (_mostrarBusqueda)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre, código o barras...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentSearchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      ),
                    // Botón de escáner dentro del campo de búsqueda también
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
                      tooltip: 'Escanear código',
                    ),
                  ],
                ),
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

  // ✅ AGREGAR ESTAS FUNCIONES EN ArticuloSelectorScreen
double _getPrecioConImpuesto(Product product) {
  final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
  final tieneImpuestoCompra = product.supplierTaxesIds != null && 
                             product.supplierTaxesIds!.isNotEmpty;
  
  print('🔍 _getPrecioConImpuesto para: ${product.name}');
  print('   Precio base: \$${product.listPrice}');
  print('   Tiene impuestos venta: $tieneImpuestos');
  print('   Tiene impuestos compra: $tieneImpuestoCompra');

  // ✅ SI NO ES PARA VENTA, RETORNAR PRECIO BASE SIN IMPUESTOS
  if (!widget.esParaVenta) {
     print('   ⚠️ Modo Compra: Sin impuestos forzado: \$${product.listPrice}');
     return product.listPrice;
  }
  
  if (tieneImpuestos || tieneImpuestoCompra) {
    final precioConImpuesto = product.listPrice;
    print('   ✅ ITBIS incl en BD: \$${precioConImpuesto.toStringAsFixed(2)}');
    return precioConImpuesto;
  }
  
  print('   ⚠️ Sin impuestos: \$${product.listPrice}');
  return product.listPrice;
}

bool _tieneImpuestos(Product product) {
  return (product.taxesIds != null && product.taxesIds!.isNotEmpty) ||
         (product.supplierTaxesIds != null && product.supplierTaxesIds!.isNotEmpty);
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

Widget _buildArticuloItem(ArticuloItem articulo, int cantidad, bool yaAgregado, Product product) {
  // ✅ USAR LAS FUNCIONES PARA CALCULAR IMPUESTOS
  final tieneImpuestos = _tieneImpuestos(product);
  final precioConImpuesto = _getPrecioConImpuesto(product);

  // ✅ CLAVE ÚNICA Y ESTABLE QUE INCLUYA EL ESTADO ACTUAL
  final uniqueKey = '${articulo.id}_${product.id}_${_currentPage}_${cantidad}_${_currentSearchQuery}';

  return Dismissible(
    key: Key(uniqueKey), // ✅ CLAVE MÁS ESTABLE Y ÚNICA
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
    confirmDismiss: (direction) async {
      // ✅ CONFIRMACIÓN ANTES DE AGREGAR
      return await _mostrarConfirmacionAgregar(articulo);
    },
    onDismissed: (direction) {
      // ✅ AGREGAR EL PRODUCTO
      _agregarArticulo(articulo);
      
      // ✅ MOSTRAR FEEDBACK
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${articulo.nombre} agregado' + 
                       (articulo.tieneImpuestos ? ' (con ITBIS)' : '')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
    dismissThresholds: const {
      DismissDirection.startToEnd: 0.4,
    },
    movementDuration: const Duration(milliseconds: 300),
    child: _buildProductContent(articulo, cantidad, yaAgregado, product, precioConImpuesto, tieneImpuestos),
  );
}

// ✅ MÉTODO SEPARADO PARA EL CONTENIDO DEL PRODUCTO
// ✅ MÉTODO SEPARADO PARA EL CONTENIDO DEL PRODUCTO (ACTUALIZADO)
Widget _buildProductContent(
  ArticuloItem articulo, 
  int cantidad, 
  bool yaAgregado, 
  Product product, 
  double precioConImpuesto, 
  bool tieneImpuestos
) {
  return Container(
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
              if (product.barcode != null && product.barcode!.isNotEmpty)
                _buildInfoChip('Cód: ${product.barcode!}', Icons.qr_code),
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
                    "+18% ITBIS",
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
                    "\$${articulo.precio.toStringAsFixed(2)}", // ✅ USAR PRECIO DEL ARTÍCULO (ya incluye impuestos)
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  if (articulo.tieneImpuestos) // ✅ VERIFICAR EN EL ARTÍCULO
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
              esParaVenta: widget.esParaVenta, // ✅ Pasar el flag
            ),
          ),
        );
      },
    ),
  );

}

// ✅ MÉTODO PARA CONFIRMAR AGREGAR PRODUCTO
Future<bool> _mostrarConfirmacionAgregar(ArticuloItem articulo) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.green),
            SizedBox(width: 8),
            Text("Agregar producto"),
          ],
        ),
        content: Text("¿Agregar \"${articulo.nombre}\" a la orden?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text("Agregar", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  ) ?? false;
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

}

/// ✅ Pantalla de detalle de producto  
class ProductDetailScreen extends StatefulWidget {
  final ArticuloItem articulo;
  final Product product;
  final int cantidadInicial;
  final Function(ArticuloItem, int) onAgregarArticulo;
  final bool esParaVenta;

  const ProductDetailScreen({
    super.key,
    required this.articulo,
    required this.product,
    this.cantidadInicial = 0,
    required this.onAgregarArticulo,
    this.esParaVenta = true, 
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _cantidad = 1;
   late ArticuloItem _currentArticulo = widget.articulo; 
  late Product _currentProduct = widget.product;  

  @override
  void initState() {
    super.initState();
    _cantidad = widget.cantidadInicial > 0 ? widget.cantidadInicial : 1;
    _currentArticulo = widget.articulo;
    _currentProduct = widget.product;
    _actualizarProductoEnTiempoReal(); 
  }
  ArticuloItem get articuloActual => _currentArticulo ?? widget.articulo;
  Product get productActual => _currentProduct ?? widget.product;

  double get _precioFinalParaVenta {
    if (widget.esParaVenta) {
      // ✅ PARA VENTAS: Usar el precio del artículo que YA tiene impuestos aplicados
        return _currentArticulo.precio; 
    } else {
      // ✅ PARA COMPRAS: Usar precio sin impuestos
      return _currentProduct.listPrice;
    }
  }

  bool get _tieneImpuestos {
    // Verificar si debe mostrar impuestos (solo para ventas)
    if (!widget.esParaVenta) return false;
    
    return widget.articulo.tieneImpuestos ?? 
           (widget.product.taxesIds != null && widget.product.taxesIds!.isNotEmpty);
  }


  (double precioBase, double montoImpuesto, double precioFinal) _calcularDesglosePrecio() {
    if (!widget.esParaVenta) {
      // Para compras: no hay impuestos
      return (_precioFinalParaVenta, 0.0, _precioFinalParaVenta);
    }
    
     final precioArticulo = articuloActual.precio; // Este es el precio FINAL con impuestos
    
    if (_tieneImpuestos) {
      // Si tiene impuestos, calcular el precio base
      final precioBase = precioArticulo / 1.18;
      final montoImpuesto = precioArticulo - precioBase;
      
      return (precioBase, montoImpuesto, precioArticulo);
    } else {
      // Si no tiene impuestos, el precio es el mismo
      return (precioArticulo, 0.0, precioArticulo);
    }
  }

Future<void> _actualizarProductoEnTiempoReal() async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    final productService = OdooProductService(odooService);
    
    final productoActualizado = await productService.getProductDetails(widget.product.id);
    
    if (productoActualizado != null && mounted) {
        setState(() {
          // ✅ USAR COPYWITH PARA CREAR NUEVAS INSTANCIAS ACTUALIZADAS
          _currentArticulo = widget.articulo.copyWithProduct(productoActualizado);
          _currentProduct = productoActualizado;
        });
      
      print('✅ Producto actualizado en detalle: ${productoActualizado.name} - \$${productoActualizado.listPrice}');
    }
  } catch (e) {
    print('⚠️ No se pudo actualizar producto, usando datos cacheados: $e');
  }
}


  @override
  Widget build(BuildContext context) {
     final articulo = articuloActual;
    final product = productActual;
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

// ✅ SECCIÓN DE PRECIOS MEJORADA CON DETALLE DE IMPUESTOS (CORREGIDO)
Widget _buildPricingSection() {
    print('🔄 _buildPricingSection llamado:');
  print('   widget.articulo.precio: \$${widget.articulo.precio}');
  print('   widget.articulo.tieneImpuestos: ${widget.articulo.tieneImpuestos}');
  print('   widget.product.taxesIds: ${widget.product.taxesIds}');
  print('   _tieneImpuestos: ${_tieneImpuestos}');
  final tieneImpuestos = _tieneImpuestos;
  
  if (tieneImpuestos) {
    // ✅ CASO 1: PRODUCTO CON IMPUESTOS
    // Asumimos que widget.articulo.precio es el precio FINAL con ITBIS incluido
    final precioFinal = widget.articulo.precio; // $174.99 (ejemplo)
    final precioBase = precioFinal / 1.18; // $148.30
    final montoImpuesto = precioFinal - precioBase; // $26.69
    
    print('💰 Producto CON impuestos:');
    print('   Precio final: \$${precioFinal.toStringAsFixed(2)}');
    print('   Precio base: \$${precioBase.toStringAsFixed(2)}');
    print('   ITBIS 18%: \$${montoImpuesto.toStringAsFixed(2)}');
    
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
          
          // Desglose de precios CON impuestos
          _buildPriceRow(
            label: "Precio sin ITBIS:",
            value: "\$${precioBase.toStringAsFixed(2)}",
            description: "Precio base sin impuestos"
          ),
          
          const SizedBox(height: 8),
          _buildPriceRow(
            label: "Impuesto ITBIS (18%):",
            value: "\$${montoImpuesto.toStringAsFixed(2)}",
            description: "Aplicado sobre el precio base",
            valueColor: Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            label: "Precio final (con ITBIS):",
            value: "\$${precioFinal.toStringAsFixed(2)}",
            description: "Incluye 18% ITBIS",
            valueColor: Colors.green,
            isBold: true,
          ),
          
          // Precio de venta
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.sell, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Precio de Venta",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${precioFinal.toStringAsFixed(2)}", // ✅ MUESTRA EL PRECIO FINAL
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Incluye 18% ITBIS",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Nota informativa sobre impuestos
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
                    "Este producto incluye ITBIS del 18%. El precio de venta ya incluye el impuesto.",
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
  } else {
    // ✅ CASO 2: PRODUCTO SIN IMPUESTOS
    final precioFinal = widget.articulo.precio; // $148.30 (ejemplo)
    final precioBase = widget.product.listPrice;
    
    print('💰 Producto SIN impuestos:');
    print('   Precio final: \$${precioFinal.toStringAsFixed(2)}');
    
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
          
          // Desglose de precios SIN impuestos
          _buildPriceRow(
            label: "Precio base:",
            value: "\$${precioFinal.toStringAsFixed(2)}"
          ),
          
          // const SizedBox(height: 8),
          // _buildPriceRow(
          //   label: "Impuestos:",
          //   value: "Exento",
          //   description: "Producto no sujeto a impuestos",
          //   valueColor: Colors.grey,
          // ),
          const SizedBox(height: 8),
          _buildPriceRow(
            label: "Precio final:",
            value: "\$${precioFinal.toStringAsFixed(2)}",
            valueColor: Colors.green,
            isBold: true,
          ),
          
          // Precio de venta
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.sell, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Precio de Venta",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${precioFinal.toStringAsFixed(2)}", // ✅ MUESTRA EL PRECIO FINAL
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        widget.cantidadInicial > 0 ? "Actualizar en orden" : "Guardar Orden",
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
