import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/actualizar_inventario_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/inventario/nuevaTomaInventario.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_service_odoo.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_sync_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
//import 'package:fl_chart/fl_chart.dart';
class TomaInventarioScreen extends StatefulWidget {
  const TomaInventarioScreen({super.key});

  @override
  State<TomaInventarioScreen> createState() => _TomaInventarioScreenState();
}

class _TomaInventarioScreenState extends State<TomaInventarioScreen> {
  List<InventoryItem> _inventoryItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Todos';
  bool _showBalance = false;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _mostrarBusqueda = false;
  String _currentSearchQuery = '';
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 50;
  
  // Lista completa de productos (con paginación)
  List<Map<String, dynamic>> _allProductsOdoo = [];
  final List<InventoryItem> _allInventoryItems = []; 


  late OdooInventoryService _inventoryService;
  late InventorySyncManager _syncManager; 
  SyncStatus? _syncStatus; 


  
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13],
    facing: CameraFacing.back,
  );
  
  bool _mostrarScanner = false;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _initializeServices(); 
    _loadProductsFromOdoo();
    _checkSyncStatus(); 
  }
  @override
void dispose() {
  _scannerController.dispose(); 
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
}

    void _initializeServices() {
    final odooService = OdooServiceEnhanced(
      baseUrl: 'https://solutions.tailorw.net',
      dbName: 'pointsales_prodv18',
    );
    _inventoryService = OdooInventoryService(odooService);
    
    //  INICIALIZAR SYNC MANAGER
    final productService = OdooProductService(odooService);
    _syncManager = InventorySyncManager(_inventoryService, productService);
  }
// ✅ CARGAR PRODUCTOS INICIALES
Future<void> _loadInitialProducts() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isAuthenticated = await _inventoryService.odooService.login('admin', 'admin');
    if (!isAuthenticated) throw Exception('Error de autenticación');

    // Cargar primera página
    await _loadMoreProducts();

  } catch (e) {
    print('❌ Error cargando productos iniciales: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Error: $e';
    });
  }
}

// ✅ CARGAR MÁS PRODUCTOS (PAGINACIÓN)
Future<void> _loadMoreProducts({String searchQuery = ''}) async {
  if (_isLoadingMore || !_hasMore) return;

  try {
    setState(() => _isLoadingMore = true);

    final products = await _inventoryService.getProductsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      searchQuery: searchQuery,
    );

    if (products.isEmpty) {
      setState(() => _hasMore = false);
    } else {
      setState(() {
        _allProductsOdoo.addAll(products);
        _currentPage++;
        _convertProductsToInventoryItems();
      });
    }
  } catch (e) {
    print('❌ Error cargando más productos: $e');
  } finally {
    setState(() => _isLoadingMore = false);
  }
}

// ✅ MANEJAR CAMBIOS EN LA BÚSQUEDA
void _onSearchChanged() {
  final query = _searchController.text.trim();
  if (query != _currentSearchQuery) {
    _performSearch(query);
  }
}

// ✅ REALIZAR BÚSQUEDA
void _performSearch(String query) {
  setState(() {
    _currentSearchQuery = query;
    _allProductsOdoo.clear();
    _inventoryItems.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
  });

  // Pequeño delay para evitar búsquedas muy frecuentes
  Future.delayed(const Duration(milliseconds: 500), () {
    _loadMoreProducts(searchQuery: query);
  });
}

// ✅ CONVERTIR PRODUCTOS ODDO A INVENTORY ITEMS
void _convertProductsToInventoryItems() {
  final newInventoryItems = <InventoryItem>[];
  
  for (final product in _allProductsOdoo) {
    final productId = product['id'];
    final productName = product['name'] ?? 'Sin nombre';
    final defaultCode = product['default_code']?.toString() ?? '';
    final category = product['categ_id']?[1]?.toString() ?? 'Sin categoría';
    
    if (_inventoryService.shouldManageStock(product)) {
      newInventoryItems.add(InventoryItem(
        id: productId,
        name: productName,
        sku: defaultCode,
        category: category,
        currentStock: product['qty_available']?.toInt() ?? 0,
        physicalCount: product['qty_available']?.toInt() ?? 0,
        cost: 0.0,
        price: 0.0,
        status: InventoryStatus.matched,
        managesStock: true,
      ));
    }
  }

  setState(() {
    _inventoryItems = newInventoryItems;
    _isLoading = false;
  });
}


void _handleScan(BarcodeCapture capture) async {
  if (_isProcessingScan || capture.barcodes.isEmpty) return;
  
  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  _isProcessingScan = true;
  
  try {
    print('📷 Código escaneado: $code');
    
    // Usar el servicio de inventario para procesar el código escaneado
    final result = await _inventoryService.processScannedProduct(code, null);
    
    if (result.success) {
      if (result.isService) {
        // Es servicio - mostrar información
        _showServiceDialog(result.product!);
      } else {
        // Es producto con stock - pedir conteo físico
        _showStockInputDialog(result, code);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('❌ Error en escaneo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error escaneando: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    _isProcessingScan = false;
    setState(() => _mostrarScanner = false);
  }
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _filterStatus = value),
                itemBuilder: (context) => ['Todos', 'Con Discrepancia', 'Faltante', 'Correcto'].map((status) {
                  return PopupMenuItem(value: status, child: Text(status));
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_filterStatus), const SizedBox(width: 4), const Icon(Icons.filter_list, size: 16)]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_filteredItems.length} de ${_inventoryItems.length} productos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
void _toggleScanner() {
  setState(() {
    _mostrarScanner = !_mostrarScanner;
  });
}

    Future<void> _performQuickSync() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Sincronizando discrepancias...'),
          backgroundColor: Colors.blue,
        ),
      );

      await _syncManager.performQuickSync();

      // Recargar productos después de la sincronización
      await _loadProductsFromOdoo();
      
      // Actualizar estado de sync
      await _checkSyncStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sincronización completada'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('❌ Error en sincronización: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error sincronizando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  // ✅ NUEVO MÉTODO FALTANTE: BALANCE
  InventoryBalance get _balance {
    int totalItems = _inventoryItems.length;
    int matchedItems = _inventoryItems.where((item) => item.status == InventoryStatus.matched).length;
    int discrepancyItems = _inventoryItems.where((item) => item.status == InventoryStatus.discrepancy).length;
    int missingItems = _inventoryItems.where((item) => item.status == InventoryStatus.missing).length;
    
    double totalValueDifference = _inventoryItems.fold(0.0, (sum, item) {
      return sum + ((item.physicalCount - item.currentStock) * item.cost);
    });

    double accuracyRate = totalItems > 0 ? (matchedItems / totalItems) * 100 : 0.0;

    return InventoryBalance(
      totalItems: totalItems,
      matchedItems: matchedItems,
      discrepancyItems: discrepancyItems,
      missingItems: missingItems,
      totalValueDifference: totalValueDifference,
      accuracyRate: accuracyRate,
      calculationDate: DateTime.now(),
    );
  }
  // ✅ AGREGAR ESTOS MÉTODOS FALTANTES AL FINAL:
  List<InventoryItem> get _filteredItems {
    var filtered = _inventoryItems;
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item.sku.toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item.category.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }
    
    if (_filterStatus != 'Todos') {
      filtered = filtered.where((item) {
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
    
    return filtered;
  }
  void _exportReport() {
    // Método temporal - implementar según necesites
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando reporte...')),
    );
  }

  // ✅ HEADER SIMPLIFICADO - SOLO DISCREPANCIAS Y FALTANTES
Widget _buildMetricsHeader(InventoryBalance balance) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1), 
          blurRadius: 10, 
          offset: const Offset(0, 2)
        ),
      ],
    ),
    child: Column(
      children: [
        // ✅ SOLO DOS OPCIONES: DISCREPANCIAS Y FALTANTES
        Row(
          children: [
            // DISCREPANCIAS
            Expanded(
              child: _buildStatusCard(
                title: 'Discrepancias',
                count: balance.discrepancyItems,
                color: Colors.orange,
                icon: Icons.warning,
                onTap: () => _mostrarProductosPorEstado(InventoryStatus.discrepancy),
              ),
            ),
            const SizedBox(width: 12),
            // FALTANTES
            Expanded(
              child: _buildStatusCard(
                title: 'Faltantes',
                count: balance.missingItems,
                color: Colors.red,
                icon: Icons.error,
                onTap: () => _mostrarProductosPorEstado(InventoryStatus.missing),
              ),
            ),
          ],
        ),
        
        // ✅ INDICADOR DE SINCRONIZACIÓN (OPCIONAL)
        if (_syncStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _syncStatus!.isSynced ? Icons.check_circle : Icons.sync_problem,
                  color: _syncStatus!.isSynced ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _syncStatus!.isSynced 
                    ? 'Sincronizado' 
                    : '${_syncStatus!.discrepancies} discrepancias',
                  style: TextStyle(
                    fontSize: 12,
                    color: _syncStatus!.isSynced ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ✅ TARJETA DE ESTADO MEJORADA
Widget _buildStatusCard({
  required String title,
  required int count,
  required Color color,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ÍCONO Y CONTADOR
          Stack(
            alignment: Alignment.center,
            children: [
              // ÍCONO DE FONDO
              Icon(
                icon,
                size: 32,
                color: color.withOpacity(0.2),
              ),
              // CONTADOR
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // TÍTULO
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // INDICADOR DE CLIC
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ver detalles',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 10,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  

  Widget _buildMetricItem({required String value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

 

  Widget _buildBalanceSection(InventoryBalance balance) {
    return Container(); // Implementar según necesites
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('SKU: ${item.sku} • Stock: ${item.currentStock} • Físico: ${item.physicalCount}'),
          trailing: Icon(
            item.status == InventoryStatus.matched ? Icons.check_circle : 
            item.status == InventoryStatus.discrepancy ? Icons.warning : Icons.error,
            color: item.status == InventoryStatus.matched ? Colors.green : 
                   item.status == InventoryStatus.discrepancy ? Colors.orange : Colors.red,
          ),
        );
      },
    );
  }


  // ✅ NUEVO MÉTODO: VERIFICAR ESTADO DE SINCRONIZACIÓN
  Future<void> _checkSyncStatus() async {
    try {
      final status = await _syncManager.getSyncStatus();
      setState(() {
        _syncStatus = status;
      });
    } catch (e) {
      print('❌ Error verificando estado de sync: $e');
    }
  }


Future<void> _loadProductsFromOdoo() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print('🔄 Cargando productos...');

    final isAuthenticated = await _inventoryService.odooService.login('admin', 'admin');
    
    if (!isAuthenticated) {
      throw Exception('Error de autenticación con Odoo');
    }

    print('✅ Autenticación exitosa, obteniendo productos...');
    
    final products = await _inventoryService.getAllProducts();
    
    print('📦 TOTAL PRODUCTOS OBTENIDOS: ${products.length}');
    
    // ✅ VERIFICAR SI EL PRODUCTO 47 ESTÁ EN LA LISTA
    final producto47 = products.firstWhere(
      (p) => p['id'] == 47,
      orElse: () => {},
    );
    
    if (producto47.isNotEmpty) {
      print('🎯 PRODUCTO 47 ENCONTRADO EN LA LISTA:');
      print('   Nombre: ${producto47['name']}');
      print('   Código: ${producto47['default_code']}');
      print('   Categoría: ${producto47['categ_id']}');
    } else {
      print('❌ PRODUCTO 47 NO ENCONTRADO EN LA LISTA DE PRODUCTOS');
    }

    if (products.isEmpty) {
      throw Exception('No se encontraron productos en Odoo');
    }

    final inventoryItemsTemp = <InventoryItem>[];
    int productosConStock = 0;
    int servicios = 0;
    int productosFiltrados = 0;
    
    print('🔍 Analizando ${products.length} productos...');
    
    for (final product in products) {
      final productId = product['id'];
      final productName = product['name'] ?? 'Sin nombre';
      final defaultCode = product['default_code']?.toString() ?? '';
      final category = product['categ_id']?[1]?.toString() ?? 'Sin categoría';
      
      // ✅ VERIFICAR PRODUCTO 47 ESPECÍFICAMENTE
      if (productId == 47) {
        print('🎯🎯🎯 PRODUCTO 47 DETECTADO 🎯🎯🎯');
        print('   Nombre: $productName');
        print('   Código: $defaultCode');
        print('   Categoría: $category');
      }
      
      final managesStock = _inventoryService.shouldManageStock(product);
      
      if (productId == 47) {
        print('   🎯 Maneja Stock: $managesStock');
      }
      
      if (managesStock) {
        if (productId == 47) {
          print('   🎯✅ PRODUCTO 47 SERÁ AGREGADO A LA LISTA');
        }
        
        // ... (resto de la lógica de stock)
        
        inventoryItemsTemp.add(InventoryItem(
          id: productId,
          name: productName,
          sku: defaultCode,
          category: category,
          currentStock: 20, // Temporal para pruebas
          physicalCount: 20, // Temporal para pruebas
          cost: 0.0,
          price: 0.0,
          status: InventoryStatus.matched,
          managesStock: true,
        ));
        productosConStock++;
        
      } else {
        if (productId == 47) {
          print('   🎯❌ PRODUCTO 47 FILTRADO - NO MANEJA STOCK');
        }
        servicios++;
        productosFiltrados++;
      }
    }

    // ✅ VERIFICAR SI EL 47 ESTÁ EN LA LISTA FINAL
    final producto47EnLista = inventoryItemsTemp.firstWhere(
      (item) => item.id == 47,
      orElse: () => InventoryItem(
        id: -1,
        name: '',
        sku: '',
        category: '',
        currentStock: 0,
        physicalCount: 0,
        cost: 0.0,
        price: 0.0,
        status: InventoryStatus.matched,
        managesStock: false,
      ),
    );

    if (producto47EnLista.id == 47) {
      print('🎯✅ PRODUCTO 47 AGREGADO A LA LISTA FINAL');
    } else {
      print('🎯❌ PRODUCTO 47 NO ESTÁ EN LA LISTA FINAL');
    }

    setState(() {
      _inventoryItems.clear();
      _inventoryItems.addAll(inventoryItemsTemp);
      _isLoading = false;
    });

    print('🎯 RESUMEN FINAL:');
    print('   📦 Productos obtenidos: ${products.length}');
    print('   ✅ Productos con stock: $productosConStock');
    print('   ❌ Servicios ignorados: $servicios');
    print('   🎯 Producto 47 en lista final: ${producto47EnLista.id == 47 ? "SÍ" : "NO"}');
    print('   📋 Total en pantalla: ${_inventoryItems.length}');

  } catch (e) {
    print('❌ Error cargando productos: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Error: $e';
    });
  }
}

  Future<void> _updatePhysicalCount(int itemId, int newCount) async {
    try {
      setState(() {
        final item = _inventoryItems.firstWhere((element) => element.id == itemId);
        item.physicalCount = newCount;
        item.status = _calculateStatus(item.currentStock, newCount);
      });

      // ✅ SINCRONIZAR CON ODDO EN TIEMPO REAL
      final item = _inventoryItems.firstWhere((element) => element.id == itemId);
      
      // Buscar el quant_id del producto
      final stockInfo = await _inventoryService.getProductStock(itemId);
      if (stockInfo != null && stockInfo['id'] != null) {
        final success = await _inventoryService.updateStock(
          stockInfo['id'], 
          newCount.toDouble()
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Stock actualizado : $newCount'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
        await _checkSyncStatus();
      
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error sincronizando con Odoo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


 Future<void> _scanProductAndUpdate() async {
    // Simular escaneo - en tu app real usarías un scanner real
    final scannedCode = await _showBarcodeInputDialog();
    if (scannedCode == null || scannedCode.isEmpty) return;

    final result = await _inventoryService.processScannedProduct(scannedCode, null);
    
    if (result.success) {
      if (result.isService) {
        // Es servicio - mostrar información
        _showServiceDialog(result.product!);
      } else {
        // Es producto con stock - pedir conteo físico
        _showStockInputDialog(result, scannedCode);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ VENTANA MEJORADA Y VISUALMENTE ATRACTIVA
void _showStockInputDialog(InventoryProcessResult result, String scannedCode) {
  final physicalCountController = TextEditingController();
  final product = result.product!;
  final stockInfo = result.stockInfo!;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER CON ÍCONO Y TÍTULO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF583F80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Color(0xFF583F80),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Actualizar Inventario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF583F80),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // ✅ INFORMACIÓN DEL PRODUCTO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip('SKU', product['default_code']?.toString() ?? 'N/A'),
                      const SizedBox(width: 8),
                      _buildInfoChip('Categoría', product['categ_id']?[1]?.toString() ?? 'Sin categoría'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ✅ STOCK ACTUAL VS FÍSICO
            Row(
              children: [
                Expanded(
                  child: _buildStockCard(
                    title: 'Stock Sistema',
                    value: '${stockInfo['inventory_quantity']?.toStringAsFixed(0) ?? '0'}',
                    color: Colors.blue,
                    icon: Icons.store,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockCard(
                    title: 'Conteo Físico',
                    value: physicalCountController.text.isEmpty ? '--' : physicalCountController.text,
                    color: Colors.green,
                    icon: Icons.checklist,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // ✅ CAMPO DE ENTRADA MEJORADO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: physicalCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ingresar conteo físico',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit, color: Colors.grey),
                  suffixText: 'unidades',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  // Actualizar en tiempo real el valor del conteo físico
                  if (context.mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ✅ INDICADOR DE DIFERENCIA
            if (physicalCountController.text.isNotEmpty)
              _buildDifferenceIndicator(
                double.parse(stockInfo['inventory_quantity']?.toString() ?? '0'),
                double.tryParse(physicalCountController.text) ?? 0,
              ),
            
            const SizedBox(height: 24),
            
            // ✅ BOTONES MEJORADOS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final physicalCount = int.tryParse(physicalCountController.text);
                      if (physicalCount != null && physicalCount >= 0) {
                        Navigator.pop(context);
                        
                        // Mostrar loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(width: 12),
                                Text('Actualizando stock a $physicalCount unidades...'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF583F80),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        
                        // Actualizar en Odoo
                        final updateResult = await _inventoryService.processScannedProduct(
                          scannedCode, 
                          physicalCount.toDouble()
                        );
                        
                        if (updateResult.success) {
                          // Actualizar en la lista local
                          final productId = product['id'];
                          await _updatePhysicalCount(productId, physicalCount);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('✅ Stock actualizado a $physicalCount unidades'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Ingresa un valor válido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF583F80),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Actualizar Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ✅ CHIP DE INFORMACIÓN
Widget _buildInfoChip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
  );
}

// ✅ TARJETA DE STOCK MEJORADA
Widget _buildStockCard({required String title, required String value, required Color color, required IconData icon}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ✅ INDICADOR DE DIFERENCIA
Widget _buildDifferenceIndicator(double systemStock, double physicalCount) {
  final difference = physicalCount - systemStock;
  final isPositive = difference > 0;
  final isZero = difference == 0;
  
  Color color;
  String text;
  IconData icon;
  
  if (isZero) {
    color = Colors.green;
    text = '✓ Correcto';
    icon = Icons.check_circle;
  } else if (isPositive) {
    color = Colors.orange;
    text = '+${difference.toInt()} unidades';
    icon = Icons.arrow_upward;
  } else {
    color = Colors.red;
    text = '${difference.toInt()} unidades';
    icon = Icons.arrow_downward;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

  // ✅ DIALOGO PARA SERVICIOS
  void _showServiceDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${product['default_code']}'),
            Text('Categoría: ${product['categ_id']?[1] ?? "N/A"}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SERVICIO - Sin gestión de stock',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  // ✅ DIALOGO PARA INGRESAR CÓDIGO DE BARRAS
  Future<String?> _showBarcodeInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escanear Producto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingresar código de barras...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
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
    if (_inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos para actualizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            category: updateItem.category,
            currentStock: updateItem.newStock,
            physicalCount: updateItem.newStock,
            cost: updateItem.cost,
            price: updateItem.price,
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
        // ✅ BOTÓN DE CÁMARA/SCANNER
        IconButton(
          icon: Icon(_mostrarScanner ? Icons.camera_alt : Icons.qr_code_scanner),
          onPressed: _toggleScanner,
          tooltip: 'Escanear código',
        ),
        if (_syncStatus != null && _syncStatus!.discrepancies > 0)
          IconButton(
            icon: Badge(
              label: Text('${_syncStatus!.discrepancies}'),
              child: const Icon(Icons.sync_problem),
            ),
            onPressed: _performQuickSync,
            tooltip: 'Sincronizar discrepancias',
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProductsFromOdoo,
          tooltip: 'Actualizar productos',
        ),
        IconButton(
          icon: const Icon(Icons.balance),
          onPressed: () {
            setState(() {
              _showBalance = !_showBalance;
            });
          },
          tooltip: 'Ver Balance',
        ),
        if (_inventoryItems.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _exportReport,
        ),
      ],
    ),
    body: _isLoading 
        ? _buildLoadingState()
        : _inventoryItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // ✅ SCANNER (NO SCROLLEA - FIJO ARRIBA)
                if (_mostrarScanner) 
                  Container(
                    height: 250,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleScan,
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black54,
                            child: const Text(
                              'Enfoca un código de barras o QR',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // ✅ CONTENIDO PRINCIPAL CON SCROLL
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMetricsHeader(balance),
                        _buildFilterSection(),
                        _buildChartSection(balance),
                        if (_showBalance) _buildBalanceSection(balance),
                        // LISTA DE PRODUCTOS
                        Column(
                          children: _filteredItems.map((item) => _buildInventoryItem(item)).toList(),
                        ),
                        const SizedBox(height: 80), // Espacio para FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
    floatingActionButton: _inventoryItems.isNotEmpty ? FloatingActionButton(
      onPressed: _toggleScanner,
      backgroundColor: const Color.fromARGB(255, 88, 63, 128),
      child: Icon(_mostrarScanner ? Icons.close : Icons.qr_code_scanner, color: Colors.white),
    ) : null,
  );
}
// ✅ NUEVO: MOSTRAR PRODUCTOS POR ESTADO (DISCREPANCIAS O FALTANTES)
// ✅ MEJORADO: MOSTRAR PRODUCTOS POR ESTADO CON MÁS FUNCIONALIDADES
void _mostrarProductosPorEstado(InventoryStatus status) {
  final productosFiltrados = _inventoryItems.where((item) => item.status == status).toList();
  
  // Configuración según el estado
  final Map<InventoryStatus, Map<String, dynamic>> config = {
    InventoryStatus.discrepancy: {
      'titulo': 'Discrepancias',
      'color': Colors.orange,
      'icon': Icons.warning,
      'descripcion': 'Productos con diferencias entre el stock físico y el sistema',
    },
    InventoryStatus.missing: {
      'titulo': 'Productos Faltantes',
      'color': Colors.red,
      'icon': Icons.error,
      'descripcion': 'Productos que existen en el sistema pero no en el inventario físico',
    },
  };

  final configEstado = config[status]!;
  final color = configEstado['color'] as Color;
  final icon = configEstado['icon'] as IconData;
  final titulo = configEstado['titulo'] as String;
  final descripcion = configEstado['descripcion'] as String;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text('$titulo (${productosFiltrados.length})'),
            ],
          ),
          backgroundColor: color,
          actions: [
            if (productosFiltrados.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: () => _exportarReporteEspecifico(productosFiltrados, titulo),
                tooltip: 'Exportar reporte',
              ),
          ],
        ),
        body: productosFiltrados.isEmpty
            ? _buildEmptyStateEspecifico(titulo, descripcion, icon, color)
            : Column(
                children: [
                  // ✅ HEADER INFORMATIVO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            descripcion,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ LISTA DE PRODUCTOS
                  Expanded(
                    child: ListView.builder(
                      itemCount: productosFiltrados.length,
                      itemBuilder: (context, index) {
                        final item = productosFiltrados[index];
                        return _buildInventoryItemDetailed(item, color);
                      },
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

// ✅ ESTADO VACÍO ESPECÍFICO
Widget _buildEmptyStateEspecifico(String titulo, String descripcion, IconData icon, Color color) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No hay $titulo',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.scanner),
          label: const Text('Escanear Productos'),
          onPressed: _toggleScanner,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ✅ EXPORTAR REPORTE ESPECÍFICO
void _exportarReporteEspecifico(List<InventoryItem> productos, String tipo) {
  // Aquí implementarías la lógica de exportación
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Exportando reporte de $tipo (${productos.length} productos)'),
      backgroundColor: Colors.blue,
    ),
  );
  
  // Ejemplo de implementación:
  print('📊 Reporte de $tipo:');
  for (final producto in productos) {
    final diferencia = producto.physicalCount - producto.currentStock;
    print('   ${producto.name} - Sistema: ${producto.currentStock}, Físico: ${producto.physicalCount}, Diferencia: $diferencia');
  }
}
// ✅ NUEVO: ITEM DETALLADO PARA VISTA ESPECÍFICA
Widget _buildInventoryItemDetailed(InventoryItem item, Color color) {
  final difference = item.physicalCount - item.currentStock;
  
  return Container(
    margin: const EdgeInsets.all(8),
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
      border: Border.all(color: color.withOpacity(0.3), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item.sku}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // INFORMACIÓN DE STOCK
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStockInfo('Sistema', item.currentStock.toString(), Colors.blue),
            _buildStockInfo('Físico', item.physicalCount.toString(), color),
            _buildStockInfo(
              'Diferencia', 
              '${difference >= 0 ? '+' : ''}$difference',
              difference == 0 ? Colors.green : color
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // BOTÓN PARA CORREGIR
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showEditDialog(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Corregir Conteo'),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStockInfo(String label, String value, Color color) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}
// ✅ CONTENIDO PRINCIPAL CON BÚSQUEDA Y PAGINACIÓN
// ✅ CONTENIDO PRINCIPAL COMPLETO Y CORREGIDO
Widget _buildContent() {
  final filteredItems = _filteredItems;
  
  return Column(
    children: [
      // BARRA DE BÚSQUEDA
      if (_mostrarBusqueda)
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}), // ✅ ACTUALIZAR EN TIEMPO REAL
            decoration: InputDecoration(
              hintText: "Buscar por nombre, código o barras...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _currentSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),

      // INDICADOR DE ESTADO
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentSearchQuery.isEmpty
                  ? "${filteredItems.length} productos${_hasMore ? '+' : ''}"
                  : '"$_currentSearchQuery" - ${filteredItems.length} resultados${_hasMore ? '+' : ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (_isLoading || _isLoadingMore)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),

      // ✅ SCANNER (SI ESTÁ ACTIVO)
      if (_mostrarScanner) 
        _buildScannerSection(),

      // CONTENIDO PRINCIPAL
      Expanded(
        child: _isLoading && _inventoryItems.isEmpty
            ? _buildLoadingState()
            : _inventoryItems.isEmpty
                ? _buildEmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      _onScroll(scrollInfo);
                      return false;
                    },
                    child: Column(
                      children: [
                        // ✅ MÉTRICAS, FILTROS Y GRÁFICA
                        _buildMetricsHeader(_balance),
                        _buildFilterSection(),
                        _buildChartSection(_balance), // ✅ GRÁFICA DEL BALANCE RECUPERADA
                        
                        // ✅ BALANCE DETALLADO (SI ESTÁ ACTIVO)
                        if (_showBalance) _buildBalanceSection(_balance),
                        
                        // LISTA DE PRODUCTOS FILTRADOS
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredItems.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                            itemBuilder: (context, index) {
                              if (index == filteredItems.length) {
                                return _buildLoadMoreLoader();
                              }
                              
                              final item = filteredItems[index];
                              return _buildInventoryItem(item);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    ],
  );
}
// ✅ MANEJAR SCROLL PARA CARGA AUTOMÁTICA
void _onScroll(ScrollNotification scrollInfo) {
  if (scrollInfo is ScrollEndNotification &&
      scrollInfo.metrics.extentAfter == 0 &&
      _hasMore &&
      !_isLoadingMore) {
    _loadMoreProducts(searchQuery: _currentSearchQuery);
  }
}

// ✅ LOADER PARA CARGAR MÁS
Widget _buildLoadMoreLoader() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: _isLoadingMore
          ? const CircularProgressIndicator(strokeWidth: 2)
          : OutlinedButton(
              onPressed: () => _loadMoreProducts(searchQuery: _currentSearchQuery),
              child: const Text("Cargar más productos"),
            ),
    ),
  );
}

// ✅ ESTADO VACÍO MEJORADO
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _currentSearchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          _currentSearchQuery.isEmpty 
              ? "No hay productos disponibles"
              : 'No se encontraron resultados para "${_currentSearchQuery}"',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        if (_currentSearchQuery.isNotEmpty)
          TextButton(
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
            child: const Text('Limpiar búsqueda'),
          ),
      ],
    ),
  );
}

// ✅ SECCIÓN DEL SCANNER
Widget _buildScannerSection() {
  return Container(
    height: 250,
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _handleScan,
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: const Text(
              'Enfoca un código de barras o QR',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

// ✅ GRÁFICO ESTADÍSTICO COMPLETO Y CORREGIDO
Widget _buildChartSection(InventoryBalance balance) {
  final total = balance.totalItems.toDouble();
  if (total == 0) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No hay datos para mostrar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics, size: 18, color: Color.fromARGB(255, 88, 63, 128)),
            SizedBox(width: 8),
            Text(
              'Distribución del Inventario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color.fromARGB(255, 88, 63, 128),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // ✅ GRÁFICO DE BARRAS HORIZONTAL CON WIDGETS NATIVOS
        _buildNativeBarChart(balance, total),
        
        const SizedBox(height: 16),
        
        // ✅ LEYENDA DETALLADA CORREGIDA
        _buildChartLegendDetailed(balance, total),
      ],
    ),
  );
}

// ✅ GRÁFICO DE BARRAS CON WIDGETS NATIVOS
Widget _buildNativeBarChart(InventoryBalance balance, double total) {
  final maxValue = [balance.matchedItems, balance.discrepancyItems, balance.missingItems]
      .reduce((a, b) => a > b ? a : b)
      .toDouble();

  return Column(
    children: [
      // BARRAS
      Row(
        children: [
          _buildNativeBar('✅', balance.matchedItems, maxValue, Colors.green, 'Correctos'),
          const SizedBox(width: 12),
          _buildNativeBar('⚠️', balance.discrepancyItems, maxValue, Colors.orange, 'Discrep.'),
          const SizedBox(width: 12),
          _buildNativeBar('❌', balance.missingItems, maxValue, Colors.red, 'Faltantes'),
        ],
      ),
      const SizedBox(height: 8),
      
      // LÍNEA DE REFERENCIA Y VALORES
      Container(
        height: 20,
        child: Stack(
          children: [
            // LÍNEA DE REFERENCIA
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              child: Container(
                height: 1,
                color: Colors.grey[300],
              ),
            ),
            // VALORES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('0', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text('${(maxValue / 2).round()}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text('${maxValue.round()}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// ✅ BARRA INDIVIDUAL NATIVA
Widget _buildNativeBar(String emoji, int value, double maxValue, Color color, String label) {
  final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
  
  return Expanded(
    child: Column(
      children: [
        // EMOJI Y LABEL
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        // BARRA
        Container(
          height: 120,
          width: 30,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // FONDO DE LA BARRA
              Container(
                width: 20,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // BARRA DE VALOR
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 20,
                height: percentage * 100,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // VALOR NUMÉRICO
              Positioned(
                top: 105,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ✅ LEYENDA DETALLADA CORREGIDA
Widget _buildChartLegendDetailed(InventoryBalance balance, double total) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Total', '${balance.totalItems}', Icons.inventory_2, Colors.blue),
        _buildLegendItem('Precisión', '${balance.accuracyRate.toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
        _buildLegendItem('Problemas', '${balance.discrepancyItems + balance.missingItems}', Icons.warning_amber, Colors.orange),
      ],
    ),
  );
}

// ✅ ÍTEM DE LEYENDA
Widget _buildLegendItem(String label, String value, IconData icon, Color color) {
  return Column(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
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

// ✅ MÉTODO _buildChartLegend CORREGIDO PARA ACEPTAR DOUBLE
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
        '${percent.toStringAsFixed(1)}%', // ✅ MOSTRAR CON 1 DECIMAL
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando productos...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }




  Widget _buildCustomAccuracyChart(InventoryBalance balance) {
  final total = balance.totalItems.toDouble();
  final matchedPercent = total > 0 ? (balance.matchedItems / total) * 100 : 0.0;
  final discrepancyPercent = total > 0 ? (balance.discrepancyItems / total) * 100 : 0.0;
  final missingPercent = total > 0 ? (balance.missingItems / total) * 100 : 0.0;

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
      
      // Leyenda - CORREGIR LOS PORCENTAJES
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
        
        // Count controls and info - ✅ VERSIÓN EDITABLE DIRECTAMENTE
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
                    // ✅ CAMBIO: Hacer el campo editable directamente
                    GestureDetector(
                      onTap: () {
                        _showEditDialog(item);
                      },
                      child:
                      // En _buildInventoryItem, reemplazar el GestureDetector con:
                      Container(
                           width: 60,
                           height: 32,
                          decoration: BoxDecoration(
                             border: Border.all(color: Colors.blue.withOpacity(0.5)),
                             borderRadius: BorderRadius.circular(8),
                             color: Colors.blue[50],
                           ),
                          child: TextField(
                             textAlign: TextAlign.center,
                             controller: TextEditingController(text: item.physicalCount.toString()),
                             keyboardType: TextInputType.number,
                             decoration: const InputDecoration(
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.zero,
                          ),
                            style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                          onChanged: (value) {
                            final newCount = int.tryParse(value) ?? item.physicalCount;
                            if (newCount != item.physicalCount) {
                            _updatePhysicalCount(item.id, newCount);
                          }
                          },
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
                '${difference >= 0 ? '+' : ''}$difference',
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


void _showEditDialog(InventoryItem item) {
  final controller = TextEditingController(text: item.physicalCount.toString());
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Editar Conteo - ${item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SKU: ${item.sku}'),
          Text('Stock Sistema: ${item.currentStock}'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Conteo Físico',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newCount = int.tryParse(controller.text) ?? item.physicalCount;
            Navigator.pop(context);
            await _updatePhysicalCount(item.id, newCount);
          },
          child: const Text('Actualizar'),
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
 
}
