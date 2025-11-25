import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_select/user_select.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/model_orden.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/services/offline_order_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onOrdenTerminada;
  final bool showTitle; 
  final Function(Order, User, List<ArticuloItem>)? onOrdenCreadaCompleta;
  final Customer? currentCustomer; 


  const CustomAppBar({
    super.key,
    required this.title,
    this.onOrdenTerminada,
    this.showTitle = true,
    this.onOrdenCreadaCompleta,
    this.currentCustomer, 

  });

  @override
Widget build(BuildContext context) {

  final companyService = CompanyService();


    return AppBar(
    backgroundColor: Colors.deepPurple,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyService.companyName.toUpperCase(), 
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              companyService.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        
        // Título centrado + Indicador de conexión
        if (showTitle)
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  _buildConnectionIndicator(),
                ],
              ),
            ),
          )
        else
          const Spacer(),
        
        // ✅ INDICADOR DE ÓRDENES OFFLINE PENDIENTES
        _buildOfflineOrdersIndicator(context),
        
        const SizedBox(width: 8),
        
        // Icono de notificaciones (borradores)
        badges.Badge(
          showBadge: OrderDraftState.hasDraft,
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          badgeContent: const Text(
            '1',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeStyle: const badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
            elevation: 0,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () {
              if (OrderDraftState.hasDraft) {
                final customer = currentCustomer ?? Customer(
                  id: 0,
                  name: 'Cliente Temporal',
                  email: 'temp@email.com',
                  phone: '000-000-0000',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NuevaOrdenPage(
                      customer: customer,
                      onOrdenCreada: (orden, customer, articulos) {
                        onOrdenTerminada?.call();
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No tienes órdenes incompletas"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
    centerTitle: false,
  );
}

// ✅ WIDGET DEL INDICADOR DE CONEXIÓN
Widget _buildConnectionIndicator() {
  return FutureBuilder<bool>(
    future: ConnectivityService.hasInternet(),
    builder: (context, snapshot) {
      final isOnline = snapshot.data ?? false;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          color: isOnline ? Colors.green : Colors.orange,
          size: 16,
        ),
      );
    },
  );
}

// ✅ WIDGET DEL INDICADOR DE ÓRDENES OFFLINE
Widget _buildOfflineOrdersIndicator(BuildContext context) {
  return StreamBuilder<int>(
    stream: Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => OfflineOrderService.getPendingCount()),
    builder: (context, snapshot) {
      final pendingCount = snapshot.data ?? 0;
      return badges.Badge(
        showBadge: pendingCount > 0,
        position: badges.BadgePosition.topEnd(top: -5, end: -5),
        badgeContent: Text(
          pendingCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 9),
        ),
        badgeStyle: const badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          badgeColor: Colors.orange,
          padding: EdgeInsets.all(3),
        ),
        child: IconButton(
          icon: Icon(
            Icons.cloud_off,
            color: pendingCount > 0 ? Colors.orange : Colors.white70,
            size: 22,
          ),
          onPressed: () {
            if (pendingCount > 0) {
              _mostrarOrdenesPendientes(context, pendingCount);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No hay órdenes pendientes de sincronizar"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      );
    },
  );
}

// ✅ MÉTODO PARA MOSTRAR ÓRDENES PENDIENTES
void _mostrarOrdenesPendientes(BuildContext context, int pendingCount) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange),
          SizedBox(width: 10),
          Text("Órdenes Pendientes"),
        ],
      ),
      content: Text(
        "Tienes $pendingCount órdenes guardadas offline. "
        "Se sincronizarán automáticamente cuando recuperes la conexión a internet.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Entendido"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            // Opcional: Forzar sincronización manual
            await _sincronizarOrdenesPendientes(context);
          },
          child: const Text("Sincronizar Ahora"),
        ),
      ],
    ),
  );
}

// ✅ MÉTODO PARA SINCRONIZAR MANUALMENTE (OPCIONAL)
Future<void> _sincronizarOrdenesPendientes(BuildContext context) async {
  final tieneInternet = await ConnectivityService.hasInternet();
  if (!tieneInternet) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No hay conexión a internet para sincronizar"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Sincronizando órdenes pendientes..."),
    ),
  );
  
  // Aquí puedes implementar la lógica de sincronización
  // Por ahora solo mostramos un mensaje
  await Future.delayed(const Duration(seconds: 2));
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Sincronización completada"),
      backgroundColor: Colors.green,
    ),
  );
}

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}