import 'package:flutter/material.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/07-proveedores.dart';
//import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden.dart';


// VENTANA DE ÓRDENES DE COMPRA
class PurchaseOrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> purchaseOrders;
  final Customer? selectedSupplier;

  const PurchaseOrdersScreen({
    super.key,
    required this.purchaseOrders,
    this.selectedSupplier,
  });

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  String estadoFiltro = "Todas";
  String _ordenFecha = "DESC";
  int _selectedIndex = 3; // Índice para navegación
  int _resultadosCount = 0;
  late OdooPurchaseService _purchaseService;

  // 🎯 CREA UNA COPIA MUTABLE DE LAS ÓRDENES
  List<Map<String, dynamic>> _ordenesLocales = [];

  @override
  void initState() {
    super.initState();
    _ordenesLocales = List<Map<String, dynamic>>.from(widget.purchaseOrders);
    _resultadosCount = _ordenesLocales.length;
    _initializeServices();
    _cargarOrdenesDesdeOdoo();
  }

  void _initializeServices() {
    final companyService = CompanyService();
    
    // ✅ USAR LA MISMA INSTANCIA DE ODDO SERVICE
    final odooService = companyService.odooService;
    
    if (odooService != null) {
      _purchaseService = OdooPurchaseService(odooService);
    } else {
      // Fallback si no está inicializado
      final fallbackService = OdooServiceEnhanced(
        baseUrl: 'https://solutions.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      _purchaseService = OdooPurchaseService(fallbackService);
    }
  }

  void _agregarOrden(Map<String, dynamic> nuevaOrden) {
    setState(() {
      final ordenCompleta = {
        'orden': nuevaOrden['orden'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'proveedor': nuevaOrden['proveedor'] ?? 'Proveedor desconocido',
        'articulo': nuevaOrden['articulo'] ?? '',
        'articulos': nuevaOrden['articulos'] ?? [],
        'fecha': nuevaOrden['fecha'] ?? DateTime.now().toString(),
        'estado': nuevaOrden['estado'] ?? 'Presupuesto',
        'total': nuevaOrden['total'] ?? 0.0,
      };
      
      _ordenesLocales.insert(0, ordenCompleta);
      _resultadosCount = _ordenesLocales.length;
    });
  }

  // Agrega este método temporal para debug
  void _verificarEstadosOrdenes() {
  print('📊 DIAGNÓSTICO COMPLETO DE ÓRDENES DE COMPRA:');
  for (var orden in _ordenesLocales) {
    print('════════════════════════════════════════════');
    print('📋 Orden: ${orden['referencia_odoo']}');
    print('   👤 Proveedor: ${orden['proveedor']}');
    print('   💰 Total: \$${orden['total']}');
    print('   📅 Fecha: ${orden['fecha']}');
    print('   --- ESTADOS RAW ---');
    print('   🏷️  Estado Odoo: ${orden['state_odoo']}');
    print('   📦 Receipt Status: ${orden['receipt_status']}');
    print('   🧾 Invoice Status: ${orden['invoice_status']}');
    print('   📝 Note: ${orden['note']}');
    print('   --- ESTADOS VISUALES ---');
    print('   👁️  Estado Visual: ${orden['estado']}');
    print('   ✅ Mapeo correcto: ${_verificarMapeoCorrecto(orden)}');
  }
  print('════════════════════════════════════════════');
}

bool _verificarMapeoCorrecto(Map<String, dynamic> orden) {
  final estadoOdoo = orden['state_odoo'];
  final receiptStatus = orden['receipt_status'];
  final estadoVisual = orden['estado'];
  
  // Lógica de mapeo igual que _getEstadoVisual
  String estadoCorrecto = _getEstadoVisual(orden);
  
  return estadoVisual == estadoCorrecto;
}

  Future<void> _cargarOrdenesDesdeOdoo() async {
    try {
      final companyService = CompanyService();
      final odooService = companyService.odooService;
      
      if (odooService == null) {
        print('❌ OdooService no inicializado en CompanyService');
        return;
      }
      
      final ordenesOdoo = await _purchaseService.getPurchaseOrders();
      
      setState(() {
        _ordenesLocales = ordenesOdoo.map((ordenOdoo) {
          return {
            'orden': ordenOdoo['id'].toString(),
            'proveedor': ordenOdoo['partner_id'] is List 
                ? (ordenOdoo['partner_id'][1] as String) 
                : 'Proveedor Odoo',
            'fecha': ordenOdoo['date_order'],
            'estado': _getEstadoVisual(ordenOdoo),
            'state_odoo': ordenOdoo['state'],
            'receipt_status': ordenOdoo['receipt_status'],
            'invoice_status': ordenOdoo['invoice_status'],
            'note': ordenOdoo['note'],
            'total': (ordenOdoo['amount_total'] as num).toDouble(),
            'referencia_odoo': ordenOdoo['name'],
            'date_planned': ordenOdoo['date_planned'],
          };
        }).toList();
        
        _resultadosCount = _ordenesLocales.length;
      });
      
      _verificarEstadosOrdenes();
      
    } catch (e) {
      print('❌ Error cargando órdenes de compra: $e');
    }
  }

  // ✅ MÉTODO PARA MOSTRAR ERRORES
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Método para crear orden de prueba
  Future<void> _crearOrdenPrueba() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Creando orden de compra de prueba..."),
          ],
        ),
      ),
    );

    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        final resultado = await _purchaseService.createPurchaseOrder(
          partnerId: 1, // Proveedor por defecto
          orderLines: [
            {
              'product_id': 14, // Producto de ejemplo
              'quantity': 2,
              'price_unit': 1253.39,
            }
          ],
        );

        Navigator.pop(context);

        if (resultado['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Orden de compra de prueba creada (ID: ${resultado['order_id']})'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recargar órdenes
          _cargarOrdenesDesdeOdoo();
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDebugButton() {
    return FloatingActionButton(
      heroTag: "debug",
      onPressed: _crearOrdenPrueba,
      backgroundColor: Colors.orange,
      mini: true,
      child: Icon(Icons.bug_report, color: Colors.white),
    );
  }

// 🎯 VERSIÓN CON "PENDIENTE" - REEMPLAZA LA ACTUAL
String _mapearEstadoOdoo(String estadoOdoo) {
  switch (estadoOdoo) {
    case 'draft': return 'Pendiente';  // ← CAMBIADO de "Presupuesto" a "Pendiente"
    case 'sent': return 'Enviada';
    case 'to approve': return 'Por Aprobar';
    case 'purchase': return 'Confirmada';
    case 'done': return 'Recibida';
    case 'cancel': return 'Cancelada';
    default: return 'Pendiente';       // ← CAMBIADO también aquí
  }
}

  Color _getStatusColor(String status) {
  switch (status) {
    case 'Pendiente': return Colors.orange; // ← Color naranja para Pendiente
    case 'Enviada': return Colors.blue;
    case 'Por Aprobar': return Colors.orange;
    case 'Confirmada': return Colors.green;
    case 'En Recepción': return Colors.purple;
    case 'Recibida': return Colors.teal;
    case 'Cancelada': return const Color.fromARGB(255, 61, 61, 61);
    default: return Colors.grey;
  }
}

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Pendiente': return const Color.fromARGB(255, 158, 158, 158).withOpacity(0.1);
      case 'Enviada': return Colors.blue.withOpacity(0.1);
      case 'Por Aprobar': return Colors.orange.withOpacity(0.1);
      case 'Confirmada': return Colors.green.withOpacity(0.1);
      case 'En Recepción': return Colors.purple.withOpacity(0.1);
      case 'Recibida': return Colors.teal.withOpacity(0.1);
      case 'Cancelada': return const Color.fromARGB(255, 58, 57, 57).withOpacity(0.1);
      default: return Colors.grey.withOpacity(0.1);
    } 
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente': return Icons.description;
      case 'Enviada': return Icons.send;
      case 'Por Aprobar': return Icons.pending;
      case 'Confirmada': return Icons.check_circle;
      case 'En Recepción': return Icons.local_shipping;
      case 'Recibida': return Icons.inventory_2;
      case 'Cancelada': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pendiente': return "Orden recién creada - Pendiente de confirmación";
      case 'Enviada': return "Cotización enviada al proveedor";
      case 'Por Aprobar': return "Esperando aprobación";
      case 'Confirmada': return "Orden confirmada - En proceso de compra";
      case 'En Recepción': return "Productos en proceso de recepción";
      case 'Recibida': return "Orden recibida y finalizada";
      case 'Cancelada': return "Orden cancelada";
      default: return "Estado desconocido";
    }
  }

  // FUNCIÓN MEJORADA PARA DETERMINAR ESTADO VISUAL
String _getEstadoVisual(Map<String, dynamic> order) {
  final estadoOdoo = order['state_odoo'] ?? 'draft';
  final receiptStatus = order['receipt_status'];
  final invoiceStatus = order['invoice_status'];
  
  print('🔍 Analizando orden - Odoo: $estadoOdoo, Receipt: $receiptStatus, Invoice: $invoiceStatus');
  
  // ✅ PRIMERO: Si está CANCELADA, mostrar Cancelada
  if (estadoOdoo == 'cancel') {
    return 'Cancelada';
  }
  
  // ✅ SEGUNDO: Verificar recepción (tiene prioridad sobre el estado general)
  if (receiptStatus == 'full') {
    return 'Recibida';
  }
  
  if (receiptStatus == 'partial') {
    return 'En Recepción';
  }
  
  // ✅ TERCERO: Verificar facturación
  if (invoiceStatus == 'invoiced') {
    return 'Facturada';
  }
  
  if (invoiceStatus == 'to invoice') {
    return 'Por Facturar';
  }
  
  // ✅ CUARTO: Usar el mapeo básico del estado Odoo
  return _mapearEstadoOdoo(estadoOdoo);
}
  // 🎯 ACTUALIZA _aplicarFiltros
  void _aplicarFiltros() {
    setState(() {
      _resultadosCount = _ordenesLocales.where((order) {
        return estadoFiltro == "Todas" || order['estado'] == estadoFiltro;
      }).length;
    });
  }

  // 🎯 ACTUALIZA _buildOrdersList
  Widget _buildOrdersList() {
    List<Map<String, dynamic>> filteredOrders = _ordenesLocales.where((order) {
      final estadoMatch = estadoFiltro == "Todas" || order['estado'] == estadoFiltro;
      return estadoMatch; 
    }).toList();

    _sortOrdersByDate();

    if (filteredOrders.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8), 
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order, order['estado'] == "Recibida",
            showProveedor: true, showArticulo: true);
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(),
                  decoration: InputDecoration(
                    hintText: 'Buscar órdenes de compra...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    estadoFiltro = value;
                    _aplicarFiltros();
                  });
                },
                itemBuilder: (context) => [
                  'Todas',
                  'Presupuesto',
                  'Enviada', 
                  'Por Aprobar',
                  'Confirmada',
                  'En Recepción',
                  'Recibida',
                  'Cancelada',
                ].map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(estadoFiltro),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(estadoFiltro),
                      const SizedBox(width: 4),
                      const Icon(Icons.filter_list, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _crearNuevaOrden() async {
    final proveedorSeleccionado = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (context) => ProveedoresScreen(
          onSupplierPageNavigate: (proveedor) {
            Navigator.pop(context, proveedor);
          },
        ),
      ),
    );

    if (proveedorSeleccionado != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrearOrdenCompraScreen(
            proveedor: proveedorSeleccionado,
            onOrdenCreada: (orden, proveedor, articulos) {
              _agregarOrden({
                'orden': orden.id,
                'proveedor': proveedor.name,
                'articulo': articulos.isNotEmpty ? articulos.first.nombre : '',
                'articulos': articulos.map((a) => {
                  'nombre': a.nombre,
                  'cantidad': a.cantidad,
                  'precio': a.precio,
                  'categoria': a.categoria,
                  'subcategoria': a.subcategoria,
                }).toList(),
                'fecha': orden.date.toString(),
                'estado': orden.status ?? 'Presupuesto',
                'total': orden.total,
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '',
        onOrdenTerminada: () {
          setState(() {});
        },
        showTitle: false,
      ),
      drawer: AppDrawer(
        onItemTapped: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // 🔹 Título 
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Órdenes de compra',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // ✅ NUEVA SECCIÓN DE FILTROS COMO EN VENTAS
          _buildFilterSection(),
          
          // 🔹 Contador de resultados
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_resultadosCount resultados',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (estadoFiltro != "Todas")
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        estadoFiltro = "Todas";
                        _aplicarFiltros();
                      });
                    },
                    child: Text(
                      'Limpiar filtro',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de órdenes
          Expanded(child: _buildOrdersList()),
        ],
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildDebugButton(),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "nuevaOrdenCompra",
            onPressed: _crearNuevaOrden,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 🎯 ACTUALIZA _sortOrdersByDate
  void _sortOrdersByDate() {
    setState(() {
      _ordenesLocales.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fecha']) ?? DateTime.now();
        final fechaB = DateTime.tryParse(b['fecha']) ?? DateTime.now();
        return _ordenFecha == "ASC"
            ? fechaA.compareTo(fechaB)
            : fechaB.compareTo(fechaA);
      });
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: index),
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isRecibida,
      {bool showProveedor = true, bool showArticulo = true}) {
    // Obtener la lista de artículos (si existe)
    final List<dynamic> articulos = order['articulos'] ?? [];
    final bool tieneMultiplesArticulos = articulos.length > 1;
    
    // 🎯 USAR EL NUEVO SISTEMA DE ESTADOS
    final estadoVisual = _getEstadoVisual(order);
    final estadoOdoo = order['state_odoo'] ?? 'draft';
    
    // 🎯 DETERMINAR BOTONES DISPONIBLES
    final puedeConfirmar = estadoOdoo == 'draft' || estadoOdoo == 'to approve';
    final puedeEnviar = estadoOdoo == 'draft';
    final puedeCancelar = estadoOdoo != 'cancel' && estadoVisual != 'Recibida';
    final puedeMarcarRecibida = estadoOdoo == 'purchase' && estadoVisual != 'Recibida';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(estadoVisual).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ✅ BARRA LATERAL DE COLOR COMO EN VENTAS
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: _getStatusColor(estadoVisual),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Contenido de la orden
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con información principal
                  Row(
                    children: [
                      // Icono de estado (más pequeño)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(estadoVisual),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(estadoVisual),
                          color: _getStatusColor(estadoVisual),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Información del proveedor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showProveedor)
                              Text(
                                order['proveedor'] ?? "Proveedor desconocido",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            
                            // Fecha y estado
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(order['fecha']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 🎯 COLUMNA DERECHA - TOTAL Y BOTONES
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Total de la orden
                          Text(
                            "\$${order['total']?.toStringAsFixed(2) ?? '0.00'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // ✅ BADGE DE ESTADO COMPACTO
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusBackgroundColor(estadoVisual),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estadoVisual,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: _getStatusColor(estadoVisual),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 🎯 BOTONES DE ACCIÓN (EN COLUMNA)
                          Column(
                            children: [
                              if (puedeConfirmar)
                                _buildActionButton('Confirmar', Icons.check, Colors.blue, 
                                  () => _confirmarOrden(order['orden'])),
                              
                              if (puedeEnviar)
                                _buildActionButton('Enviar', Icons.send, Colors.blue, 
                                  () => _enviarCotizacion(order['orden'])),
                              
                              if (puedeMarcarRecibida)
                                _buildActionButton('Recibir', Icons.inventory_2, Colors.green, 
                                  () => _marcarRecibida(order['orden'])),
                              
                              if (puedeCancelar)
                                _buildActionButton('Cancelar', Icons.cancel, Colors.red, 
                                  () => _cancelarOrden(order['orden'])),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  
                  // Sección de artículos
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Artículos:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      if (articulos.isEmpty)
                        _buildArticuloItemCompact(
                          nombre: order['articulo'] ?? "Sin artículo especificado",
                          cantidad: 1,
                          precio: order['total'] ?? 0.0,
                        )
                      else if (tieneMultiplesArticulos)
                        Column(
                          children: [
                            _buildArticuloItemCompact(
                              nombre: articulos.first['nombre'] ?? "Artículo",
                              cantidad: articulos.first['cantidad'] ?? 1,
                              precio: articulos.first['precio'] ?? 0.0,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "+ ${articulos.length - 1} artículo(s) más",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        _buildArticuloItemCompact(
                          nombre: articulos.first['nombre'] ?? "Artículo",
                          cantidad: articulos.first['cantidad'] ?? 1,
                          precio: articulos.first['precio'] ?? 0.0,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Footer con información adicional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cantidad total de artículos
                      if (articulos.isNotEmpty)
                        Text(
                          "${articulos.fold(0, (sum, item) => sum + (item['cantidad'] as int? ?? 1))} items",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        const Text(
                          "1 item",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      
                      // Botón para ver detalles
                      TextButton(
                        onPressed: () => _mostrarDetallesOrden(order),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 24),
                        ),
                        child: Text(
                          "Ver detalles",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                          ),
                        ),
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

  // 🎯 WIDGET PARA BOTONES DE ACCIÓN
  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 12),
        label: Text(text, style: const TextStyle(fontSize: 10)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 0),
        ),
      ),
    );
  }

  // ✅ CONFIRMAR ORDEN
  Future<void> _confirmarOrden(String orderId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Orden de Compra'),
        content: Text('¿Confirmar la orden de compra $orderId? Esto cambiará el estado a "Confirmada".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _ejecutarAccionOrden(
        orderId, 
        'confirmar', 
        'Confirmando orden de compra...',
        '✅ Orden de compra $orderId confirmada'
      );
    }
  }

  // ✅ ENVIAR COTIZACIÓN
  Future<void> _enviarCotizacion(String orderId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enviar Cotización'),
        content: Text('¿Enviar cotización de la orden de compra $orderId al proveedor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Enviar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _ejecutarAccionOrden(
        orderId, 
        'enviar', 
        'Enviando cotización...',
        '✅ Cotización $orderId enviada'
      );
    }
  }

  // ✅ MARCAR COMO RECIBIDA
  Future<void> _marcarRecibida(String orderId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como Recibida'),
        content: Text('¿Marcar la orden de compra $orderId como recibida/entregada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Recibir', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _ejecutarAccionOrden(
        orderId, 
        'recibir', 
        'Marcando como recibida...',
        '✅ Orden de compra $orderId recibida'
      );
    }
  }

  // ✅ CANCELAR ORDEN
  Future<void> _cancelarOrden(String orderId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Orden de Compra'),
        content: Text('¿Cancelar la orden de compra $orderId? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _ejecutarAccionOrden(
        orderId, 
        'cancelar', 
        'Cancelando orden...',
        '✅ Orden de compra $orderId cancelada'
      );
    }
  }

  // 🎯 MÉTODO PRINCIPAL PARA EJECUTAR ACCIONES
  Future<void> _ejecutarAccionOrden(
    String orderId, 
    String accion, 
    String mensajeLoading,
    String mensajeExito
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(mensajeLoading),
          ],
        ),
      ),
    );

    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        Map<String, dynamic> resultado;

        // EJECUTAR ACCIÓN CORRESPONDIENTE
        switch (accion) {
          case 'confirmar':
            resultado = await _purchaseService.confirmPurchaseOrder(int.parse(orderId));
            break;
          case 'enviar':
            resultado = await _purchaseService.sendPurchaseOrder(int.parse(orderId));
            break;
          case 'recibir':
            resultado = await _purchaseService.markAsReceived(int.parse(orderId));
            break;
          case 'cancelar':
            resultado = await _purchaseService.cancelPurchaseOrder(int.parse(orderId));
            break;
          default:
            resultado = {'success': false, 'error': 'Acción no válida'};
        }

        Navigator.pop(context); // Cerrar loading

        if (resultado['success']) {
          // Recargar los datos de la orden
          final ordenActualizada = await _purchaseService.getOrderDetails(int.parse(orderId));
          
          setState(() {
            final index = _ordenesLocales.indexWhere(
              (order) => order['orden'] == orderId
            );
            if (index != -1 && ordenActualizada.isNotEmpty) {
              // Actualizar datos de la orden
              _ordenesLocales[index]['state_odoo'] = ordenActualizada['state'];
              _ordenesLocales[index]['receipt_status'] = ordenActualizada['receipt_status'];
              _ordenesLocales[index]['note'] = ordenActualizada['note'];
              _ordenesLocales[index]['estado'] = _getEstadoVisual(ordenActualizada);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeExito),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${resultado['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ NUEVO MÉTODO PARA ARTÍCULOS COMPACTOS
  Widget _buildArticuloItemCompact({
    required String nombre,
    required int cantidad,
    required double precio,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.shopping_bag, size: 12, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "$cantidad x \$${precio.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          "\$${(cantidad * precio).toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  void _mostrarDetallesOrden(Map<String, dynamic> order) {
    final List<dynamic> articulos = order['articulos'] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Detalles de la orden de compra",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              
              // Información general
              _buildDetalleItem("Proveedor", order['proveedor'] ?? "Desconocido"),
              _buildDetalleItem("Fecha", _formatDate(order['fecha'])),
              _buildDetalleItem("Estado", order['estado'] ?? "Desconocido"),
              _buildDetalleItem("Orden #", order['orden']?.toString() ?? "N/A"),
              
              const SizedBox(height: 16),
              const Text(
                "Artículos:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(),
              
              // Lista de artículos
              Expanded(
                child: articulos.isEmpty
                    ? Center(
                        child: Text(
                          order['articulo'] ?? "Sin artículo especificado",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: articulos.length,
                        itemBuilder: (context, index) {
                          final articulo = articulos[index];
                          return _buildArticuloDetalle(articulo);
                        },
                      ),
              ),
              
              const Divider(),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "\$${order['total']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$titulo:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticuloDetalle(Map<String, dynamic> articulo) {
    final cantidad = articulo['cantidad'] ?? 1;
    final precio = articulo['precio'] ?? 0.0;
    final total = cantidad * precio;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articulo['nombre'] ?? "Artículo",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  "${articulo['categoria'] ?? ''} • ${articulo['subcategoria'] ?? ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                "$cantidad x \$${precio.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
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
          Icon(Icons.shopping_cart, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No hay órdenes de compra",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text("Intenta ajustar los filtros o crear una nueva orden",
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ],
      ));
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString.split(' ')[0];
    }
  }
}

// 🎯 SERVICIO DE COMPRAS EXTENDIDO
class OdooPurchaseService {
  final OdooServiceEnhanced odooService;

  OdooPurchaseService(this.odooService);

  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'search_read',
          [
            [] // Dominio vacío para todas las órdenes
          ],
          {
            'fields': [
              'id', 'name', 'partner_id', 'date_order', 'state',
              'amount_total', 'order_line', 'receipt_status', 
              'invoice_status', 'date_planned'
            ],
            'limit': 50,
          }
        ],
      });

      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo órdenes de compra: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
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
            'fields': [
              'id', 'name', 'partner_id', 'date_order', 'state',
              'amount_total', 'order_line', 'receipt_status', 
              'invoice_status', 'date_planned', 'note'
            ],
          }
        ],
      });

      final orders = (result as List).cast<Map<String, dynamic>>();
      return orders.isNotEmpty ? orders.first : {};
    } catch (e) {
      print('❌ Error obteniendo detalles de orden: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> createPurchaseOrder({
    required int partnerId,
    required List<Map<String, dynamic>> orderLines,
    String? datePlanned,
    String? notes,
  }) async {
    try {
      // Preparar líneas de orden
      final orderLineValues = orderLines.map((line) {
        return [
          0, 0, {
            'product_id': line['product_id'],
            'product_qty': line['quantity'],
            'price_unit': line['price_unit'],
            'name': line['name'] ?? 'Product',
          }
        ];
      }).toList();

      final values = {
        'partner_id': partnerId,
        'order_line': orderLineValues,
        'date_planned': datePlanned ?? _getDefaultDeliveryDate(),
        'notes': notes,
      };

      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'create',
          [values]
        ],
      });

      return {'success': true, 'order_id': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmPurchaseOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_confirm',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendPurchaseOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_send',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markAsReceived(int orderId) async {
    try {
      // Para órdenes de compra, marcar como hecho/done
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_done',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelPurchaseOrder(int orderId) async {
    try {
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          odooService.dbName,
          odooService.uid,
          odooService.password,
          'purchase.order',
          'button_cancel',
          [[orderId]]
        ],
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  String _getDefaultDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 7));
    return '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
  }
}