
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/services/draft_order_service.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'package:ecomerce_app/src/services/odoo_purchase_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/config/api_config.dart';


class CrearOrdenCompraScreen extends StatefulWidget {
  final Customer  proveedor;
    final Function(PurchaseOrder, Customer , List<ArticuloItem>) onOrdenCreada;


  const CrearOrdenCompraScreen({
    super.key,
    required this.proveedor,
    required this.onOrdenCreada, 
  });

  @override
  State<CrearOrdenCompraScreen> createState() => _CrearOrdenCompraScreenState();
}

class _CrearOrdenCompraScreenState extends State<CrearOrdenCompraScreen> {
  final List<Map<String, dynamic>> _productosAgregados = [];
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarBusqueda = false;
  bool _isLoading = false;
  String _fechaEntrega = '';
  String _notas = '';
  bool _mostrarScanner = false;
  bool _isProcessingScan = false;

  List<Product> _productosFiltrados = [];
  List<Product> _productosDisponibles = []; // ← ESTA FALTABA


  late MobileScannerController _scannerController;

  late OdooPurchaseService _purchaseService;
  late OdooProductService _productService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fechaEntrega = _getDefaultDeliveryDate();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.qrCode, BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.code128],
    facing: CameraFacing.back,
  );
    _fechaEntrega = _getDefaultDeliveryDate();
    _cargarProductosIniciales();
    _cargarBorrador();

  }

  

@override
void dispose() {
  _scannerController.dispose();
  if (_productosAgregados.isNotEmpty) {
    _guardarBorrador();
  }
  super.dispose();
}

Future<void> _cargarBorrador() async {
  try {
    print('🔄 Intentando cargar borrador para proveedor ID: ${widget.proveedor.id}');
    
    await DraftOrderService.instance.init();
    
    final drafts = await DraftOrderService.instance.getAllDrafts();
    
    if (drafts.isEmpty) {
      print('📭 No se encontraron borradores');
      return;
    }
    
    print('📋 Revisando ${drafts.length} borradores');
    
    // Buscar borrador para este proveedor
    DraftOrder? draftForProveedor;
    
    for (var draft in drafts) {
      print('   - Borrador: ${draft.id}, Tipo: ${draft.type}, Proveedor: ${draft.proveedor?['id']}');
      
      if (draft.type == OrderType.compra) {
        final proveedorId = draft.proveedor?['id'];
        if (proveedorId == widget.proveedor.id) {
          draftForProveedor = draft;
          print('   ✅ ¡Borrador encontrado!');
          break;
        }
      }
    }
    
    // ✅ USAR EL OPERADOR ?. PARA ACCESO SEGURO
    if (draftForProveedor?.articulos?.isNotEmpty ?? false) {
      final articulos = draftForProveedor!.articulos!;
      
      setState(() {
        // Limpiar la lista actual
        _productosAgregados.clear();
        
        // Agregar los productos del borrador
        for (var articulo in articulos) {
          _productosAgregados.add({
            'id': articulo.id,
            'nombre': articulo.nombre,
            'categoria': articulo.categoria,
            'subcategoria': articulo.subcategoria,
            'precio': articulo.precio,
            'descripcion': articulo.descripcion,
            'cantidad': articulo.cantidad,
            'subtotal': articulo.precio * articulo.cantidad,
            'tiene_impuesto': articulo.tieneImpuestos ?? false,
          });
        }
      });
      
      // Cargar notas con operador ?.
      final notas = draftForProveedor.notas;
      if (notas != null && notas.isNotEmpty) {
        _notas = notas;
      }
      
      // Cargar fecha con operador ?.
      final fecha = draftForProveedor.fechaEntrega;
      if (fecha != null && fecha.isNotEmpty) {
        _fechaEntrega = fecha;
      }
      
      print('✅ Borrador cargado: ${articulos.length} productos');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Borrador cargado para ${widget.proveedor.name} (${articulos.length} productos)'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      print('📭 No se encontró borrador para este proveedor o está vacío');
    }
  } catch (e) {
    print('❌ Error cargando borrador de compra: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cargar borrador: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


Future<void> _guardarBorrador() async {
  if (_productosAgregados.isEmpty) {
    // Si no hay productos, eliminar cualquier borrador existente
    final draftId = 'compra_${widget.proveedor.id}';
    await DraftOrderService.instance.deleteDraft(draftId);
    return;
  }
  
  final articulos = _productosAgregados.map((producto) {
    return ArticuloItem(
      id: producto['id'] ?? 0,
      nombre: producto['nombre'] ?? 'Producto',
      categoria: producto['categoria'] ?? 'Sin categoría',
      subcategoria: producto['subcategoria'] ?? 'Producto',
      precio: (producto['precio'] ?? 0.0).toDouble(),
      descripcion: producto['descripcion'] ?? '',
      cantidad: producto['cantidad'] ?? 1,
      tieneImpuestos: producto['tiene_impuesto'] ?? false,
    );
  }).toList();
  
  final draft = DraftOrder(
    id: 'compra_${widget.proveedor.id}',
    type: OrderType.compra,
    createdAt: DateTime.now(),
    proveedor: {
      'id': widget.proveedor.id,
      'name': widget.proveedor.name,
      'email': widget.proveedor.email,
      'vat': widget.proveedor.vat,
    },
    articulos: articulos,
    total: _calculateTotal(),
    notas: _notas,
    fechaEntrega: _fechaEntrega,
  );
  
  await DraftOrderService.instance.saveDraft(draft);
  print('💾 Borrador de compra guardado para ${widget.proveedor.name}');
}


  void _initializeServices() {
    final companyService = CompanyService();
    
    // ✅ USAR LA MISMA INSTANCIA DE ODDO SERVICE
    final odooService = companyService.odooService;
    
    if (odooService != null) {
      _purchaseService = OdooPurchaseService(odooService);
      _productService = OdooProductService(odooService);
    } else {
      // Fallback si no está inicializado
      final fallbackService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: 'pointsales-v18',
      );
      _purchaseService = OdooPurchaseService(fallbackService);
      _productService = OdooProductService(fallbackService);
    }
  }

  String _getDefaultDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 7));
    return '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
  }

  // 🎯 DISEÑO MEJORADO - APP BAR
  @override
Widget build(BuildContext context) {
  final total = _calculateTotal();

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text(
        'Crear Orden de Compra',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: const Color(0xFF583F80),
      actions: [        
        if (_productosAgregados.isNotEmpty)
        Chip(
    label: Text('${_productosAgregados.length} productos'),
    backgroundColor: Colors.blue,
    labelStyle: TextStyle(color: Colors.white),
  ),
          IconButton(
            icon: Badge(
              label: Text('${_productosAgregados.length}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: _showCartDetails,
            tooltip: 'Ver productos agregados',
          ),
      ],
    ),
    body: _buildContent(total),
    bottomNavigationBar: _productosAgregados.isNotEmpty
        ? _buildBottomBar(total)
        : null,
  );
}
Future<int?> _obtenerIdProveedorLMH() async {
  try {
    final result = await _purchaseService.odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        _purchaseService.odooService.dbName,
        _purchaseService.odooService.uid,
        _purchaseService.odooService.password,
        'res.partner',
        'search_read',
        [
          [
            ['name', 'ilike', 'lmh'],
            ['company_type', '=', 'company']
          ]
        ],
        {
          'fields': ['id', 'name'],
          'limit': 1
        }
      ],
    });

    final proveedores = (result as List).cast<Map<String, dynamic>>();
    if (proveedores.isNotEmpty) {
      return proveedores.first['id'];
    }
    return null;
  } catch (e) {
    print('❌ Error buscando L.M.H: $e');
    return null;
  }
}
// 🎯 MÉTODO PARA CARGAR PRODUCTOS AL INICIAR
Future<void> _cargarProductosIniciales() async {
  try {
    setState(() => _isLoading = true);
    
    // Cargar algunos productos para búsqueda rápida
    final productos = await _productService.getProducts(limit: 50);
    
    setState(() {
      _productosDisponibles = productos;
      _isLoading = false;
    });
    
    print('✅ Productos cargados: ${productos.length}');
  } catch (e) {
    setState(() => _isLoading = false);
    print('❌ Error cargando productos: $e');
  }
}

void _handleScan(BarcodeCapture capture) async {
  if (_isProcessingScan || capture.barcodes.isEmpty) return;
  
  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  _isProcessingScan = true;
  
  try {
    print('🔍 Código escaneado en COMPRAS: $code');
    
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    final productService = OdooProductService(odooService);
    
    Product? productRealTime = await productService.getProductByBarcode(code);
    
    if (productRealTime != null) {
      // ✅ OBTENER DETALLES COMPLETOS
      final productDetails = await productService.getProductDetails(productRealTime.id);
      
      if (productDetails != null) {
        productRealTime = productDetails;
      }
      
      // ✅ ✅ ✅ **CAMBIAR AQUÍ: USAR PRECIO BASE SIN IMPUESTOS**
      final tieneImpuestos = productRealTime.taxesIds != null && productRealTime.taxesIds!.isNotEmpty;
      final tieneImpuestoCompra = productRealTime.supplierTaxesIds != null && 
                                 productRealTime.supplierTaxesIds!.isNotEmpty;
      
      // ✅ **USAR EL PRECIO BASE DIRECTAMENTE (SIN AGREGAR IMPUESTOS)**
      double precioBase = productRealTime.listPrice;
      
      print('✅ Producto encontrado en COMPRAS:');
      print('   Nombre: ${productRealTime.name}');
      print('   Precio base (sin impuestos): \$${precioBase.toStringAsFixed(2)}');
      print('   Tiene impuestos venta: $tieneImpuestos');
      print('   Tiene impuestos compra: $tieneImpuestoCompra');
      
      final articulo = ArticuloItem(
        id: productRealTime.id,
        nombre: productRealTime.name,
        categoria: productRealTime.categoryName ?? 'Sin categoría',
        subcategoria: productRealTime.typeDisplay,
        precio: precioBase, // ✅ PRECIO SIN IMPUESTOS
        descripcion: productRealTime.description ?? productRealTime.name,
        cantidad: 1,
        tieneImpuestos: tieneImpuestos || tieneImpuestoCompra,
      );
      
      // ✅ AGREGAR A LA LISTA DE PRODUCTOS DE LA PANTALLA ACTUAL
      _agregarProductoDesdeScannerAListaTemporal(articulo);
      
    } else {
      // ✅ FALLBACK - Buscar en productos disponibles
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
        final productDetails = await productService.getProductDetails(productoCached.id);
        Product productoFinal = productoCached;
        
        if (productDetails != null) {
          productoFinal = productDetails;
        }
        
        final tieneImpuestos = productoFinal.taxesIds != null && productoFinal.taxesIds!.isNotEmpty;
        final tieneImpuestoCompra = productoFinal.supplierTaxesIds != null && 
                                   productoFinal.supplierTaxesIds!.isNotEmpty;
        
        // ✅ **USAR PRECIO BASE SIN IMPUESTOS**
        double precioBase = productoFinal.listPrice;
        
        final articulo = ArticuloItem(
          id: productoFinal.id,
          nombre: productoFinal.name,
          categoria: productoFinal.categoryName ?? 'Sin categoría',
          subcategoria: productoFinal.typeDisplay,
          precio: precioBase, // ✅ PRECIO SIN IMPUESTOS
          descripcion: productoFinal.description ?? productoFinal.name,
          cantidad: 1,
          tieneImpuestos: tieneImpuestos || tieneImpuestoCompra,
        );
        
        // ✅ AGREGAR A LA LISTA DE PRODUCTOS DE LA PANTALLA ACTUAL
        _agregarProductoDesdeScannerAListaTemporal(articulo);
      } else {
        _mostrarMensajeError('❌ Producto no encontrado con código: $code');
      }
    }
  } catch (e) {
    print('❌ Error en escaneo COMPRAS: $e');
    _mostrarMensajeError('Error escaneando producto: $e');
  } finally {
    _isProcessingScan = false;
    setState(() => _mostrarScanner = false);
  }
}


void _agregarProductoDesdeScannerAListaTemporal(ArticuloItem articulo) {
  setState(() {
    final existingIndex = _productosAgregados.indexWhere(
      (p) => p['id'] == articulo.id
    );

    if (existingIndex >= 0) {
      _productosAgregados[existingIndex]['cantidad'] += 1;
      _productosAgregados[existingIndex]['subtotal'] = 
          _productosAgregados[existingIndex]['cantidad'] * 
          _productosAgregados[existingIndex]['precio'];
    } else {
      _productosAgregados.add({
        'id': articulo.id,
        'nombre': articulo.nombre,
        'categoria': articulo.categoria,
        'subcategoria': articulo.subcategoria,
        'precio': articulo.precio,
        'descripcion': articulo.descripcion,
        'cantidad': 1,
        'subtotal': articulo.precio,
        'tiene_impuesto': articulo.tieneImpuestos,
        'escanado': true,
      });
    }
  });
  _guardarBorrador();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${articulo.nombre} agregado (${_productosAgregados.length} productos)'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
  
  // Mostrar diálogo informativo
  _mostrarResumenProductosEscaneados();
}

// ✅ DIALOGO PARA MOSTRAR RESUMEN
void _mostrarResumenProductosEscaneados() {
  if (_productosAgregados.isEmpty) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Productos Escaneados (${_productosAgregados.length})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var producto in _productosAgregados)
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text(producto['nombre']),
                subtitle: Text('${producto['cantidad']} x \$${producto['precio'].toStringAsFixed(2)}'),
                trailing: Text('\$${(producto['cantidad'] * producto['precio']).toStringAsFixed(2)}'),
              ),
            SizedBox(height: 10),
            Text(
              'Total: \$${_calculateTotal().toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Seguir escaneando'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _mostrarDialogoCrearOrden();
          },
          child: Text('Crear Orden Ahora'),
        ),
      ],
    ),
  );
}

// ✅ DIALOGO PARA CREAR ORDEN
void _mostrarDialogoCrearOrden() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Crear Orden de Compra'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tienes ${_productosAgregados.length} productos listos.'),
          SizedBox(height: 10),
          Text('¿Con qué proveedor deseas crear la orden?'),
          SizedBox(height: 10),
          // Aquí podrías agregar un dropdown para seleccionar proveedor
          // Por ahora usaremos el proveedor por defecto (L.M.H)
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _crearOrdenConProductosEscaneados();
          },
          child: Text('Crear con L.M.H'),
        ),
      ],
    ),
  );
}

// ✅ CREAR ORDEN CON PRODUCTOS ESCANEADOS
Future<void> _crearOrdenConProductosEscaneados() async {
  if (_productosAgregados.isEmpty) {
    _showError('No hay productos para crear orden');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // 1. Obtener ID de L.M.H (o usar el que ya tienes)
    final idLmh = await _obtenerIdProveedorLMH();
    if (idLmh == null) {
      _showError('No se encontró el proveedor L.M.H');
      return;
    }

    // 2. Preparar líneas de orden
    final orderLines = _productosAgregados.map((producto) {
      return {
        'product_id': producto['id'],
        'product_qty': producto['cantidad'],
        'price_unit': producto['precio'],
        'name': producto['nombre'],
      };
    }).toList();

    print('🎯 Creando orden con ${orderLines.length} productos...');

    // 3. Crear orden en Odoo
    final result = await _purchaseService.createPurchaseOrder(
      partnerId: idLmh,
      orderLines: orderLines,
      datePlanned: _getDefaultDeliveryDate(),
      notes: 'Orden creada desde scanner con ${_productosAgregados.length} productos',
    );

    if (result['success']) {
      _showSuccess('✅ Orden creada exitosamente (ID: ${result['order_id']})');
      
      // 4. Limpiar lista temporal
      setState(() {
        _productosAgregados.clear();
      });
      
      // 5. Opcional: Navegar a la orden creada o actualizar lista
      Navigator.pop(context, true); // Regresar a la pantalla anterior
      
    } else {
      _showError('❌ Error creando orden: ${result['error']}');
    }
  } catch (e) {
    print('❌ Error completo creando orden: $e');
    _showError('❌ Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

// ✅ MÉTODO PARA SOLICITAR PROVEEDOR Y CREAR ORDEN
Future<void> _solicitarProveedorYCrearOrdenDesdeScanner(ArticuloItem articulo) async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    final purchaseService = OdooPurchaseService(odooService);
    
    final proveedores = await purchaseService.getSuppliers();
    
    if (proveedores.isEmpty) {
      _mostrarMensajeError('No hay proveedores disponibles');
      return;
    }
    
    // Mostrar diálogo para seleccionar proveedor
    final proveedorSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Proveedor'),
        content: Text('Para agregar "${articulo.nombre}", selecciona un proveedor:'),
        actions: [
          ...proveedores.take(5).map((proveedor) {
            return TextButton(
              onPressed: () => Navigator.pop(context, proveedor),
              child: Text(proveedor['name'] ?? 'Sin nombre'),
            );
          }).toList(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
    
    if (proveedorSeleccionado != null) {
      // Crear orden con el proveedor seleccionado
      final orderLines = [
        {
          'product_id': articulo.id,
          'product_qty': articulo.cantidad,
          'price_unit': articulo.precio,
          'name': articulo.nombre,
        }
      ];
      
      final resultado = await purchaseService.createPurchaseOrder(
        partnerId: proveedorSeleccionado['id'],
        orderLines: orderLines,
        datePlanned: _getDefaultDeliveryDate(),
        notes: 'Creada desde scanner',
      );
      
      if (resultado['success']) {
        _mostrarMensajeError('✅ Orden creada (ID: ${resultado['order_id']})');
        // Opcional: navegar a la pantalla de la orden o actualizar lista
      } else {
        _mostrarMensajeError('❌ Error: ${resultado['error']}');
      }
    }
  } catch (e) {
    _mostrarMensajeError('Error: $e');
  }
}

// ✅ MÉTODO PARA AGREGAR PRODUCTO A ORDEN EXISTENTE
Future<void> _agregarProductoAOrdenExistente(ArticuloItem articulo, int ordenId) async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // Agregar línea a la orden existente
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order.line',
        'create',
        [{
          'order_id': ordenId,
          'product_id': articulo.id,
          'product_qty': articulo.cantidad,
          'price_unit': articulo.precio,
          'name': articulo.nombre,
        }]
      ],
    });
    
    _mostrarMensajeError('✅ Producto agregado a orden $ordenId');
  } catch (e) {
    _mostrarMensajeError('❌ Error agregando producto: $e');
  }
}



// ✅ MÉTODO AUXILIAR PARA MOSTRAR MENSAJES
void _mostrarMensajeError(String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: mensaje.contains('✅') ? Colors.green : Colors.orange,
      duration: const Duration(seconds: 3),
    ),
  );
}

void _agregarProductoDesdeScanner(ArticuloItem articulo) {
  setState(() {
    final existingIndex = _productosAgregados.indexWhere(
      (p) => p['id'] == articulo.id
    );

    if (existingIndex >= 0) {
      _productosAgregados[existingIndex]['cantidad'] += 1;
    } else {
      _productosAgregados.add({
        'id': articulo.id,
        'nombre': articulo.nombre,
        'categoria': articulo.categoria,
        'precio': articulo.precio,
        'descripcion': articulo.descripcion,
        'cantidad': 1,
        'subtotal': articulo.precio,
      });
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${articulo.nombre} agregado desde scanner'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

// 🎯 CONTENIDO PRINCIPAL CON BÚSQUEDA
Widget _buildContent(double total) {
  return Column(
    children: [
      // INFORMACIÓN DEL PROVEEDOR
      _buildProveedorInfo(),
      
      // 🎯 SECCIÓN SCANNER
      if (_mostrarScanner)
        Container(
          margin: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleScan,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _mostrarScanner = false),
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
                    'Escanea un código de barras',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

      // FORMULARIO DE INFORMACIÓN ADICIONAL
      _buildOrderInfoForm(),

      // 🎯 RESULTADOS DE BÚSQUEDA
      if (_searchController.text.isNotEmpty && _productosFiltrados.isNotEmpty)
        _buildResultadosBusqueda(),

      // LISTA DE PRODUCTOS AGREGADOS
      Expanded(
        child: _productosAgregados.isEmpty
            ? _buildEmptyState()
            : _buildProductList(),
      ),
    ],
  );
}

// 🎯 WIDGET PARA MOSTRAR RESULTADOS DE BÚSQUEDA
Widget _buildResultadosBusqueda() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Resultados de búsqueda:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _productosFiltrados.length,
            itemBuilder: (context, index) {
              final producto = _productosFiltrados[index];
              return _buildItemResultadoBusqueda(producto);
            },
          ),
        ),
      ],
    ),
  );
}

// Agrega este método a tu CrearOrdenCompraScreen
Future<void> _verificarCreacionOrdenOdoo(int orderId) async {
  try {
    print('🔍 VERIFICANDO ORDEN EN ODDO: ID $orderId');
    
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: 'pointsales-v18',
    );
    
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // Verificar si la orden existe en Odoo
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'purchase.order',
        'read',
        [
          [orderId]
        ],
        {
          'fields': ['id', 'name', 'state', 'order_line', 'amount_total'],
        }
      ],
    });
    
    final orden = (result as List).cast<Map<String, dynamic>>().first;
    print('✅ Orden encontrada en Odoo:');
    print('   ID: ${orden['id']}');
    print('   Nombre: ${orden['name']}');
    print('   Estado: ${orden['state']}');
    print('   Líneas: ${orden['order_line']}');
    print('   Total: ${orden['amount_total']}');
    
    // Verificar líneas de la orden
    if (orden['order_line'] != null && (orden['order_line'] as List).isNotEmpty) {
      print('🔍 Verificando líneas de la orden...');
      
      final lineResult = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order.line',
          'search_read',
          [
            [['order_id', '=', orderId]]
          ],
          {
            'fields': ['id', 'product_id', 'name', 'product_qty', 'price_unit'],
          }
        ],
      });
      
      final lineas = (lineResult as List).cast<Map<String, dynamic>>();
      print('   📦 Líneas encontradas: ${lineas.length}');
      
      for (var linea in lineas) {
        print('      - ${linea['name']} x${linea['product_qty']} = \$${linea['price_unit']}');
      }
    } else {
      print('❌ La orden NO TIENE LÍNEAS en Odoo');
    }
    
  } catch (e) {
    print('❌ Error verificando orden en Odoo: $e');
  }
}

// 🎯 ÍTEM DE RESULTADO DE BÚSQUEDA
Widget _buildItemResultadoBusqueda(Product producto) {
  return ListTile(
    leading: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
    ),
    title: Text(
      producto.name,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (producto.defaultCode != null) Text('Código: ${producto.defaultCode}'),
        Text('Precio: \$${producto.listPrice.toStringAsFixed(2)}'),
        if (producto.barcode != null) Text('Barcode: ${producto.barcode}'),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(Icons.add_circle, color: Colors.green),
      onPressed: () {
        _agregarProductoDesdeBusqueda(producto);
        _searchController.clear();
        setState(() {
          _productosFiltrados = [];
        });
      },
    ),
    onTap: () {
      _agregarProductoDesdeBusqueda(producto);
      _searchController.clear();
      setState(() {
        _productosFiltrados = [];
      });
    },
  );
}

void _agregarProductoDesdeBusqueda(Product producto) {
  // ✅ Cambiar a _getPrecioBase
  final precioBase = _getPrecioBase(producto);
  final tieneImpuestos = (producto.taxesIds != null && producto.taxesIds!.isNotEmpty) ||
                        (producto.supplierTaxesIds != null && producto.supplierTaxesIds!.isNotEmpty);
  
  setState(() {
    final existingIndex = _productosAgregados.indexWhere(
      (p) => p['id'] == producto.id
    );

    if (existingIndex >= 0) {
      _productosAgregados[existingIndex]['cantidad'] += 1;
      _productosAgregados[existingIndex]['subtotal'] = 
          _productosAgregados[existingIndex]['cantidad'] * precioBase;
    } else {
      _productosAgregados.add({
        'id': producto.id,
        'nombre': producto.name,
        'categoria': producto.categoryName ?? 'Sin categoría',
        'precio': precioBase, // ✅ PRECIO SIN IMPUESTOS
        'descripcion': producto.description ?? producto.name,
        'cantidad': 1,
        'subtotal': precioBase,
        'tiene_impuesto': tieneImpuestos, 
      });
    }
  }); 
  _guardarBorrador();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${producto.name} agregado' + (tieneImpuestos ? ' (sin impuestos)' : '')),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

  // 🎯 INFORMACIÓN DEL PROVEEDOR
  Widget _buildProveedorInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.proveedor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.proveedor.email != null && widget.proveedor.email!.isNotEmpty)
                  Text(
                    widget.proveedor.email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                if (widget.proveedor.vat != null && widget.proveedor.vat!.isNotEmpty)
                  Text(
                    'RUT: ${widget.proveedor.vat!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: _changeSupplier,
            tooltip: 'Cambiar proveedor',
          ),
        ],
      ),
    );
  }

void _buscarProductos(String query) async {
  if (query.length < 2) {
    setState(() {
      _productosFiltrados = [];
    });
    return;
  }

  try {
    final queryLower = query.toLowerCase();
    
    // Primero buscar en productos ya cargados
    final productosLocales = _productosDisponibles.where((producto) {
      return producto.name.toLowerCase().contains(queryLower) ||
             (producto.defaultCode?.toLowerCase().contains(queryLower) ?? false) ||
             (producto.barcode?.toLowerCase().contains(queryLower) ?? false);
    }).toList();

    setState(() {
      _productosFiltrados = productosLocales;
    });

    // Si no hay resultados locales, buscar en Odoo
    if (productosLocales.isEmpty) {
      final productoOdoo = await _productService.getProductByBarcode(query);
      if (productoOdoo != null) {
        setState(() {
          _productosFiltrados = [productoOdoo];
        });
      }
    }
  } catch (e) {
    print('❌ Error buscando productos: $e');
  }
}


Widget _buildOrderInfoForm() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // 🎯 BARRA DE BÚSQUEDA INTEGRADA
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos por nombre o código...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.length >= 2) {
                    _buscarProductos(value);
                  }
                },
                // onTap: () {
                //   // Opcional: Mostrar lista de productos al hacer tap
                //   _mostrarBusquedaProductos();
                // },
              ),
            ),
            const SizedBox(width: 10),
            // 🎯 BOTÓN SCANNER
            IconButton(
              icon: const Icon(Icons.document_scanner),
              onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
              style: IconButton.styleFrom(
                backgroundColor: _mostrarScanner ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              tooltip: 'Escáner de código de barras',
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // FECHA DE ENTREGA
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Fecha de entrega:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectDeliveryDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _formatDate(_fechaEntrega),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // NOTAS
        TextField(
  onChanged: (value) => _onNotasChanged(value),
  controller: TextEditingController(text: _notas),
  decoration: const InputDecoration(
    labelText: 'Notas (opcional)',
    prefixIcon: Icon(Icons.note),
    border: OutlineInputBorder(),
  ),
  maxLines: 2,
),
      ],
    ),
  );
}

double _getPrecioBase(Product product) {
  final tieneImpuestos = product.taxesIds != null && product.taxesIds!.isNotEmpty;
  final tieneImpuestoCompra = product.supplierTaxesIds != null && 
                             product.supplierTaxesIds!.isNotEmpty;
  
  print('🔍 Verificando impuestos para: ${product.name}');
  print('   Precio base: \$${product.listPrice}');
  print('   Tiene impuestos venta: $tieneImpuestos');
  print('   Tiene impuestos compra: $tieneImpuestoCompra');
  
  // ✅ **SIEMPRE DEVOLVER EL PRECIO BASE SIN IMPUESTOS**
  // En compras no aplicamos impuestos al precio
  return product.listPrice;
}

  // 🎯 LISTA DE PRODUCTOS AGREGADOS
  Widget _buildProductList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _productosAgregados.length,
      itemBuilder: (context, index) {
        final producto = _productosAgregados[index];
        return _buildProductItem(producto, index);
      },
    );
  }

  // 🎯 ÍTEM DE PRODUCTO MEJORADO
  // 🎯 ÍTEM DE PRODUCTO MEJORADO - CONTROL DE CANTIDAD FIXED
Widget _buildProductItem(Map<String, dynamic> producto, int index) {
  final cantidad = producto['cantidad'] ?? 1;
  final precio = producto['precio'] ?? 0.0;
  final subtotal = cantidad * precio;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        // BARRA LATERAL DE COLOR
        Container(
          width: 6,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // INFORMACIÓN DEL PRODUCTO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto['nombre'] ?? 'Producto',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${producto['default_code'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // ✅ CONTROL DE CANTIDAD MEJORADO
                      Row(
                        children: [
                          // ✅ CONTROL DE CANTIDAD CON ANCHO FIJO
                          Container(
                            width: 120, // ✅ ANCHO FIJO PARA 2 DÍGITOS
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // ✅ BOTÓN MENOS
                                SizedBox(
                                  width: 32,
                                  child: IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () => _updateQuantity(index, cantidad - 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                
                                // ✅ CANTIDAD CON ANCHO FIJO
                                Container(
                                  width: 40, // ✅ ANCHO FIJO
                                  alignment: Alignment.center,
                                  child: Text(
                                    cantidad.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                
                                // ✅ BOTÓN MÁS
                                SizedBox(
                                  width: 32,
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () => _updateQuantity(index, cantidad + 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // ✅ PRECIO UNITARIO MEJORADO
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: precio.toStringAsFixed(2)
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                final newPrice = double.tryParse(value) ?? precio;
                                _updatePrice(index, newPrice);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ✅ COLUMNA DERECHA MEJORADA
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ SUBTOTAL
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // ✅ BOTÓN ELIMINAR
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeProduct(index),
                      tooltip: 'Eliminar producto',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  // 🎯 BARRA INFERIOR CON TOTAL Y BOTÓN CREAR
  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // TOTAL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // BOTÓN CREAR ORDEN
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Crear Orden'),
            onPressed: _createPurchaseOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF583F80),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ESTADO VACÍO MEJORADO
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay productos agregados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega productos para crear la orden de compra',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 🎯 DETALLES DEL CARRITO
  void _showCartDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_cart, color: Color(0xFF583F80)),
                  SizedBox(width: 8),
                  Text(
                    'Productos Agregados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF583F80),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // LISTA DE PRODUCTOS
              ..._productosAgregados.map((producto) {
                final cantidad = producto['cantidad'] ?? 1;
                final precio = producto['precio'] ?? 0.0;
                final subtotal = cantidad * precio;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${producto['nombre']} (x$cantidad)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const Divider(),
              
              // TOTAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF583F80),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 MÉTODOS DE ACCIÓN
  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _productosAgregados[index]['cantidad'] = newQuantity;
      });
      _guardarBorrador();
    }
  }

  void _updatePrice(int index, double newPrice) {
    setState(() {
      _productosAgregados[index]['precio'] = newPrice;
    });
    _guardarBorrador();
  }

  void _removeProduct(int index) {
    setState(() {
      _productosAgregados.removeAt(index);
    });
    _guardarBorrador();
  }

  void _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fechaEntrega),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        _fechaEntrega = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
          _guardarBorrador();

    }
  }

  void _changeSupplier() {
    // Navegar de vuelta a proveedores
    Navigator.pop(context);
  }
void _debugOrderData() {
  print('🐛 DEBUG ORDER DATA:');
  print('   Proveedor ID: ${widget.proveedor.id}');
  print('   Proveedor Name: ${widget.proveedor.name}');
  print('   Productos agregados: ${_productosAgregados.length}');
  
  for (var producto in _productosAgregados) {
    print('      - ${producto['nombre']} (ID: ${producto['id']})');
    print('        Cantidad: ${producto['cantidad']}');
    print('        Precio: ${producto['precio']}');
    print('        Tipo ID: ${producto['id'].runtimeType}');
    print('        Tipo Cantidad: ${producto['cantidad'].runtimeType}');
    print('        Tipo Precio: ${producto['precio'].runtimeType}');
  }
  
  print('   Fecha entrega: $_fechaEntrega');
  print('   Notas: $_notas');
}

Future<void> _createPurchaseOrder() async {
  if (_productosAgregados.isEmpty) {
    _showError('Agrega al menos un producto a la orden');
    return;
  }

  setState(() => _isLoading = true);

  try {
    print('🛒 PRODUCTOS PARA CREAR ORDEN:');
    for (var i = 0; i < _productosAgregados.length; i++) {
      final producto = _productosAgregados[i];
      print('   ${i + 1}. ${producto['nombre']}');
      print('      ID: ${producto['id']}');
      print('      Cantidad: ${producto['cantidad']}');
      print('      Precio: ${producto['precio']}');
    }

    final orderLines = _productosAgregados.map((producto) {
      return {
        'product_id': producto['id'],
        'product_qty': producto['cantidad'],
        'price_unit': producto['precio'],
        'name': producto['nombre'],
      };
    }).toList();

    print('🎯 Creando orden con ${orderLines.length} productos...');
    print('   Proveedor ID: ${widget.proveedor.id}');
    print('   Proveedor Nombre: ${widget.proveedor.name}');

    final result = await _purchaseService.createPurchaseOrder(
      partnerId: widget.proveedor.id,
      orderLines: orderLines,
      datePlanned: _fechaEntrega,
      notes: _notas.isNotEmpty ? _notas : 'Orden creada desde app móvil',
    );

    if (result['success']) {
      final orderId = result['order_id'];
      _showSuccess('✅ Orden de compra creada exitosamente (ID: $orderId)');
       final draftId = 'compra_${widget.proveedor.id}';
      await DraftOrderService.instance.deleteDraft(draftId);
      
      // Crear el objeto local
      final nuevaOrden = PurchaseOrder(
        id: orderId.toString(),
        date: DateTime.now(),
        total: _calculateTotal(),
        status: 'draft',
      );

      // Convertir productos a ArticuloItem
      final articulos = _productosAgregados.map((p) {
        return ArticuloItem(
          id: p['id'] ?? 0,
          nombre: p['nombre'] ?? 'Producto',
          categoria: p['categoria'] ?? 'Sin categoría',
          precio: (p['precio'] ?? 0.0).toDouble(),
          descripcion: p['descripcion'] ?? '',
          cantidad: p['cantidad'] ?? 1,
        );
      }).toList();

      widget.onOrdenCreada(nuevaOrden, widget.proveedor, articulos);
      
      setState(() {
        _productosAgregados.clear();
      });
      
      Navigator.pop(context, true);
      
      await Future.delayed(Duration(seconds: 2));
      
    } else {
      _showError('❌ Error creando orden: ${result['error']}');
    }
  } catch (e) {
    print('❌ Error completo creando orden: $e');
    _showError('❌ Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }

}

void _onNotasChanged(String value) {
  _notas = value;
  _guardarBorrador();
}

  // 🎯 MÉTODOS AUXILIARES
  double _calculateTotal() {
    return _productosAgregados.fold(0.0, (sum, producto) {
      final cantidad = producto['cantidad'] ?? 1;
      final precio = producto['precio'] ?? 0.0;
      return sum + (cantidad * precio);
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }


void _agregarProductoDesdeSelector(ArticuloItem articulo, int cantidad) {
  setState(() {
    final existingIndex = _productosAgregados.indexWhere(
      (p) => p['id'] == articulo.id
    );

    if (existingIndex >= 0) {
      _productosAgregados[existingIndex]['cantidad'] += cantidad;
      _productosAgregados[existingIndex]['subtotal'] = 
          _productosAgregados[existingIndex]['cantidad'] * _productosAgregados[existingIndex]['precio'];
    } else {
      _productosAgregados.add({
        'id': articulo.id,
        'nombre': articulo.nombre,
        'categoria': articulo.categoria,
        'precio': articulo.precio,
        'descripcion': articulo.descripcion,
        'cantidad': cantidad,
        'subtotal': articulo.precio * cantidad,
      });
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${articulo.nombre} agregado a la orden'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

// 🎯 REMOVER PRODUCTO DESDE EL SELECTOR
void _removerProductoDesdeSelector(ArticuloItem articulo) {
  setState(() {
    _productosAgregados.removeWhere((p) => p['id'] == articulo.id);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('🗑️ ${articulo.nombre} removido de la orden'),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    ),
  );
}
}
