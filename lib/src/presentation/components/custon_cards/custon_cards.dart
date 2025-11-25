import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/recent_orders_screen.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/07-proveedores.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/08-toma_de_inventario.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_compra.dart';


class Custon_Cards extends StatefulWidget {
  final Customer customer; 
  
  const Custon_Cards({
    super.key, 
    required this.customer,
  });

  @override
  _Custon_CardsState createState() => _Custon_CardsState();
}

class _Custon_CardsState extends State<Custon_Cards> {

  List<Map<String, dynamic>> recentOrders = [];
  List<ArticuloItem> _articulosSeleccionados = [];

     @override
  void initState() {
    super.initState();
    // ✅ VERIFICAR QUE EL SERVICIO ESTÉ INICIALIZADO
    _ensureCompanyServiceInitialized();
  }
    Future<void> _ensureCompanyServiceInitialized() async {
    final companyService = CompanyService();
    if (companyService.odooService == null) {
      await companyService.initialize();
    }
  }


  void addRecentOrder(String cliente, String ordenId) {
    recentOrders.insert(0, {
      'cliente': cliente,
      'orden': ordenId,
      'fecha': DateTime.now().toString().substring(0, 16),
    });
    if (recentOrders.length > 10) {
      recentOrders.removeLast();
    }
  }

  Widget buildCard(
    Color color,
    IconData icon,
    String title, {
    TextStyle? textStyle,
    bool disabled = false,
    bool showTag = false,
    bool accesoDirecto = false,
    VoidCallback? onTap,
  }) {
    final cardColor = disabled ? Colors.grey.shade400 : color;

    final cardWidget = accesoDirecto
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: _cardContent(cardColor, icon, title, textStyle, showTag),
          )
        : Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color.fromARGB(99, 186, 162, 204),
                width: 0.5,
              ),
            ),
            elevation: 0,
            child: _cardContent(cardColor, icon, title, textStyle, showTag),
          );

    return Expanded(
      child: SizedBox(
        height: 110,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: cardWidget,
        ),
      ),
    );
  }

  Widget _cardContent(
    Color cardColor,
    IconData icon,
    String title,
    TextStyle? textStyle,
    bool showTag,
  ) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cardColor, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textStyle ??
                    TextStyle(
                      color: cardColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        if (showTag)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
              child: const Text(
                'Featuring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompanyHeader(),
        
        const SizedBox(height: 10),
        // SECCIÓN VENTAS
        const Text(
          'Ventas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),

        // Gestión de Órdenes (Primera fila de Ventas)
        const SizedBox(height: 8),
        Row(
          children: [
            buildCard(
  const Color.fromARGB(255, 88, 63, 128),
  Icons.people,
  'Clientes',
  onTap: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClientScreen(
          onCustomerPageNavigate: (customer) {
            // Manejar la navegación para clientes (personas)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrdenPago(
                  customer: customer,
                  onProductListNavigate: (selectedCustomer) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductList(
                          selectedCustomer: selectedCustomer,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  },
),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.shopping_cart,
              'Órdenes de venta',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecentOrdersScreen(
                      recentOrders: recentOrders,
                      customer: widget.customer,
                    ),
                  ),
                );
                setState(() {});
              },
            ),
            const SizedBox(width: 10),
            buildCard(
  const Color.fromARGB(255, 88, 63, 128),
  Icons.shopping_bag,
  'Artículos',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticuloSelectorScreen(
          onArticuloAgregado: (articulo, cantidad) {
            setState(() {
              // Actualizar tu lista local de artículos seleccionados
              _articulosSeleccionados.add(articulo);
            });
          },
          onArticuloEliminado: (articulo) {
            setState(() {
              // Remover de tu lista local
              _articulosSeleccionados.removeWhere((item) => item.id == articulo.id);
            });
          },
          articulosSeleccionadosIniciales: _articulosSeleccionados,
        ),
      ),
    );
  },
),
          ],
        ),
        const SizedBox(height: 15),

        // Gestión de Procesos (Segunda fila de Ventas)
        const SizedBox(height: 8),
        Row(
          children: [
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.description,
              'Proformas',
            ),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.local_shipping,
              'Despacho',
              disabled: true,
              showTag: true,
            ),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.attach_money,
              'Cobro de Facturas',
              disabled: true,
              showTag: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // SECCIÓN GASTOS
        const Text(
          'Compras',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),

        // Tercera fila (Gastos)
        Row(
          children: [
            buildCard(
  const Color.fromARGB(255, 88, 63, 128),
  Icons.shopping_cart_checkout,
  'Órdenes de compra',
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseOrdersScreen(
          purchaseOrders: [], 
          selectedSupplier: null,
        ),
      ),
    );
    setState(() {});
  },
),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.inventory,
              'Recepción',
            ),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.receipt,
              'Facturas',
            ),
            
          ],
        ),
        const SizedBox(height: 10),

        // Cuarta fila (Pagos)
        Row(
          children: [
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.payment,
              'Pagos',
            ),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.shopping_bag,
              'Artículos',
            ),
            const SizedBox(width: 10),
            buildCard(
  const Color.fromARGB(255, 214, 119, 31), // Color diferente para distinguir
  Icons.business,
  'Proveedores',
  onTap: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProveedoresScreen(
          onSupplierPageNavigate: (supplier) {
            // ✅ CORREGIDO: Navegar directamente a crear orden de compra
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearOrdenCompraScreen(
                  proveedor: supplier,
                  onOrdenCreada: (orden, proveedor, articulos) {
                    // Manejar la orden creada exitosamente
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Orden de compra creada para ${proveedor.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Opcional: Navegar de vuelta
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  },
),
          ],
        ),
        const SizedBox(height: 20),

        // SECCIÓN INVENTARIO 
        const Text(
          "Inventario",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 88, 63, 128),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
           buildCard(
  const Color.fromARGB(255, 88, 63, 128),
  Icons.inventory_2,
  'Toma de inventario',
  accesoDirecto: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TomaInventarioScreen(),
      ),
    );
  },
),
            const SizedBox(width: 10),
            buildCard(
              const Color.fromARGB(255, 88, 63, 128),
              Icons.history,
              '',
              accesoDirecto: true,
            ),
          ],
        ),
      ],
    );
  }
  


    // ✅ HEADER CON INFORMACIÓN DE EMPRESA
  Widget _buildCompanyHeader() {
      final companyService = CompanyService();


     return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),

  );
}

   //Widget para mostrar información del cliente
  Widget _buildCustomerInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente Actual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  radius: 25,
                  child: Text(
                    widget.customer.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
                        Text(
                          widget.customer.email!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
                        Text(
                          widget.customer.phone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (widget.customer.commercialCompanyName != null && 
                          widget.customer.commercialCompanyName!.isNotEmpty)
                        Text(
                          widget.customer.commercialCompanyName!,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.deepPurple, size: 28),
                  onPressed: () {
                    // Crear orden rápida para este cliente
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdenPago(
                          customer: widget.customer,
                          onProductListNavigate: (customer) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductList(
                                  selectedCustomer: customer,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  tooltip: 'Crear orden para ${widget.customer.name}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    widget.customer.isCompany ? 'Empresa' : 'Persona',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: widget.customer.isCompany 
                      ? Colors.orange[100] 
                      : Colors.green[100],
                ),
                if (widget.customer.city != null && widget.customer.city!.isNotEmpty)
                  Text(
                    widget.customer.city!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}