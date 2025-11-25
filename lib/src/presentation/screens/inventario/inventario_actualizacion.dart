// inventory_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/nuevaTomaInventario.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/actualizar_inventario_screen.dart';


import 'package:intl/intl.dart';

class InventoryDashboardScreen extends StatefulWidget {
  final String usuarioActual;

  const InventoryDashboardScreen({super.key, required this.usuarioActual});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  final List<InventoryUpdate> _updateHistory = [];
  InventoryBalance? _currentBalance;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  void _loadInventoryData() {
    // Cargar datos iniciales del inventario
  }

  void _navigateToUpdateInventory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualizarInventarioScreen(
          currentInventory: [], // Pasar inventario actual
          customerName: 'Cliente Principal', // Pasar nombre del cliente
          updatedBy: widget.usuarioActual,
        ),
      ),
    );

    if (result != null && result is InventoryUpdate) {
      setState(() {
        _updateHistory.insert(0, result);
        _currentBalance = result.balance;
      });
    }
  }

  void _navigateToNewInventory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaTomaInventarioScreen(
          usuarioActual: widget.usuarioActual,
        ),
      ),
    );

    if (result != null) {
      // Manejar resultado de nueva toma
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 88, 63, 128),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
            tooltip: 'Historial de actualizaciones',
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen de balance
          _buildBalanceCard(),
          
          // Acciones rápidas
          _buildQuickActions(),
          
          // Historial reciente
          Expanded(
            child: _buildRecentHistory(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpdateInventory,
        backgroundColor: const Color.fromARGB(255, 88, 63, 128),
        child: const Icon(Icons.inventory_2, color: Colors.white),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Resumen de Inventario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 88, 63, 128),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentBalance != null) ...[
              _buildBalanceMetric('Total Items', _currentBalance!.totalItems.toString()),
              _buildBalanceMetric('Coinciden', _currentBalance!.matchedItems.toString()),
              _buildBalanceMetric('Discrepancias', _currentBalance!.discrepancyItems.toString()),
              _buildBalanceMetric('Faltantes', _currentBalance!.missingItems.toString()),
              _buildBalanceMetric('Precisión', '${_currentBalance!.accuracyRate.toStringAsFixed(1)}%'),
              _buildBalanceMetric('Diferencia Valor', '\$${_currentBalance!.totalValueDifference.toStringAsFixed(2)}'),
            ] else ...[
              const Text('No hay datos de balance disponibles'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: InkWell(
                onTap: _navigateToUpdateInventory,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.update, color: Colors.blue, size: 32),
                      SizedBox(height: 8),
                      Text('Actualizar', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: InkWell(
                onTap: _navigateToNewInventory,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.add_box, color: Colors.green, size: 32),
                      SizedBox(height: 8),
                      Text('Nueva Toma', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: InkWell(
                onTap: _showBalanceDetails,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.analytics, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text('Balance', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Actualizaciones Recientes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _updateHistory.isEmpty
              ? _buildEmptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _updateHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(_updateHistory[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay actualizaciones recientes',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(InventoryUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.inventory, color: Colors.blue),
        title: Text('Actualización - ${DateFormat('dd/MM/yy HH:mm').format(update.timestamp)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por: ${update.updatedBy}'),
            Text('Cliente: ${update.customerName}'),
            Text('${update.items.length} productos actualizados'),
          ],
        ),
        trailing: Chip(
          label: Text('${update.balance.accuracyRate.toStringAsFixed(0)}%'),
          backgroundColor: update.balance.accuracyRate > 90 ? Colors.green : Colors.orange,
        ),
        onTap: () => _showUpdateDetails(update),
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial Completo'),
        content: SizedBox(
          width: double.maxFinite,
          child: _updateHistory.isEmpty
              ? const Text('No hay historial disponible')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _updateHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(_updateHistory[index]);
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDetails(InventoryUpdate update) {
    showDialog(
      context: context,
      builder: (context) => UpdateDetailsDialog(update: update),
    );
  }

  void _showBalanceDetails() {
    if (_currentBalance == null) return;
    
    showDialog(
      context: context,
      builder: (context) => BalanceDetailsDialog(balance: _currentBalance!),
    );
  }
}

class UpdateDetailsDialog extends StatelessWidget {
  final InventoryUpdate update;

  const UpdateDetailsDialog({super.key, required this.update});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalles de Actualización'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(update.timestamp)),
              _buildDetailRow('Actualizado por:', update.updatedBy),
              _buildDetailRow('Cliente:', update.customerName),
              _buildDetailRow('Notas:', update.notes.isEmpty ? 'Sin notas' : update.notes),
              
              const SizedBox(height: 16),
              const Text('Productos actualizados:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...update.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${item.productName}: ${item.previousStock} → ${item.newStock} (${item.difference > 0 ? '+' : ''}${item.difference})'),
              )),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class BalanceDetailsDialog extends StatelessWidget {
  final InventoryBalance balance;

  const BalanceDetailsDialog({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalles del Balance'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceDetail('Total de items:', balance.totalItems.toString()),
            _buildBalanceDetail('Items que coinciden:', balance.matchedItems.toString()),
            _buildBalanceDetail('Discrepancias:', balance.discrepancyItems.toString()),
            _buildBalanceDetail('Items faltantes:', balance.missingItems.toString()),
            _buildBalanceDetail('Tasa de precisión:', '${balance.accuracyRate.toStringAsFixed(1)}%'),
            _buildBalanceDetail('Diferencia de valor:', '\$${balance.totalValueDifference.toStringAsFixed(2)}'),
            _buildBalanceDetail('Calculado el:', DateFormat('dd/MM/yyyy HH:mm').format(balance.calculationDate)),
          ],
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

  Widget _buildBalanceDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}