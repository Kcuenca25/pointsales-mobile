import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_service_odoo.dart';
import 'package:ecomerce_app/src/services/service_company.dart';

class TomaInventarioScreen extends StatefulWidget {
  const TomaInventarioScreen({super.key});

  @override
  State<TomaInventarioScreen> createState() => _TomaInventarioScreenState();
}

class _TomaInventarioScreenState extends State<TomaInventarioScreen> {
  OdooInventoryService? _inventoryService;

  // Scanner variables
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
    facing: CameraFacing.back,
  );
  bool _mostrarScanner = false;
  bool _isProcessingScan = false;

  // Cada elemento es un stock.quant:
  // { id, product_id: [id, name], quantity, inventory_quantity, location_id }
  List<Map<String, dynamic>> _allQuants = []; // Caché local de todos los registros para búsqueda instantánea
  List<Map<String, dynamic>> _quants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _errorMessage = '';
  int _totalServerCount = 0; // Total real en Odoo

  int _currentPage = 0;
  final int _pageSize = 2500; // Cargar todos de una vez para evitar problemas de paginación
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeService();
  }

  void _initializeService() {
    final odooService = CompanyService().odooService;

    if (odooService == null || odooService.uid == null || odooService.uid == 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ Sesión no iniciada. Por favor inicia sesión primero en la app.';
      });
      return;
    }

    _inventoryService = OdooInventoryService(odooService);
    _fetchTotalCount();
    _loadQuants(refresh: true);
  }

  Future<void> _fetchTotalCount() async {
    if (_inventoryService == null) return;
    try {
      final result = await _inventoryService!.odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          _inventoryService!.odooService.dbName,
          _inventoryService!.odooService.uid,
          _inventoryService!.odooService.password,
          'stock.quant',
          'search_count',
          [[
            '&',
            ['location_id.usage', 'in', ['internal', 'transit']],
            '|',
            ['company_id', '=', false],
            ['company_id', '=', _inventoryService!.odooService.companyId],
          ]],
        ],
      });
      if (mounted) {
        setState(() => _totalServerCount = result as int);
      }
    } catch (e) {
      print('❌ Error obteniendo total: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessingScan || capture.barcodes.isEmpty) return;
    
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessingScan = true;
      _mostrarScanner = false;
      _searchController.text = code;
      _searchQuery = code;
    });

    await _loadQuants(refresh: true);

    setState(() {
      _isProcessingScan = false;
    });
  }

  Widget _buildScanner() {
    if (!_mostrarScanner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
         border: Border.all(color: Colors.teal, width: 2),
         borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleScan,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text('Error del scanner: $error', 
                    style: const TextStyle(color: Colors.red)),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(50),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() => _mostrarScanner = false);
                },
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                'Escaneando... Apunta al código de barras',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    // Paginación desactivada: cargamos todo de una vez
  }

  Future<void> _loadQuants({bool refresh = false}) async {
    if (_inventoryService == null) return;

    if (refresh) {
      setState(() {
        _currentPage = 0;
        _quants.clear();
        _hasMore = true;
        _isLoading = true;
        _errorMessage = '';
      });
    } else {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final fetched = await _inventoryService!.getPhysicalInventoryQuants(
        offset: _currentPage * _pageSize,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      setState(() {
        if (fetched.isEmpty) {
          _hasMore = false;
        } else {
          _quants.addAll(fetched);
          _currentPage++;
          if (fetched.length < _pageSize) _hasMore = false;
        }
        
        // Guardar copia completa para búsqueda local instantánea
        if (_searchQuery.isEmpty) {
          _allQuants = List.from(_quants);
        }
        
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Error al cargar inventario: $e';
      });
    }
  }

  void _onSearchTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _quants = List.from(_allQuants);
      });
      return;
    }

    final query = text.toLowerCase();
    final filtered = _allQuants.where((quant) {
      final productInfo = quant['product_id'];
      final productName = productInfo is List ? productInfo[1].toString().toLowerCase() : '';
      return productName.contains(query);
    }).toList();

    setState(() {
      _quants = filtered;
    });
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadQuants(refresh: true);
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> quant) async {
    final productInfo = quant['product_id'];
    final productName = productInfo is List ? productInfo[1] : 'Producto';
    final productId = productInfo is List ? productInfo[0] as int : 0;
    final quantId = quant['id'] as int;
    final currentStock = (quant['quantity'] ?? 0.0).toDouble();
    final currentCounted = (quant['inventory_quantity'] ?? currentStock).toDouble();

    // Obtener el código del producto si no está en el quant
    // (ya lo tenemos en el quant via product_id)
    final TextEditingController qtyController =
        TextEditingController(text: currentCounted.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                productName.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Cantidad a la mano: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$currentStock',
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Cantidades contadas',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      suffixIcon: const Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newQty = double.tryParse(qtyController.text);
                          if (newQty == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Ingresa un número válido.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          // Usamos el quantId directamente del quant
                          final success = await _inventoryService!
                              .updateStock(quantId, newQty);

                          setDialogState(() => isSaving = false);

                          if (success) {
                            if (mounted) {
                              Navigator.pop(context);
                              // Actualizar el valor localmente sin recargar todo
                              setState(() {
                                final idx = _quants.indexWhere((q) => q['id'] == quantId);
                                if (idx != -1) {
                                  _quants[idx] = {
                                    ..._quants[idx],
                                    'inventory_quantity': newQty,
                                  };
                                }
                                final allIdx = _allQuants.indexWhere((q) => q['id'] == quantId);
                                if (allIdx != -1) {
                                  _allQuants[allIdx] = {
                                    ..._allQuants[allIdx],
                                    'inventory_quantity': newQty,
                                  };
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Inventario actualizado en Odoo.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('❌ Error al actualizar en Odoo.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ajustes de Inventario',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: _mostrarScanner ? Colors.teal : null,
            ),
            tooltip: _mostrarScanner ? 'Cerrar escáner' : 'Escanear código',
            onPressed: () {
              setState(() {
                _mostrarScanner = !_mostrarScanner;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => _loadQuants(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + contador ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchTextChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: _onSearchTextChanged,
                  onSubmitted: _onSearch,
                ),
                if (!_isLoading && _errorMessage.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text(
                          '${_quants.length} de $_totalServerCount   Total $_totalServerCount',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Lector QR/Scanner ──
          _buildScanner(),

          // ── Lista ──────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Cargando inventario...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off,
                                  size: 64, color: Colors.orange),
                              const SizedBox(height: 16),
                              Text(_errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _initializeService,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _quants.isEmpty
                        ? const Center(
                            child: Text('No se encontraron productos.',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _quants.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _quants.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              final quant = _quants[index];
                              final productInfo = quant['product_id'];
                              final productName = productInfo is List
                                  ? productInfo[1].toString()
                                  : 'Sin nombre';
                              final qtyOnHand =
                                  (quant['quantity'] ?? 0.0).toDouble();
                              final qtyCounted =
                                  (quant['inventory_quantity'] ?? 0.0).toDouble();
                              final locationInfo = quant['location_id'];
                              final locationName = locationInfo is List
                                  ? locationInfo[1].toString()
                                  : '';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 1,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  title: Text(
                                    productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('A la mano: ',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            Text('$qtyOnHand',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 12),
                                            if (qtyCounted > 0)
                                              Text(
                                                'Contado: $qtyCounted',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.teal,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                        if (locationName.isNotEmpty)
                                          Text(locationName,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _showUpdateDialog(quant),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Establecer',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
