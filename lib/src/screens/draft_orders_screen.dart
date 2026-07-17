// lib/screens/draft_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/services/draft_order_service.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';

class DraftOrdersScreen extends StatefulWidget {
  const DraftOrdersScreen({super.key});

  @override
  _DraftOrdersScreenState createState() => _DraftOrdersScreenState();
}

class _DraftOrdersScreenState extends State<DraftOrdersScreen> {
  List<DraftOrder> _drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    try {
      final drafts = await DraftOrderService.instance.getAllDrafts();
      setState(() {
        _drafts = drafts;
      });
    } catch (e) {
      print('Error cargando borradores: $e');
    }
  }

  void _deleteDraft(String id) async {
    await DraftOrderService.instance.deleteDraft(id);
    await _loadDrafts(); // Recargar lista
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Borrador eliminado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAllDrafts() async {
    await DraftOrderService.instance.clearAllDrafts();
    setState(() {
      _drafts = [];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos los borradores eliminados'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _continueDraft(DraftOrder draft, BuildContext context) {
    if (draft.type == OrderType.venta && draft.customer != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NuevaOrdenPage(
            customer: draft.customer!,
            onOrdenCreada: (order, customer, articulos) {
              // Callback para cuando se cree la orden
              _deleteDraft(draft.id);
            },
          ),
        ),
      );
    } else {
      // Para órdenes de compra
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad de órdenes de compra en desarrollo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes Borrador'),
        actions: [
          if (_drafts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar todos'),
                    content: const Text('¿Eliminar todos los borradores?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllDrafts();
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Eliminar todos',
            ),
        ],
      ),
      body: _drafts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay órdenes borrador',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Las órdenes incompletas aparecerán aquí',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drafts.length,
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return _buildDraftCard(draft, context);
              },
            ),
    );
  }

  Widget _buildDraftCard(DraftOrder draft, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: draft.type == OrderType.venta 
                ? Colors.blue[50] 
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            draft.type == OrderType.venta 
                ? Icons.shopping_cart 
                : Icons.shopping_bag,
            color: draft.type == OrderType.venta 
                ? Colors.blue 
                : Colors.orange,
            size: 28,
          ),
        ),
        title: Text(
          draft.displayCustomer,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${draft.totalItems} productos',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Creado: ${_formatDate(draft.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${draft.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteDraft(draft.id);
            } else if (value == 'continue') {
              _continueDraft(draft, context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'continue',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Continuar'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _continueDraft(draft, context),
      ),
    );
  }

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
}
