
import 'package:flutter/material.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
//import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
//mport 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
//import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
//import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
//import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/services/odoo_purchase_service.dart';


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

  late OdooPurchaseService _purchaseService;
  late OdooProductService _productService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fechaEntrega = _getDefaultDeliveryDate();
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
        baseUrl: 'https://solutions.tailorw.net',
        dbName: 'pointsales_prodv18',
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
        // 🎯 ACTUALIZA ESTE BOTÓN TAMBIÉN
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _navigateToProductSearch, // ← CAMBIADO AQUÍ
          tooltip: 'Buscar productos',
        ),
        if (_productosAgregados.isNotEmpty)
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

  // 🎯 CONTENIDO PRINCIPAL MEJORADO
  Widget _buildContent(double total) {
    return Column(
      children: [
        // INFORMACIÓN DEL PROVEEDOR
        _buildProveedorInfo(),
        
        // BARRA DE BÚSQUEDA
        if (_mostrarBusqueda)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar productos para agregar...",
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

        // FORMULARIO DE INFORMACIÓN ADICIONAL
        _buildOrderInfoForm(),

        // LISTA DE PRODUCTOS AGREGADOS O ESTADO VACÍO
        Expanded(
          child: _productosAgregados.isEmpty
              ? _buildEmptyState()
              : _buildProductList(),
        ),
      ],
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

  // 🎯 FORMULARIO DE INFORMACIÓN DE LA ORDEN
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
            onChanged: (value) => _notas = value,
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
                        
                        // CONTROLES DE CANTIDAD Y PRECIO
                        Row(
                          children: [
                            // CONTROL DE CANTIDAD
                            Container(
                              width: 100,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () => _updateQuantity(index, cantidad - 1),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Expanded(
                                    child: Text(
                                      cantidad.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () => _updateQuantity(index, cantidad + 1),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // PRECIO UNITARIO
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
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
                  
                  // SUBTOTAL Y BOTÓN ELIMINAR
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeProduct(index),
                        tooltip: 'Eliminar producto',
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
          ElevatedButton.icon(
  icon: const Icon(Icons.search),
  label: const Text('Buscar Productos'),
  onPressed: _navigateToProductSearch,  // ← ESTE ES EL MÉTODO CORRECTO
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF583F80),
    foregroundColor: Colors.white,
  ),
)
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
    }
  }

  void _updatePrice(int index, double newPrice) {
    setState(() {
      _productosAgregados[index]['precio'] = newPrice;
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _productosAgregados.removeAt(index);
    });
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

  // En _CrearOrdenCompraScreenState
Future<void> _createPurchaseOrder() async {
   _debugOrderData();
  if (_productosAgregados.isEmpty) {
    _showError('Agrega al menos un producto a la orden');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // 🎯 CORREGIR: PREPARAR LÍNEAS DE ORDEN CON LA ESTRUCTURA CORRECTA
    final orderLines = _productosAgregados.map((producto) {
      return {
        'product_id': producto['id'],
        'product_qty': producto['cantidad'],
        'price_unit': producto['precio'],
        'name': producto['nombre'] ?? 'Producto',
      };
    }).toList();

    print('📋 Líneas de orden preparadas:');
    for (var line in orderLines) {
      print('   Producto: ${line['name']} - Cantidad: ${line['product_qty']} - Precio: ${line['price_unit']}');
    }

    // ✅ USAR EL MÉTODO CORREGIDO
    final result = await _purchaseService.createPurchaseOrder(
      partnerId: widget.proveedor.id,
      orderLines: orderLines,
      datePlanned: _fechaEntrega,
      notes: _notas.isNotEmpty ? _notas : null,
    );

    if (result['success']) {
      _showSuccess('✅ Orden de compra creada exitosamente');
      
      // ✅ CREAR EL OBJETO PURCHASEORDER Y LLAMAR AL CALLBACK
      final nuevaOrden = PurchaseOrder(
        id: result['order_id'].toString(),
        date: DateTime.now(),
        total: _calculateTotal(),
        status: 'draft',
      );

      // ✅ CONVERTIR PRODUCTOS A ARTICULOITEM
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

      // ✅ LLAMAR AL CALLBACK
      widget.onOrdenCreada(nuevaOrden, widget.proveedor, articulos);
      
      Navigator.pop(context, true);
    } else {
      _showError('❌ Error creando orden: ${result['error']}');
    }
  } catch (e) {
    _showError('❌ Error: $e');
    print('📋 StackTrace completo: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
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
  // 🎯 NAVEGAR A BÚSQUEDA DE PRODUCTOS
void _navigateToProductSearch() async {
  print('🎯 Navegando a búsqueda de productos...');
  
  try {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticuloSelectorScreen(
          onArticuloAgregado: (articulo, cantidad) {
            _agregarProductoDesdeSelector(articulo, cantidad);
          },
          onArticuloEliminado: (articulo) {
            _removerProductoDesdeSelector(articulo);
          },
          articulosSeleccionadosIniciales: _productosAgregados.map((p) {
            return ArticuloItem(
              id: p['id'] ?? 0,
              nombre: p['nombre'] ?? 'Producto',
              categoria: p['categoria'] ?? 'Sin categoría',
              precio: (p['precio'] ?? 0.0).toDouble(),
              descripcion: p['descripcion'] ?? '',
              cantidad: p['cantidad'] ?? 1,
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      print('✅ Productos seleccionados: $result');
    }
  } catch (e) {
    print('❌ Error navegando a productos: $e');
    _showError('Error al abrir búsqueda de productos: $e');
  }
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