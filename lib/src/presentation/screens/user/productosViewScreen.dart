import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/presentation/screens/user/ProductDetailViewScreen.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

class ProductosViewScreen extends StatefulWidget {
  const ProductosViewScreen({super.key});

  @override
  State<ProductosViewScreen> createState() => _ProductosViewScreenState();
}

class _ProductosViewScreenState extends State<ProductosViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
    facing: CameraFacing.back,
  );

  // VARIABLES DE PAGINACIÓN
  List<Product> _allProducts = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  Timer? _searchDebounceTimer;

  bool _hasMore = true;
  bool _isLoading = false;
  bool _mostrarBusqueda = false;
  bool _mostrarScanner = false;
  bool _isProcessingScan = false;

  String _currentSearchQuery = '';
  int _searchSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreProducts(reset: true);
     
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text); 
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ✅ ESCANEO ACTUALIZADO: muestra TODOS los productos del código, no solo el primero
  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan || capture.barcodes.isEmpty) return;
    
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _isProcessingScan = true;
    
    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
      final productService = OdooProductService(odooService);
      
      // Busca TODOS los productos con ese código (no solo el primero)
      final productosEncontrados = await productService.getProductsByBarcode(code);
      
      if (productosEncontrados.isNotEmpty) {
        if (mounted) setState(() => _mostrarScanner = false);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        if (productosEncontrados.length > 1) {
          // Más de uno → mostrar lista para que el usuario elija
          _mostrarSelectorProductos(productosEncontrados, code);
        } else {
          // Solo uno → ir directo al detalle
          _mostrarDetalleProductoEscaneado(_buildArticuloFromProduct(productosEncontrados.first));
        }
      } else {
        // Fallback: buscar en la caché local cargada
        final productoCached = _allProducts.firstWhere(
          (p) => p.barcode == code || p.defaultCode == code,
          orElse: () => Product(id: -1, name: '', listPrice: 0.0, type: 'consu'),
        );
        
        if (productoCached.id != -1) {
          if (mounted) setState(() => _mostrarScanner = false);
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) _mostrarDetalleProductoEscaneado(_buildArticuloFromProduct(productoCached));
        } else {
          _mostrarMensajeError('Producto no encontrado con código: $code');
          if (mounted) setState(() => _mostrarScanner = false);
        }
      }
    } catch (e) {
      print('❌ Error en escaneo: $e');
      _mostrarMensajeError('Error al escanear: $e');
      if (mounted) setState(() => _mostrarScanner = false);
    } finally {
      _isProcessingScan = false;
    }
  }

  /// Convierte un Product en ArticuloItem aplicando impuestos
  ArticuloItem _buildArticuloFromProduct(Product product) {
    return ArticuloItem(
      id: product.id,
      nombre: product.name,
      categoria: product.categoryName ?? 'Sin categoría',
      subcategoria: product.typeDisplay,
      precio: _getPrecioConImpuesto(product),
      descripcion: product.description ?? product.name,
      cantidad: 1,
      tieneImpuestos: _tieneImpuestos(product),
    );
  }

  /// Cuando un código de barras devuelve varios productos, el usuario elige cuál quiere
  void _mostrarSelectorProductos(List<Product> productos, String codigoEscaneado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Código: $codigoEscaneado',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      '${productos.length} productos encontrados — selecciona uno:',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (ctx, index) {
                    final p = productos[index];
                    final precio = _getPrecioConImpuesto(p);
                    final tieneImpuestos = _tieneImpuestos(p);
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2, color: p.typeColor, size: 22),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.defaultCode != null && p.defaultCode!.isNotEmpty)
                            Text('Ref: ${p.defaultCode}', style: const TextStyle(fontSize: 12)),
                          if (p.categoryName != null)
                            Text(p.categoryName!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                          if (tieneImpuestos)
                            Text('+ITBIS',
                                style: TextStyle(fontSize: 10, color: Colors.orange[700])),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _mostrarDetalleProductoEscaneado(_buildArticuloFromProduct(p));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  double _getPrecioConImpuesto(Product product) {
    final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
    final tieneImpuestoCompra = product.supplierTaxesIds != null && 
                               product.supplierTaxesIds!.isNotEmpty;
    
    if (tieneImpuestos || tieneImpuestoCompra) {
      return product.listPrice; // ✅ ITBIS ya está incluido en Odoo
    }
    return product.listPrice;
  }

  bool _tieneImpuestos(Product product) {
    return (product.taxesIds != null && product.taxesIds!.isNotEmpty) ||
           (product.supplierTaxesIds != null && product.supplierTaxesIds!.isNotEmpty);
  }

  void _mostrarDetalleProductoEscaneado(ArticuloItem producto) async {
    try {
      // ✅ BUSCAR EL PRODUCTO COMPLETO EN ODDO PARA OBTENER TODOS LOS DATOS
      final odooService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      
      await odooService.login(
        ApiConfig.defaultUsername, 
        ApiConfig.defaultPassword
      );
      final productService = OdooProductService(odooService);
      
      final productDetails = await productService.getProductDetails(producto.id);
      
      if (productDetails != null) {
        // ✅ NAVEGACIÓN CON EL PRODUCTO COMPLETO
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailViewScreen(
                  articulo: producto,
                  product: productDetails, // ✅ PRODUCTO COMPLETO CON PRECIO BASE
                ),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isProcessingScan = false;
                });
              }
            });
          }
        });
      } else {
        // ✅ FALLBACK: Usar el producto de la lista o crear uno básico
        final product = _allProducts.firstWhere(
          (p) => p.id == producto.id,
          orElse: () => Product(
            id: producto.id,
            name: producto.nombre,
            defaultCode: '',
            // ✅ Odoo listPrice ya incluye el impuesto en esta configuración
            listPrice: producto.precio,
            type: producto.subcategoria == 'Servicio' ? 'service' : 'consu',
            categoryName: producto.categoria,
            description: producto.descripcion,
            taxesIds: producto.tieneImpuestos ? [1] : [],
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailViewScreen(
                  articulo: producto,
                  product: product,
                ),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isProcessingScan = false;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      print('❌ Error obteniendo detalles del producto: $e');
      // FALLBACK
      final product = _allProducts.firstWhere(
        (p) => p.id == producto.id,
        orElse: () => Product(
          id: producto.id,
          name: producto.nombre,
          defaultCode: '',
          listPrice: producto.precio,
          type: producto.subcategoria == 'Servicio' ? 'service' : 'consu',
          categoryName: producto.categoria,
          description: producto.descripcion,
          taxesIds: producto.tieneImpuestos ? [1] : [],
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailViewScreen(
                articulo: producto,
                product: product,
              ),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isProcessingScan = false;
              });
            }
          });
        }
      });
    }
  }

  // ✅ WIDGET DEL SCANNER MEJORADO
  Widget _buildScanner() {
    if (!_mostrarScanner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleScan,
            errorBuilder: (context, error, child) {
              return Center(
                child: Text('Error del scanner: $error', 
                  style: const TextStyle(color: Colors.white)),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.all(50),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                setState(() => _mostrarScanner = false);
              },
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                'Escaneando... Apunta al código de barras',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _performSearch(query);
    });
  }

  void _performSearch(String query) {
    _loadMoreProducts(reset: true, searchQuery: query);
  }

  Future<void> _loadMoreProducts({bool reset = false, String searchQuery = ''}) async {
    // Si no es un reset (es paginación) y ya estamos cargando, ignorar.
    if (_isLoading && !reset) return; 

    // Incrementar la secuencia para invalidar solicitudes anteriores
    final currentSeq = ++_searchSequence;
    
    setState(() {
      _isLoading = true;
      if (reset) {
        _allProducts.clear();
        _currentPage = 0;
        _hasMore = true;
        _currentSearchQuery = searchQuery;
      }
    });

    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      
      // ✅ USAR CREDENCIALES CORRECTAS
      await odooService.login(
        ApiConfig.defaultUsername, 
        ApiConfig.defaultPassword
      );
      final productService = OdooProductService(odooService);
      
      final result = await productService.getProductsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery,
      );

      // Solo actualizar si esta es la última búsqueda solicitada
      if (mounted && currentSeq == _searchSequence) {
        setState(() {
          if (reset) _allProducts.clear(); // Limpiar por si acaso
          _allProducts.addAll(result['products']);
          _hasMore = result['hasMore'];
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && currentSeq == _searchSequence) {
        setState(() => _isLoading = false);
      }
      _mostrarMensajeError('Error cargando productos: $e');
    }
  }

  void _onScroll(ScrollNotification scrollInfo) {
    if (_isLoading || !_hasMore) return;
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
      _loadMoreProducts(searchQuery: _currentSearchQuery);
    }
  }

  void _mostrarDetalleProducto(Product product) {
    // ✅ CALCULAR PRECIO CON IMPUESTOS
    final precioConImpuesto = _getPrecioConImpuesto(product);
    final tieneImpuestos = _tieneImpuestos(product);
    
    final articulo = ArticuloItem(
      id: product.id,
      nombre: product.name,
      categoria: product.categoryName ?? 'Sin categoría',
      subcategoria: product.typeDisplay,
      precio: precioConImpuesto, // ✅ USAR PRECIO CON IMPUESTOS
      descripcion: product.description ?? product.name,
      cantidad: 1,
      tieneImpuestos: tieneImpuestos, // ✅ GUARDAR ESTADO DE IMPUESTOS
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailViewScreen(
          articulo: articulo,
          product: product, // ✅ ESTE YA TIENE EL PRECIO BASE CORRECTO
        ),
      ),
    );
  }

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
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

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

  IconData _getProductIcon(String type) {
    switch (type) {
      case 'consu': return Icons.shopping_bag;
      case 'service': return Icons.design_services;
      case 'product': return Icons.inventory;
      default: return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _mostrarScanner 
                ? const Icon(Icons.qr_code_scanner, color: Colors.blue)
                : const Icon(Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _mostrarScanner = !_mostrarScanner;
                if (_mostrarScanner) {
                  _mostrarBusqueda = false;
                }
              });
            },
            tooltip: _mostrarScanner ? 'Cerrar escáner' : 'Escanear código para buscar',
          ),
          IconButton(
            icon: _mostrarBusqueda 
                ? const Icon(Icons.search, color: Colors.blue)
                : const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _mostrarBusqueda = !_mostrarBusqueda;
                if (_mostrarBusqueda) {
                  _mostrarScanner = false;
                }
                if (!_mostrarBusqueda) {
                  _searchController.clear();
                  _performSearch('');
                }
              });
            },
            tooltip: _mostrarBusqueda ? 'Cerrar búsqueda' : 'Buscar productos',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildScanner(),
        
        // Barra de búsqueda
        if (_mostrarBusqueda)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar productos...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      ),
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

        // Indicador de estado
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
                      return _buildProductoItem(product);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItem(Product product) {
    final tieneImpuestos = _tieneImpuestos(product);
    final precioConImpuesto = _getPrecioConImpuesto(product);

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: product.typeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getProductIcon(product.type),
            color: product.typeColor,
            size: 24,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500, 
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product.categoryName ?? 'Sin categoría',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.inventory, size: 12, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  product.isSellable ? "Disponible" : "No vendible",
                  style: TextStyle(
                    fontSize: 12,
                    color: product.isSellable ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (tieneImpuestos)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              const SizedBox(height: 4),
              Column(
                children: [
                  Text(
                    "\$${precioConImpuesto.toStringAsFixed(2)}",
                    style: const TextStyle(
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
          _mostrarDetalleProducto(product);
        },
      ),
    );
  }
}
