import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:ecomerce_app/src/services/odoo_purchase_service.dart';
import 'package:ecomerce_app/src/presentation/screens/user/provider_selection_screen.dart'; // [NEW]
import 'package:ecomerce_app/src/presentation/screens/user/new_purchase_order_page.dart'; // [NEW]



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
        baseUrl: ApiConfig.baseUrl,
        dbName: 'pointsales-v18',
      );
      _purchaseService = OdooPurchaseService(fallbackService);
    }
  }

   Future<void> _diagnosticoProfundoLHM() async {
    try {
      print('🔍 DIAGNÓSTICO PROFUNDO L M H:');
      
      // 1. Verificar compañía del usuario
      final userCompany = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'res.users',
          'read',
          [[_purchaseService.odooService.uid]],
          {'fields': ['id', 'name', 'company_id', 'company_ids']}
        ],
      });
      
      final userData = (userCompany as List).first;
      print('   🏢 Usuario - Compañía: ${userData['company_id']}');
      print('   📋 Compañías disponibles: ${userData['company_ids']}');
      
      // 2. Verificar compañía del proveedor L M H
      final partnerCompany = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'res.partner',
          'read',
          [[13]],
          {'fields': ['id', 'name', 'company_id']}
        ],
      });
      
      final partnerData = (partnerCompany as List).first;
      print('   🏢 Proveedor - Compañía: ${partnerData['company_id']}');
      
      // 3. Verificar reglas de seguridad
      print('   🔒 Verificando reglas de seguridad...');
      final rules = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'ir.rule',
          'search_read',
          [
            [
              ['model_id.model', '=', 'res.partner']
            ]
          ],
          {'fields': ['id', 'name', 'domain_force']}
        ],
      });
      
      print('   📜 Reglas de partner: ${(rules as List).length}');
      for (var rule in (rules as List)) {
        print('      - ${rule['name']}: ${rule['domain_force']}');
      }
      
    } catch (e) {
      print('❌ Error diagnóstico profundo: $e');
    }
  }
   // DIAGNÓSTICO DE PERMISOS
  Future<void> _diagnosticarPermisos() async {
    try {
      print('🔐 DIAGNÓSTICO DE PERMISOS:');
      
      // 1. Verificar usuario actual
      final userResult = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'res.users',
          'read',
          [[_purchaseService.odooService.uid]],
          {'fields': ['id', 'name', 'login', 'groups_id']}
        ],
      });
      
      final userData = (userResult as List).first;
      print('   👤 Usuario actual: ${userData['name']} (ID: ${userData['id']})');
      
      // 2. Buscar proveedores accesibles
      final accessiblePartners = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'res.partner',
          'search_read',
          [[['company_type', '=', 'company']]],
          {'fields': ['id', 'name'], 'limit': 5}
        ],
      });
      
      print('   📋 Proveedores accesibles:');
      for (var partner in (accessiblePartners as List)) {
        print('      - ID: ${partner['id']}, Nombre: ${partner['name']}');
      }
      
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
    }
  }
  // 🎯 BUSCAR PROVEEDOR ACCESIBLE
  Future<Customer?> _obtenerProveedorAccesible() async {
    try {
      print('🔍 Buscando proveedores accesibles...');
      
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
              ['company_type', '=', 'company'],
              ['active', '=', true]
            ]
          ],
          {
            'fields': ['id', 'name', 'email', 'vat'],
            'limit': 10,
            'order': 'id asc'
          }
        ],
      });

      final proveedores = (result as List).cast<Map<String, dynamic>>();
      print('🎯 Proveedores accesibles encontrados: ${proveedores.length}');
      
      if (proveedores.isEmpty) {
        print('❌ No hay proveedores accesibles para el usuario actual');
        return null;
      }
      
      // Tomar el primer proveedor accesible
      final proveedor = proveedores.first;
      final customer = Customer(
        id: proveedor['id'],
        name: proveedor['name'],
        email: proveedor['email'] ?? '',
        vat: proveedor['vat'] ?? '',
        isCompany: true,
      );
      
      print('✅ Proveedor accesible seleccionado: ${customer.name} (ID: ${customer.id})');
      return customer;
      
    } catch (e) {
      print('❌ Error buscando proveedores accesibles: $e');
      return null;
    }
  }
  // 🎯 VERIFICAR ACCESIBILIDAD
  Future<bool> _verificarProveedorAccesible(int partnerId) async {
    try {
      final result = await _purchaseService.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _purchaseService.odooService.dbName,
          _purchaseService.odooService.uid,
          _purchaseService.odooService.password,
          'res.partner',
          'search_count',
          [[['id', '=', partnerId]]]
        ],
      });
      
      return (result as int) > 0;
    } catch (e) {
      return false;
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
    print('   📝 Note: ${orden['notes']}');
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
    final ordenesOdoo = await _purchaseService.getPurchaseOrders();
    
    print('📥 Datos crudos de Odoo recibidos: ${ordenesOdoo.length} órdenes');
    
    setState(() {
      _ordenesLocales = ordenesOdoo.map((ordenOdoo) {
        // PROVEEDOR
        final proveedor = ordenOdoo['partner_id'] is List 
            ? (ordenOdoo['partner_id'][1] as String) 
            : 'Proveedor Odoo';
        
        // ✅ **CORRECCIÓN: Obtener artículos de order_line_details**
        final List<Map<String, dynamic>> articulos = [];
        
        final lineDetails = ordenOdoo['order_line_details'] ?? [];
        
        if (lineDetails.isNotEmpty) {
          print('   🔍 Orden ${ordenOdoo['name']} tiene ${lineDetails.length} líneas detalladas');
          
          for (var line in lineDetails) {
            // ✅ CORRECTO: Usar los campos reales de _getOrderLineDetails
            final productName = line['name'] ?? 'Producto sin nombre';
            final productId = line['product_id'] ?? 0;
            final cantidad = line['quantity'] ?? 0.0;  // ✅ Ahora es 'quantity'
            final precio = line['price_unit'] ?? 0.0;
            final subtotal = line['price_subtotal'] ?? 0.0;
            final descripcion = line['description'] ?? productName;
            
            if (cantidad > 0) {
              articulos.add({
                'id': line['id'],
                'product_id': productId,
                'nombre': productName,
                'cantidad': cantidad,
                'precio': precio,
                'subtotal': subtotal,
                'descripcion': descripcion,
              });
              
              print('      📦 ${productName} x$cantidad = \$$subtotal');
            }
          }
        } else {
          // ✅ Si no hay detalles, mostrar información básica de la orden
          print('   ⚠️ Orden ${ordenOdoo['name']} no tiene detalles de líneas');
          
          // Usar información básica de la orden
          articulos.add({
            'id': ordenOdoo['id'],
            'product_id': 0,
            'nombre': 'Orden #${ordenOdoo['name']}',
            'cantidad': 1,
            'precio': ordenOdoo['amount_total'] ?? 0.0,
            'subtotal': ordenOdoo['amount_total'] ?? 0.0,
            'descripcion': 'Orden de compra ${ordenOdoo['name']}',
          });
        }
        
        
        // 🔍 DEBUG: Verificar fecha de Odoo
        print('   📅 Fecha de orden ${ordenOdoo['name']}:');
        print('      date_order RAW: ${ordenOdoo['date_order']}');
        print('      date_order TYPE: ${ordenOdoo['date_order'].runtimeType}');
        
        // DEBUG: Valores monetarios
        print('   💰 Valores de orden ${ordenOdoo['name']}:');
        print('      amount_untaxed (subtotal): ${ordenOdoo['amount_untaxed']}');
        print('      amount_tax (ITBIS): ${ordenOdoo['amount_tax']}');
        print('      amount_total (total): ${ordenOdoo['amount_total']}');
        
        // ORDEN COMPLETA
        final ordenCompleta = {
          'orden': ordenOdoo['id'].toString(),
          'proveedor': proveedor,
          'fecha': ordenOdoo['date_order'] ?? DateTime.now().toString(),
          'estado': _getEstadoVisual(ordenOdoo),
          'state_odoo': ordenOdoo['state'] ?? 'draft',
          'receipt_status': ordenOdoo['receipt_status'] ?? '',
          'invoice_status': ordenOdoo['invoice_status'] ?? '',
          'note': ordenOdoo['notes'] is String ? ordenOdoo['notes'] : '',
          'total': (ordenOdoo['amount_untaxed'] ?? 0.0).toDouble(),  // ✅ Subtotal SIN ITBIS
          'amount_total': (ordenOdoo['amount_total'] ?? 0.0).toDouble(),  // Total con/sin impuestos
          'amount_tax': (ordenOdoo['amount_tax'] ?? 0.0).toDouble(),  // ITBIS
          'referencia_odoo': ordenOdoo['name'] ?? 'Orden sin nombre',
          'date_planned': ordenOdoo['date_planned'] ?? '',
          'articulos': articulos,  // ✅ AHORA SÍ TIENE ARTÍCULOS REALES
        };
        
        print('   📊 Orden ${ordenOdoo['name']} mapeada - Subtotal: \$${ordenCompleta['total']}, ITBIS: \$${ordenCompleta['amount_tax']}, Total: \$${ordenCompleta['amount_total']}');
        return ordenCompleta;
      }).toList();
      
      _resultadosCount = _ordenesLocales.length;
    });
    
    print('✅ Total órdenes cargadas: ${_ordenesLocales.length}');
    
    // DEBUG: Mostrar resumen detallado
    _verificarDatosOrdenesCompletos();
    
  } catch (e) {
    print('❌ Error cargando órdenes de compra: $e');
    _showError('Error cargando órdenes: $e');
  }
}
void _diagnosticarDatosOrdenes() async {
  print('🔍 DIAGNÓSTICO PROFUNDO DE DATOS ODDO:');
  
  try {
    // Verificar una orden específica (ejemplo ID 54)
    final testOrderId = 54;
    final testOrder = await _purchaseService.getOrderDetails(testOrderId);
    
    print('📋 Datos crudos de orden $testOrderId:');
    print('   ID: ${testOrder['id']}');
    print('   Nombre: ${testOrder['name']}');
    print('   order_line: ${testOrder['order_line']}');
    print('   order_line_details: ${testOrder['order_line_details']}');
    
    if (testOrder['order_line_details'] != null) {
      final lines = testOrder['order_line_details'] as List;
      print('   📦 Líneas detalladas: ${lines.length}');
      
      for (var line in lines) {
        print('      - ${line['name']} (ID: ${line['id']})');
        print('        Cantidad: ${line['quantity']}');
        print('        Precio: ${line['price_unit']}');
      }
    }
  } catch (e) {
    print('❌ Error en diagnóstico: $e');
  }
}

void _verificarDatosOrdenesCompletos() {
  print('🔍 DIAGNÓSTICO COMPLETO DE DATOS DE ÓRDENES:');
  
  for (var orden in _ordenesLocales) {
    print('═══════════════════════════════════════════════════════════');
    print('📋 Orden ID: ${orden['orden']}');
    print('   Nombre Odoo: ${orden['referencia_odoo']}');
    print('   Proveedor: ${orden['proveedor']}');
    print('   Estado: ${orden['estado']}');
    print('   Total: \$${orden['total']}');
    print('   Fecha: ${orden['fecha']}');
    
    // Verificar artículos
    final articulos = orden['articulos'] ?? [];
    print('   📦 Número de artículos: ${articulos.length}');
    
    if (articulos.isEmpty) {
      print('   ⚠️ NO HAY ARTÍCULOS EN ESTA ORDEN');
    } else {
      for (var i = 0; i < articulos.length; i++) {
        final articulo = articulos[i];
        print('      ${i + 1}. ${articulo['nombre']}');
        print('         ID: ${articulo['id']}');
        print('         Product ID: ${articulo['product_id']}');
        print('         Cantidad: ${articulo['cantidad']}');
        print('         Precio: \$${articulo['precio']}');
        print('         Subtotal: \$${articulo['subtotal']}');
        print('         Descripción: ${articulo['descripcion']}');
      }
    }
    
    // Verificar si la orden tiene líneas en Odoo
    print('   🔗 order_line_details: ${orden['order_line_details'] != null ? 'SÍ' : 'NO'}');
    print('   📝 Notas: ${orden['note']}');
  }
  print('═══════════════════════════════════════════════════════════');
}

bool _esProveedorLMH(String nombreProveedor) {
  if (nombreProveedor.isEmpty) return false;
  
  // Lista COMPLETA de variantes
  final variantesAceptadas = [
    'L M H',      // Con espacios
    'L.M.H',      // Con puntos
    'LMH',        // Sin espacios
    'LHM',        // Invertido
    'l m h',      // Minúsculas
  ];
  
  final nombreLower = nombreProveedor.toLowerCase();
  
  for (var variante in variantesAceptadas) {
    if (nombreLower.contains(variante.toLowerCase())) {
      return true;
    }
  }
  
  return false;
}

// 🎯 MÉTODO MEJORADO PARA BUSCAR PROVEEDORES LMH
Future<List<Map<String, dynamic>>> _buscarProveedoresLMH() async {
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
            ['company_type', '=', 'company'],
            '|', ['name', 'ilike', 'lmh'],
            '|', ['name', 'ilike', 'lhm'],
            '|', ['name', 'ilike', 'l m h'],  // ← NUEVA BÚSQUEDA
            ['name', '=', 'L M H']            // ← BÚSQUEDA EXACTA
          ]
        ],
        {
          'fields': ['id', 'name', 'email', 'vat', 'active'],
          'limit': 20
        }
      ],
    });

    final proveedores = (result as List).cast<Map<String, dynamic>>();
    print('🎯 Proveedores LMH encontrados: ${proveedores.length}');
    for (var prov in proveedores) {
      print('   - ID: ${prov['id']}, Nombre: "${prov['name']}", Activo: ${prov['active']}');
    }
    
    return proveedores;
  } catch (e) {
    print('❌ Error buscando proveedores LMH: $e');
    return [];
  }
}
// 🎯 MÉTODO DIRECTO - OBTENER PROVEEDOR L M H
Future<Customer?> _obtenerProveedorLMHDirecto() async {
  try {
    print('🔍 Buscando proveedor L M H específico...');
    
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
            ['id', '=', 13]  // ← BUSCAR DIRECTAMENTE POR ID 13
          ]
        ],
        {
          'fields': ['id', 'name', 'email', 'vat', 'phone', 'street', 'city'],
        }
      ],
    });

    final proveedores = (result as List).cast<Map<String, dynamic>>();
    
    if (proveedores.isNotEmpty) {
      final proveedor = proveedores.first;
      final customer = Customer(
        id: proveedor['id'],
        name: proveedor['name'],
        email: proveedor['email'] ?? '',
        vat: proveedor['vat'] ?? '',
        phone: proveedor['phone'] ?? '',
        street: proveedor['street'] ?? '',
        city: proveedor['city'] ?? '',
        isCompany: true,
      );
      
      print('✅ Proveedor L M H encontrado: ${customer.name} (ID: ${customer.id})');
      return customer;
    } else {
      print('❌ Proveedor L M H (ID 13) no encontrado');
      return null;
    }
  } catch (e) {
    print('❌ Error buscando proveedor L M H: $e');
    return null;
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
        baseUrl: ApiConfig.baseUrl,
        dbName: 'pointsales-v18',
      );
      
      bool isAuthenticated = await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
      
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





Widget _buildOrdersList() {
  List<Map<String, dynamic>> filteredOrders = _ordenesLocales.where((order) {
    final estadoMatch = estadoFiltro == "Todas" || order['estado'] == estadoFiltro;
    return estadoMatch; 
  }).toList();

  _sortOrdersByDate();

  if (filteredOrders.isEmpty) return _buildEmptyState();

  // DEBUG: Verificar datos antes de construir
  for (var order in filteredOrders.take(3)) {
    _verificarUIDebug(order);
  }

  // ✅ AGREGAR REFRESHINDICATOR PARA PULL-TO-REFRESH
  return RefreshIndicator(
    onRefresh: () async {
      await _cargarOrdenesDesdeOdoo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Órdenes actualizadas'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    },
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8), 
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        
        // DEBUG para cada orden
        if (index < 3) {
          print('🔄 Construyendo tarjeta ${index + 1}: ${order['referencia_odoo']}');
        }
        
        return _buildOrderCard(order, order['estado'] == "Recibida",
            showProveedor: true, showArticulo: true);
      },
    ),
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
  // 🎯 METODO PARA CREAR NUEVA ORDEN DE COMPRA (AUTO LMH)
  void _crearNuevaOrdenCompra() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Buscar Proveedor LMH automáticamente
      final provider = await _findLHMProvider();
      
      Navigator.pop(context); // Cerrar loading

      if (provider == null) {
        // Fallback: Si no encuentra LMH, mostrar error o dejar seleccionar manual?
        // El usuario dijo "SIEMPRE SEA LMH", así que mostramos error si no está.
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('❌ No se encontró el proveedor LMH (RUT: 101717955)'), backgroundColor: Colors.red),
        );
        return;
      }

      // 2. Ir DIRECTAMENTE a Pantalla de Creación de Orden
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPurchaseOrderPage(
            supplier: provider,
            onOrderCreated: (nuevaOrden) {
               _agregarOrden(nuevaOrden);
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('❌ Error buscando LMH: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Customer?> _findLHMProvider() async {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    
    // Login silencioso
    await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
    
    // Búsqueda específica
    final result = await odooService.callKw({
      'service': 'object',
      'method': 'execute_kw',
      'args': [
        odooService.dbName,
        odooService.uid,
        odooService.password,
        'res.partner',
        'search_read',
        [
          // Criterios de búsqueda: 'OR' (|) entre RUT y Nombre
          ['|', ['vat', '=', '101717955'], ['name', 'ilike', 'LMH']]
        ],
        {
          'fields': ['id', 'name', 'email', 'vat', 'phone', 'is_company'],
          'limit': 1, // Solo necesitamos uno
        }
      ],
    });

    if (result is List && result.isNotEmpty) {
      final data = result.first as Map<String, dynamic>;
      // Mapear manualmente simple o usar el modelo si se prefiere
      return Customer(
        id: data['id'],
        name: data['name'],
        vat: data['vat'] is String ? data['vat'] : null,
        email: data['email'] is String ? data['email'] : null,
        phone: data['phone'] is String ? data['phone'] : null,
        isCompany: data['is_company'] == true,
      );
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '',

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
          
          // 🔹 Título con botón de refresh
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
                // ✅ Botón de refresh
                IconButton(
                  icon: const Icon(Icons.refresh, size: 24),
                  onPressed: () async {
                    await _cargarOrdenesDesdeOdoo();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Órdenes actualizadas'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: 'Actualizar órdenes',
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

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // _buildDebugButton(), // Opcional, mantener si es útil para debug
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "nuevaOrdenCompra",
            onPressed: _crearNuevaOrdenCompra, // ✅ Usar nuevo método
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

  // DEBUG: Verificar datos
  print('🔍 Construyendo tarjeta para orden ${order['referencia_odoo']}');
  print('   Número de artículos en datos: ${articulos.length}');
  print('   Tiene múltiples artículos: $tieneMultiplesArticulos');

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
                
                // ✅ ✅ ✅ **CORREGIDO: SECCIÓN DE ARTÍCULOS**
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
                    
                    // ✅ **CORRECCIÓN PRINCIPAL: Usar artículos reales, no order['articulo']**
                   if (articulos.isEmpty)
  _buildArticuloItemCompact(
    nombre: "Sin artículo especificado", // ✅ CORRECTO
    cantidad: 1,
    precio: 0.0,
  )
                    else if (tieneMultiplesArticulos && articulos.isNotEmpty)
                      Column(
                        children: [
                          _buildArticuloItemCompact(
                            nombre: articulos[0]['nombre'] ?? "Artículo",
                            cantidad: articulos[0]['cantidad'] ?? 1,
                            precio: articulos[0]['precio'] ?? 0.0,
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
                    else if (articulos.isNotEmpty)
                      _buildArticuloItemCompact(
                        nombre: articulos[0]['nombre'] ?? "Artículo",
                        cantidad: articulos[0]['cantidad'] ?? 1,
                        precio: articulos[0]['precio'] ?? 0.0,
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Footer con información adicional
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cantidad total de artículos
                    Text(
                      "${articulos.isNotEmpty ? articulos.length : 1} items",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
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
// Agrega este método para verificar qué está pasando en la UI
void _verificarUIDebug(Map<String, dynamic> order) {
  print('🔍 VERIFICACIÓN UI PARA ORDEN:');
  print('   Orden ID: ${order['orden']}');
  print('   Referencia: ${order['referencia_odoo']}');
  
  final articulos = order['articulos'] ?? [];
  print('   Artículos en datos: ${articulos.length}');
  
  if (articulos.isNotEmpty) {
    print('   Primer artículo: ${articulos[0]['nombre']}');
    print('   Cantidad: ${articulos[0]['cantidad']}');
    print('   Precio: ${articulos[0]['precio']}');
  } else {
    print('   ⚠️ NO HAY ARTÍCULOS EN LOS DATOS');
  }
  
  print('   Campo "articulo" existe: ${order.containsKey('articulo')}');
  if (order.containsKey('articulo')) {
    print('   Valor de "articulo": ${order['articulo']}');
  }
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
        baseUrl: ApiConfig.baseUrl,
        dbName: 'pointsales-v18',
      );
      
      bool isAuthenticated = await odooService.login(ApiConfig.defaultUsername, ApiConfig.defaultPassword);
      
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
              _ordenesLocales[index]['notes'] = ordenActualizada['notes'];
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

  Widget _buildArticuloItemCompact({
  required String nombre,
  required dynamic cantidad,
  required dynamic precio,
}) {
  // ✅ Manejar nulos y conversiones
  final cant = cantidad is int ? cantidad : 
              cantidad is double ? cantidad.toInt() : 1;
  final prec = precio is double ? precio : 
              precio is int ? precio.toDouble() : 0.0;
  final total = cant * prec;
  
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
              "$cant x \$${prec.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      Text(
        "\$${total.toStringAsFixed(2)}",
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
  
  // DEBUG detallado
  print('🔍 MOSTRAR DETALLES DE ORDEN - COMPLETO:');
  print('   ID Orden: ${order['orden']}');
  print('   Referencia Odoo: ${order['referencia_odoo']}');
  print('   Proveedor: ${order['proveedor']}');
  print('   Total: \$${order['total']}');
  print('   Número de artículos: ${articulos.length}');
  
  for (var i = 0; i < articulos.length; i++) {
    print('   Artículo ${i + 1}: ${articulos[i]['nombre']}');
  }
  
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
            // Header mejorado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detalles de la orden de compra",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        "#${order['referencia_odoo']} • ${order['proveedor']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // Información general en tarjetas
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    "Fecha",
                    _formatDate(order['fecha']),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    "Orden",
                    order['referencia_odoo'] ?? "N/A",
                    Icons.tag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    "Estado",
                    order['estado'] ?? "Desconocido",
                    _getStatusIcon(order['estado'] ?? ''),
                    _getStatusColor(order['estado'] ?? ''),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Encabezado de artículos con subtotal + ITBIS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "Artículos (${articulos.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(
                        "\$${(order['total'] ?? 0.0).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // ITBIS (valor real de Odoo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ITBIS:', style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                        "\$${(order['amount_tax'] ?? 0.0).toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  // Total (con impuestos desde Odoo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "\$${(order['amount_total'] ?? 0.0).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            
            // Lista de artículos
            Expanded(
              child: articulos.isEmpty
                  ? _buildEmptyDetailsState()
                  : ListView.builder(
                      itemCount: articulos.length,
                      itemBuilder: (context, index) {
                        final articulo = articulos[index];
                        return _buildArticuloDetalle(articulo);
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

// Widget auxiliar para tarjetas de información
Widget _buildInfoCard(String titulo, String valor, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// Estado vacío mejorado para detalles
Widget _buildEmptyDetailsState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber, size: 60, color: Colors.orange.shade300),
        const SizedBox(height: 16),
        const Text(
          "No hay artículos en esta orden",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Los datos podrían estar incompletos",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
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
  final categoria = articulo['categoria'] ?? '';
  final subcategoria = articulo['subcategoria'] ?? '';
  
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
              if (categoria.isNotEmpty || subcategoria.isNotEmpty)
                Text(
                  '${categoria.isNotEmpty ? categoria : ''}${categoria.isNotEmpty && subcategoria.isNotEmpty ? ' • ' : ''}${subcategoria.isNotEmpty ? subcategoria : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              Text(
                articulo['descripcion'] ?? '',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No hay órdenes de compra",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text("Las órdenes se sincronizan automáticamente desde Odoo web",
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
