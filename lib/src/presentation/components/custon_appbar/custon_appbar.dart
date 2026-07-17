import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';
import 'package:provider/provider.dart'; 
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'package:ecomerce_app/src/domain/models/model_orden.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/screens/draft_orders_screen.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/services/draft_order_service.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyService>(
      builder: (context, companyService, child) {
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

          // ✅ BOTÓN DE BORRADORES
          _buildDraftsButton(context),
        ],
      ),
      centerTitle: false,
    );
      },
    );
  }

  // ✅ BOTÓN DE BORRADORES
  Widget _buildDraftsButton(BuildContext context) {
    return StreamBuilder<List<DraftOrder>>(
      stream: DraftOrderService.instance.draftsStream,
      initialData: const [],
      builder: (context, snapshot) {
        final draftCount = snapshot.data?.length ?? 0;
        
        return badges.Badge(
          showBadge: draftCount > 0,
          position: badges.BadgePosition.topEnd(top: -5, end: -5),
          badgeContent: Text(
            draftCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
          badgeStyle: const badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.orange,
            padding: EdgeInsets.all(3),
          ),
          child: IconButton(
            icon: const Icon(Icons.drafts, color: Colors.white),
            onPressed: () => _showDraftsDialog(context),
          ),
        );
      },
    );
  }

  Future<List<DraftOrder>> _getValidDrafts() async {
  try {
    final drafts = await DraftOrderService.instance.getAllDrafts();
    
    // Filtrar borradores que puedan tener problemas
    final validDrafts = <DraftOrder>[];
    
    for (var draft in drafts) {
      // Verificar que el borrador tenga datos mínimos válidos
      if (draft.articulos.isNotEmpty && 
          ((draft.type == OrderType.venta && draft.customer != null) ||
           (draft.type == OrderType.compra && draft.proveedor != null))) {
        validDrafts.add(draft);
      } else {
        print('⚠️ Borrador inválido detectado y filtrado: ${draft.id}');
        // Opcional: Eliminar borrador inválido
        // await DraftOrderService.instance.deleteDraft(draft.id);
      }
    }
    
    return validDrafts;
  } catch (e) {
    print('❌ Error obteniendo borradores válidos: $e');
    return [];
  }
}

  // ✅ DIÁLOGO DE BORRADORES
  void _showDraftsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drafts, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Órdenes Borrador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: FutureBuilder<List<DraftOrder>>(
                  future: DraftOrderService.instance.getAllDrafts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 50),
                            const SizedBox(height: 10),
                            Text('Error: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }
                    
                    final drafts = snapshot.data ?? [];
                    if (drafts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.note_add, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay órdenes borrador',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Las órdenes incompletas aparecerán aquí',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Cerrar'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Contador
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              const Icon(Icons.list, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${drafts.length} ${drafts.length == 1 ? 'borrador' : 'borradores'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: drafts.length,
                            itemBuilder: (context, index) {
                              final draft = drafts[index];
                              return _buildDraftItem(draft, context);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        label: const Text('Eliminar Todos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () => _showDeleteAllConfirmation(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text('Ver Pantalla Completa'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DraftOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ITEM DE BORRADOR EN LA LISTA
  Widget _buildDraftItem(DraftOrder draft, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showContinueConfirmation(draft, context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: draft.type == OrderType.venta 
                      ? Colors.blue[50] 
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  draft.type == OrderType.venta 
                      ? Icons.shopping_cart 
                      : Icons.shopping_bag,
                  color: draft.type == OrderType.venta 
                      ? Colors.blue 
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.displayCustomer,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Tipo de orden
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: draft.type == OrderType.venta 
                            ? Colors.blue[100] 
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        draft.displayType,
                        style: TextStyle(
                          color: draft.type == OrderType.venta 
                              ? Colors.blue[800] 
                              : Colors.orange[800],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      '${draft.totalItems} productos • \$${draft.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDate(draft.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showContinueConfirmation(draft, context),
                    tooltip: 'Continuar orden',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(draft.id, context),
                    tooltip: 'Eliminar borrador',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CONFIRMACIÓN PARA CONTINUAR BORRADOR
  Future<void> _showContinueConfirmation(DraftOrder draft, BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: draft.type == OrderType.venta ? Colors.blue : Colors.orange),
            const SizedBox(width: 10),
            Text('Continuar borrador'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Continuar con la orden de ${draft.displayType.toLowerCase()} para:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '👤 ${draft.displayCustomer}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '📦 ${draft.totalItems} productos • \$${draft.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '📅 Creada: ${_formatDate(draft.createdAt)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los productos guardados se cargarán automáticamente.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: draft.type == OrderType.venta 
                  ? Colors.blue 
                  : Colors.orange,
            ),
            child: Text(
              'Continuar ${draft.displayType.toLowerCase()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirmado == true) {
      await _continueDraft(draft, context);
    }
  }

  // ✅ CONTINUAR BORRADOR
  Future<void> _continueDraft(DraftOrder draft, BuildContext context) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa para feedback
      
      Navigator.pop(context); // Cerrar loading
      Navigator.pop(context); // Cerrar diálogo de borradores
      
      if (draft.type == OrderType.venta && draft.customer != null) {
        // Navegar a NuevaOrdenPage para ventas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NuevaOrdenPage(
              customer: draft.customer!,
              onOrdenCreada: (order, customer, articulos) {
                // Eliminar borrador después de crear la orden
                DraftOrderService.instance.deleteDraft(draft.id);
                
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Orden creada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navegar de vuelta
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else if (draft.type == OrderType.compra && draft.proveedor != null) {
        // Navegar a CrearOrdenCompraScreen para compras
        final proveedor = Customer(
          id: draft.proveedor!['id'],
          name: draft.proveedor!['name'],
          email: draft.proveedor!['email'] ?? '',
          vat: draft.proveedor!['vat'] ?? '',
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrearOrdenCompraScreen(
              proveedor: proveedor,
              onOrdenCreada: (order, proveedor, articulos) {
                // Eliminar borrador después de crear la orden
                DraftOrderService.instance.deleteDraft(draft.id);
                
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Orden de compra creada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navegar de vuelta
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: No se pudo cargar el borrador'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading si hay error
      print('❌ Error al continuar borrador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ CONFIRMACIÓN PARA ELIMINAR BORRADOR
  Future<void> _showDeleteConfirmation(String draftId, BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar borrador'),
        content: const Text('¿Estás seguro de que quieres eliminar este borrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await DraftOrderService.instance.deleteDraft(draftId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Borrador eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ CONFIRMACIÓN PARA ELIMINAR TODOS LOS BORRADORES
  Future<void> _showDeleteAllConfirmation(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los borradores'),
        content: const Text('¿Estás seguro de que deseas eliminar TODOS los borradores? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar Todos', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmado == true) {
      try {
        await DraftOrderService.instance.clearAllDrafts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Todos los borradores eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ FORMATO DE FECHA
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Recién';
    }
  }

  // ✅ INDICADOR DE CONEXIÓN
  Widget _buildConnectionIndicator() {
    return FutureBuilder<bool>(
      future: ConnectivityService.hasInternet(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
