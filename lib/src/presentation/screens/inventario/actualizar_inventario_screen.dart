// actualizar_inventario_screen.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';
import 'package:intl/intl.dart';

class ActualizarInventarioScreen extends StatefulWidget {
  final List<InventoryItem> currentInventory;
  final String customerName;
  final String updatedBy;

  const ActualizarInventarioScreen({
    super.key,
    required this.currentInventory,
    required this.customerName,
    required this.updatedBy,
  });

  @override
  State<ActualizarInventarioScreen> createState() => _ActualizarInventarioScreenState();
}

class _ActualizarInventarioScreenState extends State<ActualizarInventarioScreen> {
  final List<InventoryUpdateItem> _updateItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeUpdateItems();
  }

  void _initializeUpdateItems() {
    setState(() {
      _updateItems.addAll(widget.currentInventory.map((item) {
        return InventoryUpdateItem(
          productId: item.id,
          productName: item.name,
          sku: item.sku,
          category: item.category,
          previousStock: item.currentStock,
          newStock: item.currentStock, // Inicialmente igual
          difference: 0,
          action: 'updated',
          price: item.price,
          cost: item.cost,
        );
      }).toList());
    });
  }

  List<InventoryUpdateItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _updateItems;
    return _updateItems.where((item) {
      return item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _updateStock(int productId, int newStock) {
    setState(() {
      final item = _updateItems.firstWhere((element) => element.productId == productId);
      final index = _updateItems.indexOf(item);
      
      _updateItems[index] = InventoryUpdateItem(
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        category: item.category,
        previousStock: item.previousStock,
        newStock: newStock,
        difference: newStock - item.previousStock,
        action: newStock == 0 ? 'removed' : 
                newStock > item.previousStock ? 'added' : 'updated',
        price: item.price,
        cost: item.cost,
      );
    });
  }

  InventoryBalance _calculateBalance() {
    final totalItems = _updateItems.length;
    final matchedItems = _updateItems.where((item) => item.previousStock == item.newStock).length;
    final changedItems = _updateItems.where((item) => item.previousStock != item.newStock).length;
    
    final totalValueDifference = _updateItems.fold(0.0, (sum, item) {
      return sum + ((item.newStock - item.previousStock) * item.price).abs();
    });
    
    final accuracyRate = totalItems > 0 ? (matchedItems / totalItems) * 100 : 0.0;

    return InventoryBalance(
      totalItems: totalItems,
      matchedItems: matchedItems,
      discrepancyItems: changedItems,
      missingItems: 0,
      totalValueDifference: totalValueDifference,
      accuracyRate: accuracyRate,
      calculationDate: DateTime.now(),
    );
  }

  void _confirmUpdate() {
    final changes = _updateItems.where((item) => item.previousStock != item.newStock).toList();
    
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }

    final balance = _calculateBalance();
    final update = InventoryUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      updatedBy: widget.updatedBy,
      customerName: widget.customerName,
      items: changes,
      notes: _notesController.text,
      balance: balance,
    );

    Navigator.pop(context, update);
  }

  @override
  Widget build(BuildContext context) {
    final changesCount = _updateItems.where((item) => item.previousStock != item.newStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Inventario'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 88, 63, 128),
        elevation: 0,
        actions: [
          Badge(
            label: Text(changesCount.toString()),
            child: IconButton(
              icon: const Icon(Icons.change_circle),
              onPressed: () {
                _showChangesSummary();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header informativo
          _buildUpdateHeader(),
          
          // Búsqueda
          _buildSearchSection(),
          
          // Lista de productos
          Expanded(
            child: _buildProductList(),
          ),
          
          // Notas y acciones
          _buildFooterSection(),
        ],
      ),
    );
  }

  Widget _buildUpdateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualizando: ${widget.customerName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Por: ${widget.updatedBy} • ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // ✅ QUITÉ EL CONST AQUÍ
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildProductItem(item);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No hay productos en inventario' : 'No se encontraron productos',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(InventoryUpdateItem item) {
    final hasChanges = item.previousStock != item.newStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasChanges ? 2 : 0,
      color: hasChanges ? Colors.blue[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Indicador de cambios
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: hasChanges ? _getChangeColor(item) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.sku,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (hasChanges) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getChangeText(item),
                      style: TextStyle(
                        color: _getChangeColor(item),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Controles de stock
            Column(
              children: [
                Text(
                  'Anterior: ${item.previousStock}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () {
                          if (item.newStock > 0) {
                            _updateStock(item.productId, item.newStock - 1);
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          controller: TextEditingController(text: item.newStock.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newStock = int.tryParse(value) ?? 0;
                            _updateStock(item.productId, newStock);
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          _updateStock(item.productId, item.newStock + 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChangeColor(InventoryUpdateItem item) {
    if (item.newStock == 0) return Colors.red;
    if (item.newStock > item.previousStock) return Colors.green;
    if (item.newStock < item.previousStock) return Colors.orange;
    return Colors.grey;
  }

  String _getChangeText(InventoryUpdateItem item) {
    if (item.newStock == 0) return 'PRODUCTO ELIMINADO';
    if (item.newStock > item.previousStock) return '+${item.difference} unidades agregadas';
    if (item.newStock < item.previousStock) return '${item.difference} unidades removidas';
    return 'Sin cambios';
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Agregar notas sobre la actualización...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 88, 63, 128),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangesSummary() {
    final changes = _updateItems.where((item) => item.previousStock != item.newStock).toList();
    
    showDialog(
      context: context,
      builder: (context) => ChangesSummaryDialog(changes: changes),
    );
  }
}

class ChangesSummaryDialog extends StatelessWidget {
  final List<InventoryUpdateItem> changes;

  const ChangesSummaryDialog({super.key, required this.changes});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.change_circle),
          SizedBox(width: 8),
          Text('Resumen de Cambios'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: changes.length,
          itemBuilder: (context, index) {
            final item = changes[index];
            return ListTile(
              leading: Icon(
                _getChangeIcon(item.action),
                color: _getChangeColor(item),
              ),
              title: Text(item.productName),
              subtitle: Text(item.sku),
              trailing: Text(
                _getChangeText(item),
                style: TextStyle(
                  color: _getChangeColor(item),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  IconData _getChangeIcon(String action) {
    switch (action) {
      case 'added': return Icons.add_circle;
      case 'removed': return Icons.remove_circle;
      default: return Icons.edit;
    }
  }

  Color _getChangeColor(InventoryUpdateItem item) {
    switch (item.action) {
      case 'added': return Colors.green;
      case 'removed': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getChangeText(InventoryUpdateItem item) {
    switch (item.action) {
      case 'added': return '+${item.difference}';
      case 'removed': return 'ELIMINADO';
      default: return item.difference.toString();
    }
  }
}