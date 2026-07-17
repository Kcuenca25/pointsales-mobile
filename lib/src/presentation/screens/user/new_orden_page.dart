import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart'; 
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/services/cache_service.dart';
import 'package:ecomerce_app/src/services/offline_order_service.dart';
import 'package:ecomerce_app/src/services/draft_order_service.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

class NuevaOrdenPage extends StatefulWidget {
  final Customer customer; 
  final User? usuario;
  final Function(Order, Customer, List<ArticuloItem>) onOrdenCreada;
  final bool clienteFijo; 

  const NuevaOrdenPage({
    super.key,
    required this.customer,
    this.usuario,
    this.clienteFijo = false,
    required this.onOrdenCreada,
  });

  @override
  State<NuevaOrdenPage> createState() => _NuevaOrdenPageState();
}

class _NuevaOrdenPageState extends State<NuevaOrdenPage>   with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
    facing: CameraFacing.back,
  );

  List<Product> _productosDisponibles = []; 

  String _estadoSeleccionado = "Pendiente";
  int _selectedIndex = 2;
  User? _selectedUser;
  Customer? _selectedCustomer; 
  bool _clienteBloqueado = false;
  bool _isProcessingScan = false;
  bool _mostrarScanner = false;
  bool _ordenGuardadaExitosamente = false; // ✅ NUEVA BANDERA
  
  //variables de animacion 
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late OdooProductService _productService;
  late OdooServiceEnhanced _odooService;
  List<ArticuloItem> _articulos = [];
  ArticuloItem? _currentArticulo;

  @override
  void initState() {
    super.initState();
    _initializeServices(); 
    _cargarBorrador();
    _clienteBloqueado = true; 
    _selectedCustomer = widget.customer;
    _cargarProductos();
    
    _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8), // Más lento
  );
  
    _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.0), // Posición inicial normal
    end: const Offset(-0.3, 0.0),  // Se mueve solo un poco a la izquierda
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  ));
  if (_currentArticulo != null) {
  // Usar _currentArticulo!
  print(_currentArticulo!.nombre);
}
  

      // LIMPIAR BORRADOR SI VIENE DESDE ORDEN DE COMPRA (sin usuario)
    if (widget.usuario == null) {
      _limpiarDraft();
    }

    if (widget.usuario != null) {
      // Si viene desde Cliente
      _selectedUser = widget.usuario;
      _clienteBloqueado = true;
    } else if (OrderDraftState.hasDraft && OrderDraftState.draftUser != null) {
      // Si hay borrador y viene desde Orden de compra
      _selectedUser = OrderDraftState.draftUser;
      _clienteBloqueado = _selectedUser != null;
      _articulos = List<ArticuloItem>.from(OrderDraftState.draftArticulos);
      _actualizarTotal();
    }
  }
void _initializeServices() {
  // Inicializa el servicio de Odoo para ventas
  _odooService = OdooServiceEnhanced(
    baseUrl: ApiConfig.baseUrl, 
    dbName: ApiConfig.dbName,
  );
  
  _productService = OdooProductService(_odooService);
}
Future<void> _cargarBorrador() async {
  try {
    await DraftOrderService.instance.init();
    
    // ✅ USAR EL MÉTODO ASYNC Y ESPERAR CON AWAIT
    final drafts = await DraftOrderService.instance.getAllDrafts();
    
    if (drafts.isEmpty) return;
    
    // Buscar borrador para este cliente
    final draftForCustomer = drafts
        .where((draft) => draft.type == OrderType.venta && 
                         draft.customer?.id == widget.customer.id)
        .firstOrNull;
    
    // ✅ VERIFICACIÓN COMPLETA
    if (draftForCustomer != null && draftForCustomer.articulos.isNotEmpty) {
      setState(() {
        _articulos = List<ArticuloItem>.from(draftForCustomer.articulos);
        _actualizarTotal();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Borrador cargado para ${widget.customer.name}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('❌ Error cargando borrador: $e');
  }
}

// ✅ CORREGIDO: Cambiar el tipo de retorno
Future<ArticuloItem?> _buscarProductoPorCodigoQR(String codigoQR) async {
  print('🔍 Buscando producto con código: $codigoQR');
  
  try {
    // ✅ PRIMERO BUSCAR EN ODDO EN TIEMPO REAL
    await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    final product = await _productService.getProductByBarcode(codigoQR);
    
    if (product == null) {
      // ✅ SI NO SE ENCUENTRA POR BARCODE, BUSCAR POR DEFAULT_CODE
      final products = await _productService.searchProducts(codigoQR, limit: 1);
      if (products.isNotEmpty) {
        final foundProduct = products.first;
        
        final precioConImpuesto = _getPrecioConImpuestoVentas(foundProduct);
        final tieneImpuestos = _tieneImpuestosVentas(foundProduct);
        
        print('✅ Producto encontrado por default_code: ${foundProduct.name}');
        
        return ArticuloItem(
          id: foundProduct.id,
          nombre: foundProduct.name,
          categoria: foundProduct.categoryName ?? 'Sin categoría',
          subcategoria: foundProduct.typeDisplay,
          precio: precioConImpuesto,
          descripcion: foundProduct.description ?? foundProduct.name,
          cantidad: 1,
          imagen: 'default_product',
          rating: 4.0,
          reviews: 0,
          tieneImpuestos: tieneImpuestos,
        );
      }
      
      print('❌ Producto no encontrado para código: $codigoQR');
      return null;
    }
    
    // ✅ PRODUCTO ENCONTRADO POR BARCODE
    print('✅ Producto encontrado por barcode: ${product.name}');
    
    final precioConImpuesto = _getPrecioConImpuestoVentas(product);
    final tieneImpuestos = _tieneImpuestosVentas(product);
    
    return ArticuloItem(
      id: product.id,
      nombre: product.name,
      categoria: product.categoryName ?? 'Sin categoría',
      subcategoria: product.typeDisplay,
      precio: precioConImpuesto,
      descripcion: product.description ?? product.name,
      cantidad: 1,
      imagen: 'default_product',
      rating: 4.0,
      reviews: 0,
      tieneImpuestos: tieneImpuestos,
    );
    
  } catch (e) {
    print('❌ Error buscando producto: $e');
    
    // ✅ FALLBACK: BUSCAR EN PRODUCTOS DISPONIBLES
    final product = _productosDisponibles.firstWhere(
      (p) => p.barcode == codigoQR || p.defaultCode == codigoQR,
      orElse: () => Product(
        id: -1,
        name: '',
        defaultCode: '',
        listPrice: 0.0,
        type: 'consu',
      ),
    );

    if (product.id == -1) {
      return null;
    }

    final precioConImpuesto = _getPrecioConImpuestoVentas(product);
    final tieneImpuestos = _tieneImpuestosVentas(product);
    
    return ArticuloItem(
      id: product.id,
      nombre: product.name,
      categoria: product.categoryName ?? 'Sin categoría',
      subcategoria: product.typeDisplay,
      precio: precioConImpuesto,
      descripcion: product.description ?? product.name,
      cantidad: 1,
      imagen: 'default_product',
      rating: 4.0,
      reviews: 0,
      tieneImpuestos: tieneImpuestos,
    );
  }
}
// ✅ AGREGAR ESTA FUNCIÓN EN NuevaOrdenPage
double _getPrecioConImpuestoVentas(Product product) {
  final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
  
  print('🔍 _getPrecioConImpuestoVentas para: ${product.name}');
  print('   Precio base: \$${product.listPrice}');
  print('   Tiene impuestos: $tieneImpuestos');
  
  if (tieneImpuestos) {
    final precioConImpuesto = product.listPrice;
    print('   ✅ ITBIS ya incluido en BD: \$${precioConImpuesto.toStringAsFixed(2)}');
    return precioConImpuesto;
  }
  
  print('   ⚠️ Sin impuestos: \$${product.listPrice}');
  return product.listPrice;
}

// ✅ También agrega esta función auxiliar
bool _tieneImpuestosVentas(Product product) {
  return product.taxesIds != null && product.taxesIds!.isNotEmpty;
}



void _handleScan(BarcodeCapture capture) async {
  if (_isProcessingScan || capture.barcodes.isEmpty) return;
  
  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  _isProcessingScan = true;
  
  try {
    print('🔍 Código escaneado en VENTAS: $code');
    
    // ✅ USAR EL SERVICIO LOCAL INICIALIZADO
    await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // ✅ BUSCAR EN TIEMPO REAL EN ODDO
    Product? productRealTime = await _productService.getProductByBarcode(code);
    
    if (productRealTime != null) {
      // ✅ OBTENER DETALLES COMPLETOS
      final productDetails = await _productService.getProductDetails(productRealTime.id);
      
      if (productDetails != null) {
        productRealTime = productDetails;
      }
      
      print('🔍 Producto escaneado en VENTAS: ${productRealTime.name}');
      
      // ✅ USAR LA FUNCIÓN _getPrecioConImpuestoVentas
      final precioConImpuesto = _getPrecioConImpuestoVentas(productRealTime);
      final tieneImpuestos = _tieneImpuestosVentas(productRealTime);
      
      final articuloActualizado = ArticuloItem(
        id: productRealTime.id,
        nombre: productRealTime.name,
        categoria: productRealTime.categoryName ?? 'Sin categoría',
        subcategoria: productRealTime.typeDisplay,
        precio: precioConImpuesto,
        descripcion: productRealTime.description ?? productRealTime.name,
        cantidad: 1,
        tieneImpuestos: tieneImpuestos,
      );
      
      print('💰 Articulo creado:');
      print('   Precio final: \$${articuloActualizado.precio.toStringAsFixed(2)}');
      print('   Tiene impuestos: ${articuloActualizado.tieneImpuestos}');
      
      _mostrarDetalleProductoEscaneado(articuloActualizado);
    } else {
      // ✅ FALLBACK a búsqueda local
      print('⚠️ No encontrado por barcode, buscando por default_code...');
      final products = await _productService.searchProducts(code, limit: 1);
      
      if (products.isNotEmpty) {
        final product = products.first;
        final precioConImpuesto = _getPrecioConImpuestoVentas(product);
        final tieneImpuestos = _tieneImpuestosVentas(product);
        
        final articulo = ArticuloItem(
          id: product.id,
          nombre: product.name,
          categoria: product.categoryName ?? 'Sin categoría',
          subcategoria: product.typeDisplay,
          precio: precioConImpuesto,
          descripcion: product.description ?? product.name,
          cantidad: 1,
          tieneImpuestos: tieneImpuestos,
        );
        
        print('💰 Articulo desde búsqueda:');
        print('   Precio final: \$${articulo.precio.toStringAsFixed(2)}');
        
        _mostrarDetalleProductoEscaneado(articulo);
      } else {
        // ✅ ÚLTIMO FALLBACK: buscar en productos disponibles en caché
        final productoCached = _productosDisponibles.firstWhere(
          (p) => p.barcode == code || p.defaultCode == code,
          orElse: () => Product(
            id: -1,
            name: '',
            listPrice: 0.0,
            type: 'consu',
          ),
        );
        
        if (productoCached.id != -1) {
          final precioConImpuesto = _getPrecioConImpuestoVentas(productoCached);
          final tieneImpuestos = _tieneImpuestosVentas(productoCached);
          
          final articulo = ArticuloItem(
            id: productoCached.id,
            nombre: productoCached.name,
            categoria: productoCached.categoryName ?? 'Sin categoría',
            subcategoria: productoCached.typeDisplay,
            precio: precioConImpuesto,
            descripcion: productoCached.description ?? productoCached.name,
            cantidad: 1,
            tieneImpuestos: tieneImpuestos,
          );
          
          _mostrarDetalleProductoEscaneado(articulo);
        } else {
          _mostrarMensajeError('❌ Producto no encontrado con código: $code');
        }
      }
    }
  } catch (e) {
    print('❌ Error en escaneo VENTAS: $e');
    _mostrarMensajeError('Error al escanear: $e');
  } finally {
    _isProcessingScan = false;
    setState(() => _mostrarScanner = false);
  }
}


// ✅ Método auxiliar para mostrar mensajes de error
void _mostrarMensajeError(String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ),
  );
}



void _mostrarDetalleProductoEscaneado(ArticuloItem producto) {
  final cantidadExistente = _articulos
      .where((a) => a.id == producto.id)
      .fold(0, (sum, a) => sum + a.cantidad);

  // ✅ BUSCAR EL PRODUCTO CORRESPONDIENTE EN LA LISTA DE ODDO
  final product = _productosDisponibles.firstWhere(
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

  // ✅ PASAR EL PRODUCTO ACTUALIZADO CON LOS IMPUESTOS APLICADOS
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailScreen(
        articulo: producto, // ✅ ESTE YA TIENE EL PRECIO CON IMPUESTOS
        product: product,
        cantidadInicial: cantidadExistente,
        onAgregarArticulo: (articulo, cantidad) {
          _agregarArticulo(articulo, cantidad);
        },
        esParaVenta: true,
      ),
    ),
  );
}

Future<void> _cargarProductos() async {
  try {
    // ✅ USAR EL SERVICIO LOCAL INICIALIZADO
    await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // ✅ VERIFICAR SI DEBE ACTUALIZARSE
    final shouldRefresh = await CacheService.shouldRefreshProducts();
    List<Product> products;
    
    if (shouldRefresh) {
      print('🔄 Actualizando productos (cache expirado)...');
      products = await _productService.getProducts(limit: 200);
    } else {
      print('📦 Usando productos en caché...');
      products = await CacheService.getCachedProducts();
      
      // ✅ SI CACHÉ ESTÁ VACÍO, CARGAR DE TODOS MODOS
      if (products.isEmpty) {
        products = await _productService.getProducts(limit: 200);
      }
    }
    
    setState(() {
      _productosDisponibles = products;
    });
    
    print('✅ Productos cargados para ventas: ${products.length}');
    
  } catch (e) {
    print('❌ Error cargando productos: $e');
    // Fallback a caché
    final cachedProducts = await CacheService.getCachedProducts();
    setState(() {
      _productosDisponibles = cachedProducts;
    });
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _totalController.dispose();
    _scannerController.dispose();
     // ✅ SOLO guardar borrador si la orden NO fue guardada exitosamente
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_articulos.isNotEmpty && !_ordenGuardadaExitosamente) {
      _guardarBorrador();
    }
  });
    super.dispose();
  }


 Widget _buildAnimatedTitle(String titulo, String subtitulo) {
  final bool isLongTitle = titulo.length > 25;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Para títulos largos, no usar animación para mejor legibilidad
      if (isLongTitle)
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
      else
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Stack(
            children: [
              SlideTransition(
                position: _offsetAnimation,
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      
      // Subtítulo con el email
      if (subtitulo.isNotEmpty)
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
    ],
  );
}

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filtros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(
                        title: 'Estado',
                        children: [
                          _buildFilterCheckbox("Todas", _estadoSeleccionado == "Todas",
                              (value) => setState(() => _estadoSeleccionado = "Todas")),
                          _buildFilterCheckbox("Pendiente", _estadoSeleccionado == "Pendiente",
                              (value) => setState(() => _estadoSeleccionado = "Pendiente")),
                          _buildFilterCheckbox("Pagada", _estadoSeleccionado == "Pagada",
                              (value) => setState(() => _estadoSeleccionado = "Pagada")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aplicar"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  Widget _buildFilterSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  void _agregarArticulo(ArticuloItem articulo, int cantidad) {
  setState(() {
    final existingIndex = _articulos.indexWhere((a) => a.id == articulo.id);
    if (existingIndex >= 0) {
      // Si ya existe, actualiza la cantidad pero NO cambia la posición
      _articulos[existingIndex].cantidad += cantidad;
    } else {
      // Agrega el nuevo artículo al INICIO de la lista
      _articulos.insert(0, ArticuloItem(
        id: articulo.id,
        nombre: articulo.nombre,
        categoria: articulo.categoria,
        subcategoria: articulo.subcategoria,
        cantidad: cantidad,
        precio: articulo.precio,
        descripcion: articulo.descripcion,
      ));
    }
    _actualizarTotal();
    _guardarDraft();
     _guardarBorrador(); 
  });
}

  void _eliminarArticulo(int index) {
    setState(() {
      _articulos.removeAt(index);
      _actualizarTotal();
      _guardarDraft();
        _guardarBorrador();
    });
  }
Future<void> _guardarBorrador() async {
  // ✅ NO GUARDAR si la orden ya fue guardada exitosamente
  if (_ordenGuardadaExitosamente) {
    return;
  }
  
  if (_articulos.isEmpty) {
    // Si no hay artículos, eliminar cualquier borrador existente
    final draftId = 'venta_${widget.customer.id}';
    await DraftOrderService.instance.deleteDraft(draftId);
    return;
  }
  
  // ✅ Asegurarse de que total está calculado
  final total = _calculateTotal();
  
  final draft = DraftOrder(
    id: 'venta_${widget.customer.id}',
    type: OrderType.venta,
    createdAt: DateTime.now(),
    customer: widget.customer,
    articulos: List<ArticuloItem>.from(_articulos),
    total: total,
  );
  
  await DraftOrderService.instance.saveDraft(draft);
  print('💾 Borrador guardado para ${widget.customer.name}');
}

double _calculateTotal() {
  return _articulos.fold(0.0, (sum, articulo) {
    return sum + (articulo.precio * articulo.cantidad);
  });
}

// ✅ AL CERRAR LA ORDEN (crear orden completa)
void _crearOrden() async {
  try {
    // ... código para crear orden ...
    
    // ✅ ELIMINAR BORRADOR DESPUÉS DE CREAR LA ORDEN
    final draftId = 'venta_${widget.customer.id}';
    await DraftOrderService.instance.deleteDraft(draftId);
    
  } catch (e) {
    // ... manejo de error ...
  }
}


  void _actualizarCantidad(int index, int nuevaCantidad) {
  setState(() {
    if (nuevaCantidad < 1) {
      // Si la cantidad sería 0 o menos, eliminar el artículo
      _eliminarArticulo(index);
    } else {
      _articulos[index].cantidad = nuevaCantidad;
      _actualizarTotal();
      _guardarDraft();
       _guardarBorrador(); 
    }
  });
}


  void _actualizarTotal() {
    double total = 0;
    for (var a in _articulos) total += a.precio * a.cantidad;
    _totalController.text = total.toStringAsFixed(2);
  }

  void _guardarDraft() {
    if (_selectedUser != null || _articulos.isNotEmpty) {
      OrderDraftState.hasDraft = true;
      OrderDraftState.draftUser = _selectedUser;
      OrderDraftState.draftArticulos = List<ArticuloItem>.from(_articulos);
    }
  }

  void _limpiarDraft() {
    OrderDraftState.hasDraft = false;
    OrderDraftState.draftUser = null;
    OrderDraftState.draftArticulos = [];
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(initialIndex: index)),
      );
    }
  }
  

  void _mostrarSelectorArticulosCompleto() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ArticuloSelectorScreen(
        onArticuloAgregado: (articulo, cantidad) {
          _agregarArticulo(articulo, cantidad);
        },
        onArticuloEliminado: (articulo) {
          // ✅ Eliminar el artículo de la lista
          setState(() {
            _articulos.removeWhere((a) => a.id == articulo.id);
            _actualizarTotal();
            _guardarDraft();
          });
        },
        articulosSeleccionadosIniciales: _articulos,
      ),
    ),
  );
}


  Widget _buildCantidadSelector(int index) {
  final articulo = _articulos[index];
  final bool mostrarEliminar = articulo.cantidad == 1;
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Botón para disminuir cantidad o eliminar
      GestureDetector(
        onTap: () => _actualizarCantidad(index, articulo.cantidad - 1),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300], 
            shape: BoxShape.circle
          ),
          child: Icon(
            mostrarEliminar ? Icons.delete : Icons.remove,
            size: 18,
            color: mostrarEliminar ? Colors.red : Colors.black,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey), 
          borderRadius: BorderRadius.circular(4)
        ),
        child: Text(
          articulo.cantidad.toString(), 
          style: const TextStyle(fontSize: 16)
        ),
      ),
      GestureDetector(
        onTap: () => _actualizarCantidad(index, articulo.cantidad + 1),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300], 
            shape: BoxShape.circle
          ),
          child: const Icon(Icons.add, size: 18),
        ),
      ),
    ],
  );
}  Widget _buildArticuloItem(int index) {
  final articulo = _articulos[index];
  
  // Widget para el contenido del artículo
  Widget contenidoArticulo = Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200], 
              borderRadius: BorderRadius.circular(8)
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articulo.nombre, 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                Text(
                  articulo.categoria, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                ),
                Text(
                  "\$${articulo.precio.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.green
                  ),
                ),
              ],
            ),
          ),
          _buildCantidadSelector(index),
        ],
      ),
    ),
  );

  return Dismissible(
    key: Key(articulo.id.toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white, size: 30),
    ),
    confirmDismiss: (direction) async {
      return await _mostrarConfirmacionEliminar(context);
    },
    onDismissed: (direction) {
      _eliminarArticulo(index);
    },
    child: contenidoArticulo,
  );
}


Future<bool> _mostrarConfirmacionEliminar(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Eliminar artículo"),
        content: const Text("¿Estás seguro de que quieres eliminar este artículo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  ) ?? false;
}

// 🔴 MÉTODO PARA MOSTRAR DIÁLOGO SIN CONEXIÓN 
void _mostrarDialogoSinConexion() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange),
          SizedBox(width: 10),
          Text("Sin Conexión"),
        ],
      ),
      content: const Text(
        "No hay conexión a internet disponible. "
        "Conectate a WiFi o activa tus datos móviles para crear órdenes.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Entendido"),
        ),
      ],
    ),
  );
}

//  MÉTODO PARA GUARDAR ONLINE (CORREGIDO)
// En el método _guardarOrdenOnline(), verificar si el cliente existe
Future<void> _guardarOrdenOnline() async {
  if (_articulos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Agregue al menos un artículo"))
    );
    return;
  }
  
  // ✅ VERIFICAR QUE EL CLIENTE EXISTE
  if (_selectedCustomer == null || _selectedCustomer!.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("❌ Error: Cliente no válido"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  double totalPagar = _articulos.fold(0, (sum, articulo) => sum + (articulo.precio * articulo.cantidad));
  
  // MOSTRAR LOADING
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 1. VERIFICAR QUE EL CLIENTE EXISTE EN ODDO
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // Verificar si el cliente existe
    try {
      final clienteExiste = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'res.partner',
          'search_count',
          [
            [['id', '=', _selectedCustomer!.id!]]
          ]
        ],
      });
      
      if (clienteExiste == 0) {
        throw Exception('Cliente ID ${_selectedCustomer!.id} no existe en Odoo');
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: Cliente no existe en el sistema: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 2. PREPARAR DATOS PARA ODDO
    final orderLines = _articulos.map((articulo) {
      return {
        'product_id': articulo.id,
        'quantity': articulo.cantidad,
        'price_unit': articulo.precio,
      };
    }).toList();

    // 3. CREAR ORDEN EN ODDO
    final orderService = OdooOrderService(odooService);
    
    final result = await orderService.createSaleOrder(
      partnerId: _selectedCustomer!.id!,
      orderLines: orderLines,
    );

    // 4. CERRAR LOADING
    Navigator.pop(context);

    if (result['success'] == true) {
      print('🎉 Orden creada exitosamente en Odoo - ID: ${result['order_id']}');
      
      // 5. CREAR ORDEN LOCAL PARA LA APP
      final nuevaOrden = Order(
        id: result['order_id'].toString(),
        date: DateTime.now(),
        total: totalPagar,
        status: 'sale', // ✅ CAMBIADO: Marcar como confirmada, no como borrador
      );

      // 6. ELIMINAR BORRADOR DESPUÉS DE CREAR LA ORDEN
      final draftId = 'venta_${widget.customer.id}';
      await DraftOrderService.instance.deleteDraft(draftId);
      
      // 7. MARCAR COMO EXITOSA PARA NO VOLVER A GUARDAR BORRADOR
      setState(() {
        _ordenGuardadaExitosamente = true;
      });
      
      // 8. NOTIFICAR Y CERRAR
      widget.onOrdenCreada(nuevaOrden, _selectedCustomer!, _articulos);
      _limpiarDraft();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Orden creada exitosamente"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${result['error']}"),
          backgroundColor: Colors.red,
        ),
      );
    }
    
  } catch (e) {
    Navigator.pop(context); // Cerrar loading
    print('❌ Error creando orden: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


// 🔴 MÉTODO PARA GUARDAR OFFLINE
Future<void> _guardarOrdenOffline() async {
  if (_articulos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Agregue al menos un artículo")));
    return;
  }

  try {
    // CALCULAR TOTAL
    double totalPagar = _articulos.fold(0, (sum, articulo) => sum + (articulo.precio * articulo.cantidad));
    
    // Preparar datos para guardar offline
    final orderLines = _articulos.map((articulo) {
      return {
        'product_id': articulo.id,
        'product_name': articulo.nombre,
        'quantity': articulo.cantidad,
        'price_unit': articulo.precio,
      };
    }).toList();

    // Guardar en almacenamiento offline
    await OfflineOrderService.saveOrderOffline(
      partnerId: _selectedCustomer!.id!,
      partnerName: _selectedCustomer!.name,
      orderLines: orderLines,
      total: totalPagar,
    );

    // ✅ MARCAR COMO EXITOSA PARA NO VOLVER A GUARDAR BORRADOR
    setState(() {
      _ordenGuardadaExitosamente = true;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Orden guardada offline - Se sincronizará automáticamente cuando haya conexión"),
        duration: Duration(seconds: 4),
      ),
    );
    
    // Limpiar y cerrar
    _limpiarDraft();
    Navigator.pop(context);
    
  } catch (e) {
    print('❌ Error guardando orden offline: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error guardando orden offline: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget _buildBottomStaticSection() {
  int totalArticulos = _articulos.fold(0, (sum, articulo) => sum + articulo.cantidad);
  double totalPagar = _articulos.fold(0, (sum, articulo) => sum + (articulo.precio * articulo.cantidad));
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Fila compacta de totales
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total de artículos
            Row(
              children: [
                const Icon(Icons.shopping_basket, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '$totalArticulos artículos',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            
            // Total a pagar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total a pagar:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '\$${totalPagar.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
          onPressed: () async {
           //  VERIFICAR CONEXIÓN ANTES DE GUARDAR
          final tieneInternet = await ConnectivityService.hasInternet();
  
          if (!tieneInternet) {
           // 🔴 MODO SIN CONEXIÓN - Guardar offline
          await _guardarOrdenOffline();
         return;
      }
  
  // ✅ MODO CON CONEXIÓN - Guardar online
  await _guardarOrdenOnline();
},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 6),
                Text(
                  'Guardar Orden',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
       String titulo = "Nueva orden de ${_selectedCustomer?.name ?? 'Cliente'}";
    String subtitulo = _selectedCustomer?.email ?? "";


     return WillPopScope(
      onWillPop: () async {
        _guardarDraft();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Orden guardada como borrador"), duration: Duration(seconds: 2)),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildAnimatedTitle(titulo, subtitulo),
                ),
              ),
            ],
          ),
          toolbarHeight: 100,
          actions: [
            if (widget.usuario == null && _selectedUser != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: _desbloquearCliente,
                  tooltip: 'Cambiar cliente',
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _abrirFiltros,
              ),
            ),
          ],
        ),
        drawer: AppDrawer(onItemTapped: _onItemTapped),
        body: Column(
          children: [
            // Sección superior FIJA (botones y título)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  
                      
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text("Seleccionar Artículos"),
                            onPressed: _mostrarSelectorArticulosCompleto,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.document_scanner),
                          onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                   if (_mostrarScanner)
  Container(
    margin: const EdgeInsets.symmetric(vertical: 10), // Menos margen vertical
    height: MediaQuery.of(context).size.height * 0.35, // 35% de la altura de la pantalla
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: MobileScanner(controller: _scannerController, onDetect: _handleScan),
  ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            
            // Sección media con SCROLL (solo productos)
            Expanded(
              child: _articulos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No hay artículos seleccionados", 
                        style: TextStyle(color: Colors.grey, fontSize: 16)
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: List.generate(_articulos.length, _buildArticuloItem),
                  ),
            ),
            
            // Sección inferior FIJA (totales y botón)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _buildBottomStaticSection(),
            ),
          ],
        ),
        
        
      ),
    );
  }

  // Método para desbloquear cliente (descomenta este método)
void _desbloquearCliente() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cambiar cliente'),
      content: const Text('¿Estás seguro de que quieres cambiar de cliente? Se perderán los artículos seleccionados.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            // ✅ ELIMINAR BORRADOR DEL CLIENTE ACTUAL
            final draftId = 'venta_${widget.customer.id}';
            await DraftOrderService.instance.deleteDraft(draftId);
            
            setState(() {
              _selectedUser = null;
              _clienteBloqueado = false;
              _articulos.clear();
              _actualizarTotal();
            });
            _limpiarDraft();
            Navigator.pop(context);
          },
          child: const Text('Cambiar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
  // ✅ AL SALIR DE LA PANTALLA
}
