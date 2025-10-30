import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';

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
  //String articuloFiltro = "";
  String _ordenFecha = "DESC";
  int _selectedIndex = 2;
  int _resultadosCount = 0;

  // Listas de categorías y marcas basadas en los artículos
  List<String> categorias = ["Todas", "Computadoras", "Teléfonos", "Audio", "Monitores", "Periféricos", "Tablets", "Wearables", "Cámaras", "Almacenamiento"];
  List<String> marcas = ["Todas", "HP", "Samsung", "Sony", "LG", "Logitech", "Razer", "Apple", "GoPro", "Seagate"];

  @override
  void initState() {
    super.initState();
    _resultadosCount = widget.recentOrders.length;
  }

  void _agregarOrden(Map<String, dynamic> nuevaOrden) {
  setState(() {
    // Asegurarnos de que la orden tenga la estructura completa
    final ordenCompleta = {
      'orden': nuevaOrden['orden'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'cliente': nuevaOrden['cliente'] ?? 'Cliente desconocido',
      'articulo': nuevaOrden['articulo'] ?? '',
      'articulos': nuevaOrden['articulos'] ?? [], // Lista de artículos
      'fecha': nuevaOrden['fecha'] ?? DateTime.now().toString(),
      'estado': nuevaOrden['estado'] ?? 'Pendiente',
      'total': nuevaOrden['total'] ?? 0.0,
    };
    
    widget.recentOrders.insert(0, ordenCompleta);
    _resultadosCount = widget.recentOrders.length;
  });
}



// FUNCIONES PARA MANEJAR COLORES E ICONOS POR ESTADO
Color _getStatusColor(String status) {
  switch (status) {
    case 'Pagada':
      return Colors.green;
    case 'Terminado':
      return Colors.blue;
    case 'En Proceso':
      return const Color.fromARGB(255, 195, 215, 231);
    case 'Recibida':
      return Colors.green;
    case 'Pendiente':
      return const Color.fromARGB(255, 235, 135, 42);
    case 'Cancelado':
      return const Color.fromARGB(255, 158, 151, 151);
    default:
      return const Color.fromARGB(255, 253, 249, 249);
  }
}

Color _getStatusBackgroundColor(String status) {
  switch (status) {
    case 'Pagada':
      return Colors.green.withOpacity(0.1);
    case 'Terminado':
      return Colors.blue.withOpacity(0.1);
    case 'En Proceso':
      return Colors.orange.withOpacity(0.1);
    case 'Preparación':
      return Colors.purple.withOpacity(0.1);
    case 'Pendiente':
      return Colors.amber.withOpacity(0.1);
    case 'Cancelado':
      return Colors.red.withOpacity(0.1);
    default:
      return Colors.grey.withOpacity(0.1);
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'Pagada':
      return Icons.check_circle;
    case 'Terminado':
      return Icons.verified;
    case 'En Proceso':
      return Icons.build;
    case 'Preparación':
      return Icons.inventory_2;
    case 'Pendiente':
      return Icons.pending_actions;
    case 'Cancelado':
      return Icons.cancel;
    default:
      return Icons.help;
  }
}

String _getStatusDescription(String status) {
  switch (status) {
    case 'Pagada':
      return "Orden pagada y completada";
    case 'Terminado':
      return "Orden terminada lista para entrega";
    case 'En Proceso':
      return "Orden en proceso de elaboración";
    case 'Preparación':
      return "Orden en preparación inicial";
    case 'Pendiente':
      return "Orden pendiente de procesar";
    case 'Cancelado':
      return "Orden cancelada";
    default:
      return "Estado desconocido";
  }
}



void _aplicarFiltros() {
  setState(() {
    // Actualizar el contador de resultados basado en el filtro actual
    _resultadosCount = widget.recentOrders.where((order) {
      return estadoFiltro == "Todas" || order['estado'] == estadoFiltro;
    }).length;
  });
}


Widget _buildOrdersList() {
  List<Map<String, dynamic>> filteredOrders =
      widget.recentOrders.where((order) {
    final estadoMatch =
        estadoFiltro == "Todas" || order['estado'] == estadoFiltro;
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


 void _abrirOrdenarBottomSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.sort, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Ordenar por",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.blue),
              title: const Text("Más antiguas primero"),
              onTap: () {
                setState(() => _ordenFecha = "ASC");
                _sortOrdersByDate();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.blue),
              title: const Text("Más recientes primero"),
              onTap: () {
                setState(() => _ordenFecha = "DESC");
                _sortOrdersByDate();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}



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

  void _sortOrdersByDate() {
    widget.recentOrders.sort((a, b) {
      final fechaA = DateTime.tryParse(a['fecha']) ?? DateTime.now();
      final fechaB = DateTime.tryParse(b['fecha']) ?? DateTime.now();
      return _ordenFecha == "ASC"
          ? fechaA.compareTo(fechaB)
          : fechaB.compareTo(fechaA);
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
  final String estado = order['estado'] ?? "Pendiente";

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
        color: _getStatusColor(estado).withOpacity(0.3),
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
            color: _getStatusColor(estado),
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
                        color: _getStatusBackgroundColor(estado),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(estado),
                        color: _getStatusColor(estado),
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
                    
                    // Total de la orden
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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
                            color: _getStatusBackgroundColor(estado),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: _getStatusColor(estado),
                            ),
                          ),
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