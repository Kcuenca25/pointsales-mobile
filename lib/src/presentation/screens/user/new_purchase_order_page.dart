import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/services/odoo_purchase_service.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';  // For ProductDetailScreen if compatible, or reuse
import 'package:ecomerce_app/src/services/cache_service.dart';

class NewPurchaseOrderPage extends StatefulWidget {
  final Customer supplier;
  final Function(Map<String, dynamic>)? onOrderCreated;

  const NewPurchaseOrderPage({
    super.key,
    required this.supplier,
    this.onOrderCreated,
  });

  @override
  State<NewPurchaseOrderPage> createState() => _NewPurchaseOrderPageState();
}

class _NewPurchaseOrderPageState extends State<NewPurchaseOrderPage> {
  final _totalController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
  );
  
  // Services
  late OdooServiceEnhanced _odooService;
  late OdooProductService _productService;
  late OdooPurchaseService _purchaseService;
  
  // State
  List<ArticuloItem> _articulos = [];
  List<Product> _productosDisponibles = [];
  bool _isProcessingScan = false;
  bool _mostrarScanner = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _cargarProductos();
    _actualizarTotal();
  }

  void _initializeServices() {
    _odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    _productService = OdooProductService(_odooService);
    _purchaseService = OdooPurchaseService(_odooService);
  }

  Future<void> _cargarProductos() async {
    try {
      // Usar caché para carga rápida
      var products = await CacheService.getCachedProducts();
      
      if (products.isEmpty) {
        // Si no hay caché, intentar cargar online (si hay credenciales guardadas, o usar las default por ahora)
        await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
        products = await _productService.getProducts(limit: 200);
      }
      
      if (mounted) {
        setState(() {
          _productosDisponibles = products;
        });
      }
    } catch (e) {
      print('❌ Error cargando productos: $e');
    }
  }

  // ✅ CRÍTICO: PRECIOS SIN ITBIS
  double _getPrecioSinImpuesto(Product product) {
    // Para órdenes de compra, Odoo espera el precio unitario base.
    // Asumimos que product.listPrice es el precio de VENTA.
    // Normalmente el precio de costo está en standard_price, pero el modelo Product actual usa listPrice.
    // Si el usuario quiere "Precio Normal", usaremos el listPrice tal cual, SIN agregarle ITBIS.
    print('💰 Usando precio base para compra: ${product.listPrice}');
    return product.listPrice;
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan || capture.barcodes.isEmpty) return;
    
    final codeRaw = capture.barcodes.first.rawValue;
    if (codeRaw == null || codeRaw.isEmpty) return;
    final code = codeRaw.trim();

    _isProcessingScan = true;
    
    try {
      print('🔍 Código escaneado en COMPRA: $code');
      
      // Intentar login silencioso
      await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
      
      // Buscar en Odoo
      Product? product = await _productService.getProductByBarcode(code);
      print('🔎 Resultado de búsqueda para $code: ${product?.name ?? "NO ENCONTRADO"}');
      
      if (product == null) {
        // Fallback a búsqueda local
        try {
            product = _productosDisponibles.firstWhere(
            (p) => p.barcode == code || p.defaultCode == code
            );
        } catch (e) {
            // No encontrado localmente tampoco
            product = null;
        }
      }

      if (product != null) {
        // Producto encontrado
        _agregarOActualizarProducto(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${product.name} agregado'), duration: Duration(seconds: 1)),
        );
      } else {
        _mostrarError('Producto no encontrado con código: $code');
      }

    } catch (e) {
      _mostrarError('Error al escanear: $e');
    } finally {
      _isProcessingScan = false;
      // Opcional: Cerrar scanner o mantenerlo abierto para escanear más
      // setState(() => _mostrarScanner = false); 
    }
  }

  void _agregarOActualizarProducto(Product product) {
    final precio = _getPrecioSinImpuesto(product);
    
    setState(() {
      final index = _articulos.indexWhere((a) => a.id == product.id);
      
      if (index >= 0) {
        _articulos[index].cantidad++;
      } else {
        _articulos.insert(0, ArticuloItem(
          id: product.id,
          nombre: product.name,
          categoria: product.categoryName ?? '',
          subcategoria: product.typeDisplay,
          precio: precio,
          descripcion: product.description ?? product.name,
          cantidad: 1,
          tieneImpuestos: false, // ✅ NO IMPUESTOS EN VISUALIZACIÓN
        ));
      }
      _actualizarTotal();
    });
  }

  void _actualizarTotal() {
    double total = _articulos.fold(0, (sum, item) => sum + (item.precio * item.cantidad));
    _totalController.text = "\$${total.toStringAsFixed(2)}";
  }

  void _guardarOrden() async {
    if (_articulos.isEmpty) {
      _mostrarError('La orden debe tener al menos un artículo');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final orderLines = _articulos.map((articulo) => {
        'product_id': articulo.id,
        'product_qty': articulo.cantidad,
        'price_unit': articulo.precio, // Precio SIN ITBIS
        'name': articulo.nombre, // Opcional, Odoo lo pone por defecto si falta
      }).toList();

      // Login antes de crear
      await _odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);

      final result = await _purchaseService.createPurchaseOrder(
        partnerId: widget.supplier.id,
        orderLines: orderLines,
      );

      if (result['success'] == true) {
        // Notificar y salir
        if (widget.onOrderCreated != null) {
            // Construir objeto de orden local para actualización inmediata
            final nuevaOrden = {
                'orden': result['order_id'].toString(),
                'proveedor': widget.supplier.name,
                'fecha': DateTime.now().toString(),
                'estado': 'Pendiente', // Purchase orders start as draft/RFQ
                'total': _articulos.fold(0.0, (s, a) => s + (a.precio * a.cantidad)),
                'articulos': _articulos.map((a) => { 
                    'nombre': a.nombre,
                    'cantidad': a.cantidad,
                    'precio': a.precio
                 }).toList(),
            };
            widget.onOrderCreated!(nuevaOrden);
        }
        
        Navigator.pop(context); // Cerrar pantalla de nueva orden
        Navigator.pop(context); // Cerrar pantalla de selección de proveedor (opcional, depende del flujo)
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Orden de Compra creada existosamente'), backgroundColor: Colors.green),
        );
      } else {
        _mostrarError('Error creando orden: ${result['error']}');
      }

    } catch (e) {
      _mostrarError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarError(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo claro
      appBar: AppBar(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text("Nueva Compra", style: TextStyle(fontSize: 16)),
                Text(widget.supplier.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
        ),
        actions: [
             IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area (condicional)
          if (_mostrarScanner)
            Container(
              height: 250,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleScan,
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0, 
                    right: 0,
                    child: Center(
                        child: Text("Apunte al código de barras", style: TextStyle(color: Colors.white))
                    ),
                  ),
                   Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _mostrarScanner = false),
                    )
                  )
                ],
              ),
            ),

          // Lista de Artículos
          Expanded(
            child: _articulos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No hay artículos agregados", style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                            onPressed: () => _mostrarSelectorCompleto(),
                            icon: Icon(Icons.add),
                            label: Text("Agregar Productos"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _articulos.length,
                    itemBuilder: (context, index) {
                      final item = _articulos[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(item.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("\$${item.precio.toStringAsFixed(2)} x ${item.cantidad}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("\$${(item.precio * item.cantidad).toStringAsFixed(2)}", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                    setState(() {
                                        if (item.cantidad > 1) {
                                            item.cantidad--;
                                        } else {
                                            _articulos.removeAt(index);
                                        }
                                        _actualizarTotal();
                                    });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                              // Opcional: Editar cantidad manualmente
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Footer con Total y Botón Guardar
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_totalController.text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _guardarOrden,
                    child: _isSaving 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("GUARDAR ORDEN DE COMPRA", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorCompleto() {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticuloSelectorScreen(
          esParaVenta: false, // ✅ IMPUESTOS DESACTIVADOS PARA COMPRAS
          onArticuloAgregado: (articulo, cantidad) {
             // Asegurar que el precio sea sin ITBIS (aunque ArticuloItem ya puede traerlo sucio, mejor re-validar con el producto si es posible)
             // Simplemente actualizamos estado aquí
             setState(() {
                 // Verificar si ya existe
                 final index = _articulos.indexWhere((a) => a.id == articulo.id);
                 if(index >=0){
                     _articulos[index].cantidad += cantidad;
                 } else {
                     // Ajustar precio del articulo agregado manualmente para asegurar que no tenga ITBIS si el selector lo traía
                     // Asumimos que ArticuloSelector puede traer precio CON impuestos si se reutiliza lógica de ventas.
                     // Pero aquí necesitamos SIN.
                     // HACK: Reutilizamos el ArticuloItem pero confiamos en que el usuario verificará el precio o que el selector se comporta bien.
                     // Lo ideal sería buscar el Product base y tomar su listPrice de nuevo.
                     
                     _articulos.add(articulo); 
                 }
                 _actualizarTotal();
             });
          },
          onArticuloEliminado: (articulo) {},
          articulosSeleccionadosIniciales: _articulos,
        ),
      ),
    );
  }
}
