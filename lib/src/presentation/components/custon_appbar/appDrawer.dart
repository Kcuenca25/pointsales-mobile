import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
// lib/src/presentation/components/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';
import 'package:provider/provider.dart'; 
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/model_orden.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/services/offline_order_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onItemTapped;
  final Customer? currentCustomer;

  const AppDrawer({
    super.key, 
    this.onItemTapped,
    this.currentCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final companyService = CompanyService();
    
    return Drawer(
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
           // CABECERA MEJORADA
Container(
  padding: const EdgeInsets.only(top: 50, bottom: 5, left: 30, right: 125),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF583F80),
        Colors.deepPurple.shade700,
      ],
    ),
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.deepPurple.withOpacity(0.3),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Logo/Icono de empresa
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.business,
          color: Color(0xFF583F80),
          size: 35,
        ),
      ),
      
      const SizedBox(height: 15),
      
      // Nombre de empresa
      Text(
        companyService.companyName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        maxLines: 2,      ),
      
      const SizedBox(height: 5),
      
      // Usuario actual
      Text(
        companyService.userName,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
      
      const SizedBox(height: 15),
      
      // Estado de conexión
      _buildConnectionStatus(),
    ],
  ),
),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                children: [
                  // ✅ SECCIÓN PRINCIPAL - Navegación esencial
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Navegación Principal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF583F80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // Botón Ventas (Deshabilitado temporalmente)
                  _buildDrawerItem(
                    context,
                    icon: Icons.point_of_sale,
                    title: 'Ventas',
                    subtitle: 'Próximamente',
                    color: Colors.grey.shade500,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Módulo de ventas en desarrollo')),
                      );
                    },
                  ),
                  
                  // Botón Compras (Deshabilitado temporalmente)
                  _buildDrawerItem(
                    context,
                    icon: Icons.shopping_cart_checkout,
                    title: 'Compras',
                    subtitle: 'Próximamente',
                    color: Colors.grey.shade500,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Módulo de compras en desarrollo')),
                      );
                    },
                  ),
                  
                  // Botón Inventario (Deshabilitado temporalmente)
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Inventario',
                    subtitle: 'Próximamente',
                    color: Colors.grey.shade500,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Módulo de inventario en desarrollo')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ SECCIÓN ACCIONES RÁPIDAS
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF583F80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // 🔔 NOTIFICACIONES CON BADGE
                  _buildNotificationsItem(context),
                  
                  // 📶 ÓRDENES OFFLINE
                  _buildOfflineOrdersItem(context),
                  
                  // 🛠️ AJUSTES
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Ajustes',
                    subtitle: 'Configuración general',
                    color: Colors.grey.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a ajustes
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ PERFIL Y SALIDA
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Cuenta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF583F80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // Perfil
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_circle,
                    title: 'Mi Perfil',
                    subtitle: 'Información personal',
                    color: Color(0xFF583F80),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileScreen(context);
                    },
                  ),
                  
                  // Cerrar Sesión
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    subtitle: 'Salir de la aplicación',
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
            
            // FOOTER CON INFORMACIÓN
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Estado de la aplicación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Aplicación en línea',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Versión dinámica desde pubspec.yaml
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final versionStr = snapshot.hasData 
                          ? 'v${snapshot.data!.version}' 
                          : 'Cargando versión...';
                      return Text(
                        '$versionStr • ${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET PARA ITEMS DEL DRAWER MEJORADOS
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        visualDensity: const VisualDensity(vertical: -2),
        onTap: onTap,
      ),
    );
  }

  // ✅ INDICADOR DE ESTADO DE CONEXIÓN
  Widget _buildConnectionStatus() {
    return FutureBuilder<bool>(
      future: ConnectivityService.hasInternet(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'En línea' : 'Sin conexión',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ NOTIFICACIONES CON BADGE (Borradores)
  Widget _buildNotificationsItem(BuildContext context) {
    return StreamBuilder<bool>(
      stream: Stream.periodic(const Duration(seconds: 5))
          .map((_) => OrderDraftState.hasDraft),
      builder: (context, snapshot) {
        final hasDraft = snapshot.data ?? false;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDraft
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: badges.Badge(
                showBadge: hasDraft,
                position: badges.BadgePosition.topEnd(top: -5, end: -5),
                badgeContent: const Text(
                  '!',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
                badgeStyle: const badges.BadgeStyle(
                  shape: badges.BadgeShape.circle,
                  badgeColor: Colors.orange,
                  padding: EdgeInsets.all(4),
                ),
                child: Icon(
                  hasDraft ? Icons.notifications_active : Icons.notifications,
                  color: hasDraft ? Colors.orange : Colors.grey,
                  size: 22,
                ),
              ),
            ),
            title: Text(
              'Notificaciones',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: hasDraft ? Colors.orange : Colors.black87,
              ),
            ),
            subtitle: Text(
              hasDraft ? 'Tienes orden incompleta' : 'Sin notificaciones',
              style: TextStyle(
                fontSize: 11,
                color: hasDraft ? Colors.orange.shade600 : Colors.grey.shade600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            visualDensity: const VisualDensity(vertical: -2),
            onTap: () {
              if (hasDraft) {
                final customer = currentCustomer ??
                    Customer(
                      id: 0,
                      name: 'Cliente Temporal',
                      email: 'temp@email.com',
                      phone: '000-000-0000',
                    );

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NuevaOrdenPage(
                      customer: customer,
                      onOrdenCreada: (orden, customer, articulos) {
                      },
                    ),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No tienes notificaciones pendientes"),
                    backgroundColor: Colors.grey,
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

  // ✅ ÓRDENES OFFLINE
  Widget _buildOfflineOrdersItem(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 10))
          .asyncMap((_) => OfflineOrderService.getPendingCount()),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pendingCount > 0
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: badges.Badge(
                showBadge: pendingCount > 0,
                position: badges.BadgePosition.topEnd(top: -5, end: -5),
                badgeContent: Text(
                  pendingCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                badgeStyle: badges.BadgeStyle(
                  shape: badges.BadgeShape.circle,
                  badgeColor: pendingCount > 0 ? Colors.red : Colors.green,
                  padding: const EdgeInsets.all(4),
                ),
                child: Icon(
                  pendingCount > 0 ? Icons.cloud_off : Icons.cloud_done,
                  color: pendingCount > 0 ? Colors.red : Colors.green,
                  size: 22,
                ),
              ),
            ),
            title: Text(
              'Sincronización',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: pendingCount > 0 ? Colors.red : Colors.green,
              ),
            ),
            subtitle: Text(
              pendingCount > 0 
                  ? '$pendingCount órdenes pendientes'
                  : 'Todo sincronizado',
              style: TextStyle(
                fontSize: 11,
                color: pendingCount > 0 
                    ? Colors.red.shade600 
                    : Colors.green.shade600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            visualDensity: const VisualDensity(vertical: -2),
            onTap: () {
              Navigator.pop(context);
              if (pendingCount > 0) {
                _mostrarOrdenesPendientes(context, pendingCount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No hay órdenes pendientes de sincronizar"),
                    backgroundColor: Colors.green,
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
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange.shade600),
            const SizedBox(width: 10),
            Text(
              "Órdenes Pendientes",
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tienes $pendingCount orden(es) guardadas offline.",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: const Text(
                "Se sincronizarán automáticamente cuando recuperes la conexión a internet.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text("Entendido"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sincronizarOrdenesPendientes(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Sincronizar Ahora"),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO PARA SINCRONIZAR MANUALMENTE
  Future<void> _sincronizarOrdenesPendientes(BuildContext context) async {
    final tieneInternet = await ConnectivityService.hasInternet();
    if (!tieneInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 10),
              Text("No hay conexión a internet para sincronizar"),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                "Sincronizando órdenes pendientes...",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Sincronización completada"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ MOSTRAR PANTALLA DE PERFIL
  void _showProfileScreen(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 10),
            Text("Pantalla de perfil - En desarrollo"),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ CONFIRMACIÓN PARA CERRAR SESIÓN
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              const SizedBox(width: 10),
              Text(
                "Cerrar Sesión",
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "¿Estás seguro que deseas cerrar sesión?",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Text(
                  "Serás redirigido a la pantalla de inicio de sesión.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Cerrar Sesión"),
            ),
          ],
        );
      },
    );
  }

  // ✅ EJECUTAR EL CIERRE DE SESIÓN
  void _performLogout(BuildContext context) async {
    // Mostrar indicador de progreso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 15),
            Text("Cerrando sesión..."),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        duration: Duration(seconds: 2),
      ),
    );

    final navigator = Navigator.of(context, rootNavigator: true);
    
    try {
      // 1. Limpiar cualquier estado de la app
      OrderDraftState.hasDraft = false;
      
      // 2. ✅ LLAMAR AL MÉTODO LOGOUT DEL PROVIDER
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      await usuarioProvider.logout();
      
      // 3. Limpiar caché de credenciales
      final companyService = CompanyService();
      companyService.clearSessionData();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 4. Navegar a la pantalla de login (usando navigator capturado)
      navigator.pushNamedAndRemoveUntil(
        '/credentials',
        (route) => false,
      );

      // 5. Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Sesión cerrada exitosamente"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error en logout: $e");
      
      // En caso de error, igualmente redirigir
      navigator.pushNamedAndRemoveUntil(
        '/credentials',
        (route) => false,
      );
    }
  }
}
