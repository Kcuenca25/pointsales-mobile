import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/inventario_actualizacion.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/nuevaTomaInventario.dart';

class TomaInventarioScreen extends StatefulWidget {
  const TomaInventarioScreen({super.key});

  @override
  State<TomaInventarioScreen> createState() => _TomaInventarioScreenState();
}

class _TomaInventarioScreenState extends State<TomaInventarioScreen> {
  final List<InventoryItem> _inventoryItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Todos';
  bool _showBalance = false;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  
  void _loadSampleData() {
    setState(() {
      _inventoryItems.addAll([
        InventoryItem(
          id: 1,
          name: 'Laptop Dell XPS 13',
          sku: 'DL-XPS13-2024',
          category: 'Tecnología',
          currentStock: 15,
          physicalCount: 14,
          cost: 1200.00,
          price: 1599.00,
          status: InventoryStatus.discrepancy,
        ),
        InventoryItem(
          id: 2,
          name: 'Mouse Inalámbrico Logitech',
          sku: 'LG-MX-MASTER3',
          category: 'Accesorios',
          currentStock: 45,
          physicalCount: 45,
          cost: 89.99,
          price: 129.99,
          status: InventoryStatus.matched,
        ),
        InventoryItem(
          id: 3,
          name: 'Monitor 27" 4K Samsung',
          sku: 'SS-MON27UHD',
          category: 'Tecnología',
          currentStock: 8,
          physicalCount: 6,
          cost: 350.00,
          price: 499.00,
          status: InventoryStatus.discrepancy,
        ),
        InventoryItem(
          id: 4,
          name: 'Teclado Mecánico RGB',
          sku: 'RK-K61-RGB',
          category: 'Accesorios',
          currentStock: 22,
          physicalCount: 22,
          cost: 65.00,
          price: 89.99,
          status: InventoryStatus.matched,
        ),
        InventoryItem(
          id: 5,
          name: 'Dock Station USB-C',
          sku: 'CK-DOCK-PRO',
          category: 'Accesorios',
          currentStock: 18,
          physicalCount: 0,
          cost: 120.00,
          price: 179.00,
          status: InventoryStatus.missing,
        ),
      ]);
    });
  }

    void _updatePhysicalCount(int itemId, int newCount) {
    setState(() {
      final item = _inventoryItems.firstWhere((element) => element.id == itemId);
      item.physicalCount = newCount;
      item.status = _calculateStatus(item.currentStock, newCount);
    });
  }

  InventoryStatus _calculateStatus(int currentStock, int physicalCount) {
    if (physicalCount == 0) return InventoryStatus.missing;
    if (physicalCount == currentStock) return InventoryStatus.matched;
    return InventoryStatus.discrepancy;
  }


  void _crearNuevaTomaInventario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaTomaInventarioScreen(
          usuarioActual: 'Usuario Actual',
        ),
      ),
    ).then((result) {
      if (result != null && result is NuevaTomaInventario) {
        _procesarNuevaToma(result);
      }
    });
  }

    void _actualizarInventarioExistente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualizarInventarioScreen(
          currentInventory: _inventoryItems,
          customerName: 'Cliente Principal',
          updatedBy: 'Usuario Actual',
        ),
      ),
    ).then((result) {
      if (result != null && result is InventoryUpdate) {
        _processInventoryUpdate(result);
      }
    });
  }
  void _procesarNuevaToma(NuevaTomaInventario nuevaToma) {
    setState(() {
      _inventoryItems.clear();
      _inventoryItems.addAll(nuevaToma.items);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nueva toma creada: ${nuevaToma.items.length} productos'),
        backgroundColor: Colors.green,
      ),
    );
  }

     void _processInventoryUpdate(InventoryUpdate update) {
    for (final updateItem in update.items) {
      final existingIndex = _inventoryItems.indexWhere(
        (item) => item.id == updateItem.productId
      );
      
      if (existingIndex != -1) {
        setState(() {
          _inventoryItems[existingIndex].currentStock = updateItem.newStock;
          _inventoryItems[existingIndex].physicalCount = updateItem.newStock;
          _inventoryItems[existingIndex].status = _calculateStatus(
            updateItem.newStock, 
            updateItem.newStock
          );
        });
      } else if (updateItem.action == 'added') {
        setState(() {
          _inventoryItems.add(InventoryItem(
            id: updateItem.productId,
            name: updateItem.productName,
            sku: updateItem.sku,
            category: 'General',
            currentStock: updateItem.newStock,
            physicalCount: updateItem.newStock,
            cost: 0.0,
            price: 0.0,
            status: InventoryStatus.matched,
          ));
        });
      }
    }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inventario actualizado: ${update.items.length} cambios'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<InventoryItem> get _filteredItems {
    if (_filterStatus == 'Todos') return _inventoryItems;
    return _inventoryItems.where((item) {
      switch (_filterStatus) {
        case 'Con Discrepancia':
          return item.status == InventoryStatus.discrepancy;
        case 'Faltante':
          return item.status == InventoryStatus.missing;
        case 'Correcto':
          return item.status == InventoryStatus.matched;
        default:
          return true;
      }
    }).toList();
  }

   InventoryBalance get _balance {
    int totalItems = _inventoryItems.length;
    int matchedItems = _inventoryItems.where((item) => item.status == InventoryStatus.matched).length;
    int discrepancyItems = _inventoryItems.where((item) => item.status == InventoryStatus.discrepancy).length;
    int missingItems = _inventoryItems.where((item) => item.status == InventoryStatus.missing).length;
    
    double totalValueDifference = _inventoryItems.fold(0.0, (sum, item) {
      return sum + ((item.physicalCount - item.currentStock) * item.cost);
    });

    double accuracyRate = totalItems > 0 ? (matchedItems / totalItems) * 100 : 0;

    return InventoryBalance(
      totalItems: totalItems,
      matchedItems: matchedItems,
      discrepancyItems: discrepancyItems,
      missingItems: missingItems,
      totalValueDifference: totalValueDifference,
      accuracyRate: accuracyRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toma de Inventario'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 88, 63, 128),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.balance),
            onPressed: () {
              setState(() {
                _showBalance = !_showBalance;
              });
            },
            tooltip: 'Ver Balance',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con métricas rápidas
          _buildMetricsHeader(balance),
          
          // Filtros y búsqueda
          _buildFilterSection(),
          
          // Balance expandible
          if (_showBalance) _buildBalanceSection(balance),
          
          // Lista de items
          Expanded(
            child: _buildInventoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Nueva Toma de Inventario'),
                  onTap: () {
                    Navigator.pop(context);
                    _crearNuevaTomaInventario(); // ✅ CORREGIDO
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Actualizar Inventario Existente'),
                  onTap: () {
                    Navigator.pop(context);
                    _actualizarInventarioExistente(); // ✅ CORREGIDO
                  },
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 88, 63, 128),
        child: const Icon(Icons.inventory, color: Colors.white),
      ),
    );
  }



  Widget _buildMetricsHeader(InventoryBalance balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMetricItem(
            value: balance.totalItems.toString(),
            label: 'Total Items',
            color: Colors.blue,
          ),
          _buildMetricItem(
            value: '${balance.matchedItems}',
            label: 'Correctos',
            color: Colors.green,
          ),
          _buildMetricItem(
            value: '${balance.discrepancyItems}',
            label: 'Discrepancias',
            color: Colors.orange,
          ),
          _buildMetricItem(
            value: '${balance.missingItems}',
            label: 'Faltantes',
            color: Colors.red,
          ),
        ],
      ),
    );
  }


  Widget _buildMetricItem({required String value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
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
                    _filterStatus = value;
                  });
                },
                itemBuilder: (context) => [
                  'Todos',
                  'Con Discrepancia',
                  'Faltante',
                  'Correcto',
                ].map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Text(status),
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
                      Text(_filterStatus),
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

  Widget _buildBalanceSection(InventoryBalance balance) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color.fromARGB(255, 88, 63, 128)),
              SizedBox(width: 8),
              Text(
                'Balance de Inventario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 88, 63, 128),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Gráfico de precisión con widgets nativos
          _buildCustomAccuracyChart(balance),
          const SizedBox(height: 20),
          
          // Métricas detalladas
          Row(
            children: [
              Expanded(
                child: _buildBalanceMetric(
                  'Precisión',
                  '${balance.accuracyRate.toStringAsFixed(1)}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildBalanceMetric(
                  'Diferencia Valor',
                  '\$${balance.totalValueDifference.abs().toStringAsFixed(2)}',
                  balance.totalValueDifference >= 0 ? Colors.green : Colors.red,
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Desglose por estado
          _buildStatusBreakdown(balance),
        ],
      ),
    );
  }

  Widget _buildCustomAccuracyChart(InventoryBalance balance) {
    final total = balance.totalItems.toDouble();
  final matchedPercent = total > 0 ? (balance.matchedItems / total) * 100 : 0.0; // ✅ Cambiar a 0.0
  final discrepancyPercent = total > 0 ? (balance.discrepancyItems / total) * 100 : 0.0; // ✅ Cambiar a 0.0
  final missingPercent = total > 0 ? (balance.missingItems / total) * 100 : 0.0; // ✅ Cambiar a 0.0

    return Column(
      children: [
        // Barra de progreso compuesta
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Row(
            children: [
              if (matchedPercent > 0)
                Expanded(
                  flex: matchedPercent.round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (discrepancyPercent > 0)
                Expanded(
                  flex: discrepancyPercent.round(),
                  child: Container(
                    color: Colors.orange,
                  ),
                ),
              if (missingPercent > 0)
                Expanded(
                  flex: missingPercent.round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Leyenda
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildChartLegend('Correctos', matchedPercent, Colors.green),
            _buildChartLegend('Discrepancias', discrepancyPercent, Colors.orange),
            _buildChartLegend('Faltantes', missingPercent, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, double percent, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(InventoryBalance balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose por Estado:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('Correctos', balance.matchedItems, Colors.green),
            const SizedBox(width: 8),
            _buildStatusChip('Discrepancias', balance.discrepancyItems, Colors.orange),
            const SizedBox(width: 8),
            _buildStatusChip('Faltantes', balance.missingItems, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    if (_filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron items',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildInventoryItem(item);
      },
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    final difference = item.physicalCount - item.currentStock;
    final valueDifference = difference * item.cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          color: _getStatusColor(item.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(item.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.sku,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Count controls and info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Stock info
              Row(
                children: [
                  Column(
                    children: [
                      Text(
                        'Sistema',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        item.currentStock.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        'Físico',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          controller: TextEditingController(text: item.physicalCount.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newCount = int.tryParse(value) ?? 0;
                            _updatePhysicalCount(item.id, newCount);
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Difference indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${difference >= 0 ? '+' : ''}$difference • \$${valueDifference.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _getStatusColor(item.status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.matched:
        return Colors.green;
      case InventoryStatus.discrepancy:
        return Colors.orange;
      case InventoryStatus.missing:
        return Colors.red;
    }
  }

  void _startNewCount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Toma de Inventario'),
        content: const Text('¿Desea iniciar una nueva toma de inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Lógica para nueva toma
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte exportado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
