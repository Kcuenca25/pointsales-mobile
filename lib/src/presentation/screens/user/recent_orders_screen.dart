import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';


//VENTANA DE ORDENES DE VENTA

class RecentOrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recentOrders;
  final Customer customer;
  final String? searchQuery; 

  const RecentOrdersScreen({
    super.key,
    required this.recentOrders,
    required this.customer,
       this.searchQuery,
  });

  @override
  State<RecentOrdersScreen> createState() => _RecentOrdersScreenState();
}

class _RecentOrdersScreenState extends State<RecentOrdersScreen> {
  String estadoFiltro = "Todas";
  String _ordenFecha = "DESC";
  int _selectedIndex = 2;
  int _resultadosCount = 0;

  // 🎯 CREA UNA COPIA MUTABLE DE LAS ÓRDENES
  List<Map<String, dynamic>> _ordenesLocales = [];

 @override
  void initState() {
    super.initState();
    // 🎯 INICIALIZA CON LAS ÓRDENES DEL WIDGET
    _ordenesLocales = List<Map<String, dynamic>>.from(widget.recentOrders);
    _resultadosCount = _ordenesLocales.length;
    _cargarOrdenesDesdeOdoo(); // Cargar datos actualizados
  }
  void _agregarOrden(Map<String, dynamic> nuevaOrden) {
    setState(() {
      final ordenCompleta = {
        'orden': nuevaOrden['orden'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'cliente': nuevaOrden['cliente'] ?? 'Cliente desconocido',
        'articulo': nuevaOrden['articulo'] ?? '',
        'articulos': nuevaOrden['articulos'] ?? [],
        'fecha': nuevaOrden['fecha'] ?? DateTime.now().toString(),
        'estado': nuevaOrden['estado'] ?? 'Pendiente',
        'total': nuevaOrden['total'] ?? 0.0,
      };
      
      // 🎯 USA _ordenesLocales EN LUGAR DE widget.recentOrders
      _ordenesLocales.insert(0, ordenCompleta);
      _resultadosCount = _ordenesLocales.length;
    });
  }

// Agrega este método temporal para debug----------------PRUEBA-----------
void _verificarEstadosOrdenes() {
  print('📊 ESTADOS DE LAS ÓRDENES CARGADAS:');
  for (var orden in _ordenesLocales) {
    print('Orden ${orden['referencia_odoo']}:');
    print('  - Estado Odoo: ${orden['state_odoo']}');
    print('  - Estado Visual: ${orden['estado']}');
    print('  - Invoice Status: ${orden['invoice_status']}');
    print('  - Note: ${orden['note']}');
    print('  ---');
  }
}


  // 🎯 ACTUALIZA _cargarOrdenesDesdeOdoo
  Future<void> _cargarOrdenesDesdeOdoo() async {
    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        final orderService = OdooOrderService(odooService);
        final ordenesOdoo = await orderService.getSaleOrders();
        
         setState(() {
      _ordenesLocales = ordenesOdoo.map((ordenOdoo) {
        return {
          'orden': ordenOdoo['id'].toString(),
          'cliente': ordenOdoo['partner_id'] is List 
              ? (ordenOdoo['partner_id'][1] as String) 
              : 'Cliente Odoo',
          'fecha': ordenOdoo['date_order'],
          'estado': _getEstadoVisual(ordenOdoo),
          'state_odoo': ordenOdoo['state'],
          'invoice_status': ordenOdoo['invoice_status'],
          'note': ordenOdoo['note'],
          'total': (ordenOdoo['amount_total'] as num).toDouble(),
          'referencia_odoo': ordenOdoo['name'],
        };
      }).toList();
      
      _resultadosCount = _ordenesLocales.length;
    });
    
            _verificarEstadosOrdenes();

        //print('✅ Órdenes cargadas desde Odoo: ${ordenesOdoo.length}');
      }
    } catch (e) {
      print('❌ Error cargando órdenes: $e');
    }
  }

//--------------PRUEBA------------------------------------------------------
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
          Text("Creando orden de prueba..."),
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
      final orderService = OdooOrderService(odooService);
      
      // Crear orden en estado draft
      final resultado = await orderService.createSaleOrder(
        partnerId: 9, // Alexander
        orderLines: [
          {
            'product_id': 14, // Zapatos H No.7 Lila
            'quantity': 2,
            'price_unit': 1253.39,
          }
        ],
      );

      Navigator.pop(context);

      if (resultado['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Orden de prueba creada (ID: ${resultado['order_id']})'),
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

// Agrega un botón temporal en tu UI
Widget _buildDebugButton() {
  return FloatingActionButton(
    heroTag: "debug",
    onPressed: _crearOrdenPrueba,
    backgroundColor: Colors.orange,
    mini: true,
    child: Icon(Icons.bug_report, color: Colors.white),
  );
}


//-------------------------------------------------------------------------------------------


// 🎯 FUNCIONES ACTUALIZADAS PARA LOS NUEVOS ESTADOS
String _mapearEstadoOdoo(String estadoOdoo) {
  switch (estadoOdoo) {
    case 'draft': return 'Pendiente';
    case 'sent': return 'Enviada';
    case 'sale': return 'En Proceso';
    case 'cancel': return 'Cancelada';
    default: return 'Pendiente';
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'Pendiente': return Colors.grey;
    case 'Enviada': return Colors.blue;
    case 'En Proceso': return Colors.orange;
    case 'Facturada': return Colors.purple;
    case 'Completada': return Colors.green;
    case 'Cancelada': return Colors.red;
    default: return Colors.grey;
  }
}

Color _getStatusBackgroundColor(String status) {
  switch (status) {
    case 'Pendiente': return Colors.grey.withOpacity(0.1);
    case 'Enviada': return Colors.blue.withOpacity(0.1);
    case 'En Proceso': return Colors.orange.withOpacity(0.1);
    case 'Facturada': return Colors.purple.withOpacity(0.1);
    case 'Completada': return Colors.green.withOpacity(0.1);
    case 'Cancelada': return Colors.red.withOpacity(0.1);
    default: return Colors.grey.withOpacity(0.1);
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'Pendiente': return Icons.pending_actions;
    case 'Enviada': return Icons.send;
    case 'En Proceso': return Icons.build;
    case 'Facturada': return Icons.receipt;
    case 'Completada': return Icons.verified;
    case 'Cancelada': return Icons.cancel;
    default: return Icons.help;
  }
}

String _getStatusDescription(String status) {
  switch (status) {
    case 'Pendiente': return "Orden recién creada - Pendiente de confirmación";
    case 'Enviada': return "Cotización enviada al cliente";
    case 'En Proceso': return "Orden confirmada - En proceso de elaboración";
    case 'Facturada': return "Orden facturada - Proceso completado";
    case 'Completada': return "Orden entregada y finalizada";
    case 'Cancelada': return "Orden cancelada";
    default: return "Estado desconocido";
  }
}

//  FUNCIÓN MEJORADA PARA DETERMINAR ESTADO VISUAL
String _getEstadoVisual(Map<String, dynamic> order) {
  final estadoOdoo = order['state_odoo'] ?? 'draft';
  final invoiceStatus = order['invoice_status'] ?? 'no';
  final note = order['note'] ?? '';
  
  // Si tiene nota de completado, mostrar como "Completada"
  if (note.contains('✅') || note.contains('completado')) {
    return 'Completada';
  }
  
  // Si está facturada, mostrar como "Facturada"
  if (invoiceStatus == 'invoiced') {
    return 'Facturada';
  }
  
  // Usar mapeo normal de Odoo
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
        return _buildOrderCard(order, order['estado'] == "Pagada",
            showCliente: true, showArticulo: true);
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
                  hintText: 'Buscar órdenes...',
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
                'Recibida',
                'En Proceso', 
                'Terminado',
                'Cancelado',
                'Pendiente',
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


//  void _abrirOrdenarBottomSheet() {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (_) {
//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: const [
//                 Icon(Icons.sort, color: Colors.blue),
//                 SizedBox(width: 8),
//                 Text(
//                   "Ordenar por",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.arrow_upward, color: Colors.blue),
//               title: const Text("Más antiguas primero"),
//               onTap: () {
//                 setState(() => _ordenFecha = "ASC");
//                 _sortOrdersByDate();
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.arrow_downward, color: Colors.blue),
//               title: const Text("Más recientes primero"),
//               onTap: () {
//                 setState(() => _ordenFecha = "DESC");
//                 _sortOrdersByDate();
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }



void _crearNuevaOrden() async {
  final customerSeleccionado = await Navigator.push<Customer>(
    context,
    MaterialPageRoute(
      builder: (context) => ClientScreen(
        onCustomerPageNavigate: (customer) {
          Navigator.pop(context, customer);
        },
      ),
    ),
  );

  if (customerSeleccionado != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaOrdenPage(
          customer: customerSeleccionado,
          onOrdenCreada: (orden, customer, articulos) {
            _agregarOrden({
              'orden': orden.id,
              'cliente': customer.name,
              'articulo': articulos.isNotEmpty ? articulos.first.nombre : '',
              'articulos': articulos.map((a) => {
                'nombre': a.nombre,
                'cantidad': a.cantidad,
                'precio': a.precio,
                'categoria': a.categoria,
                'subcategoria': a.subcategoria,
              }).toList(),
              'fecha': orden.date.toString(),
              'estado': orden.status ?? 'Pendiente',
              'total': orden.total,
            });
          },
        ),
      ),
    );
  }
}


// Widget _buildCustomerInfo() {     //INFORMACION DEL CLIENTE .
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 16),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: Colors.blue[50],
//       borderRadius: BorderRadius.circular(8),
//       border: Border.all(color: const Color.fromARGB(255, 22, 104, 172)!),
//     ),
//     child: Row(
//       children: [
//         CircleAvatar(
//           backgroundColor: Colors.blue[100],
//           radius: 16,
//           child: Text(
//             widget.customer.name[0].toUpperCase(),
//             style: TextStyle(
//               color: Colors.blue[800],
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.customer.name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//               if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
//                 Text(
//                   widget.customer.email!,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

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
                'Órdenes de venta',
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
        

        
        // ✅ NUEVA SECCIÓN DE FILTROS COMO EN INVENTARIO
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
    floatingActionButton: FloatingActionButton(
      heroTag: "nuevaOrden",
      onPressed: _crearNuevaOrden,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, size: 28, color: Colors.white),
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

Widget _buildOrderCard(Map<String, dynamic> order, bool isPagada,
    {bool showCliente = true, bool showArticulo = true}) {
  // Obtener la lista de artículos (si existe)
  final List<dynamic> articulos = order['articulos'] ?? [];
  final bool tieneMultiplesArticulos = articulos.length > 1;
  
  // 🎯 USAR EL NUEVO SISTEMA DE ESTADOS
  final estadoVisual = _getEstadoVisual(order);
  final estadoOdoo = order['state_odoo'] ?? 'draft';
  
  // 🎯 DETERMINAR BOTONES DISPONIBLES
  final puedeConfirmar = estadoOdoo == 'draft';
  final puedeEnviar = estadoOdoo == 'draft';
  final puedeCancelar = estadoOdoo != 'cancel' && estadoVisual != 'Completada';
  final puedeMarcarCompletada = estadoOdoo == 'sale' && estadoVisual != 'Completada';

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
        // ✅ BARRA LATERAL DE COLOR COMO EN INVENTARIO
        Container(
          width: 4,
          height: 120, // Altura fija para que se vea como en inventario
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
                    
                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showCliente)
                            Text(
                              order['cliente'] ?? "Cliente desconocido",
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
                            
                            if (puedeMarcarCompletada)
                              _buildActionButton('Completar', Icons.verified, Colors.green, 
                                () => _marcarCompletada(order['orden'])),
                            
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

// 🎯 WIDGET PARA BOTONES DE ACCIÓN (AGREGA ESTA FUNCIÓN)
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
      title: Text('Confirmar Orden'),
      content: Text('¿Confirmar la orden $orderId? Esto cambiará el estado a "En Proceso".'),
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
      'Confirmando orden...',
      '✅ Orden $orderId confirmada'
    );
  }
}

// ✅ ENVIAR COTIZACIÓN
Future<void> _enviarCotizacion(String orderId) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enviar Cotización'),
      content: Text('¿Enviar cotización de la orden $orderId al cliente?'),
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

// ✅ MARCAR COMO COMPLETADA
Future<void> _marcarCompletada(String orderId) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Marcar como Completada'),
      content: Text('¿Marcar la orden $orderId como completada/entregada?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Completar', style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );

  if (confirmado == true) {
    _ejecutarAccionOrden(
      orderId, 
      'completar', 
      'Marcando como completada...',
      '✅ Orden $orderId completada'
    );
  }
}

// ✅ CANCELAR ORDEN
Future<void> _cancelarOrden(String orderId) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancelar Orden'),
      content: Text('¿Cancelar la orden $orderId? Esta acción no se puede deshacer.'),
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
      '✅ Orden $orderId cancelada'
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
      final orderService = OdooOrderService(odooService);
      Map<String, dynamic> resultado;

      // EJECUTAR ACCIÓN CORRESPONDIENTE
      switch (accion) {
        case 'confirmar':
          resultado = await orderService.confirmSaleOrder(int.parse(orderId));
          break;
        case 'enviar':
          resultado = await orderService.sendQuotation(int.parse(orderId));
          break;
        case 'completar':
          resultado = await orderService.markAsInvoiced(int.parse(orderId));
          break;
        case 'cancelar':
          resultado = await orderService.cancelSaleOrder(int.parse(orderId));
          break;
        default:
          resultado = {'success': false, 'error': 'Acción no válida'};
      }

      Navigator.pop(context); // Cerrar loading

      if (resultado['success']) {
        // Recargar los datos de la orden
        final ordenActualizada = await orderService.getOrderDetails(int.parse(orderId));
        
        setState(() {
          final index = widget.recentOrders.indexWhere(
            (order) => order['orden'] == orderId
          );
          if (index != -1 && ordenActualizada.isNotEmpty) {
            // Actualizar datos de la orden
            widget.recentOrders[index]['state_odoo'] = ordenActualizada['state'];
            widget.recentOrders[index]['invoice_status'] = ordenActualizada['invoice_status'];
            widget.recentOrders[index]['note'] = ordenActualizada['note'];
            widget.recentOrders[index]['estado'] = _getEstadoVisual(ordenActualizada);
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


// ✅ NUEVO MÉTODO PARA ARTÍCULOS COMPACTOS (como en inventario)
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
                  "Detalles de la orden",
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
            _buildDetalleItem("Cliente", order['cliente'] ?? "Desconocido"),
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

// Widget para mostrar un artículo individual
Widget _buildArticuloItem({
  required String nombre,
  required int cantidad,
  required double precio,
  bool isFirst = false,
}) {
  return Row(
    children: [
      // Icono del artículo
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
      ),
      const SizedBox(width: 8),
      
      // Información del artículo
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: TextStyle(
                fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "$cantidad x \$${precio.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      
      // Subtotal del artículo
      Text(
        "\$${(cantidad * precio).toStringAsFixed(2)}",
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Colors.green.shade700,
        ),
      ),
    ],
  );
}
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No hay órdenes",
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