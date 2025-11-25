import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/08-toma_de_inventario.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';

import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/08-toma_de_inventario.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';

class NuevaTomaInventarioScreen extends StatefulWidget {
  final String usuarioActual;

  const NuevaTomaInventarioScreen({
    super.key,
    required this.usuarioActual,
  });

  @override
  State<NuevaTomaInventarioScreen> createState() => _NuevaTomaInventarioScreenState();
}

class _NuevaTomaInventarioScreenState extends State<NuevaTomaInventarioScreen> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _buscarProductoController = TextEditingController();
  
  final List<InventoryItem> _productosSeleccionados = [];
  final List<Product> _productosDisponibles = [];
  String _filtroCategoria = 'Todas';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarProductosReales();
  }

  // ✅ CARGAR PRODUCTOS REALES DESDE ODDO
  Future<void> _cargarProductosReales() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔄 Cargando productos reales desde Odoo...');

      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://solutions.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      final isAuthenticated = await odooService.login('admin', 'admin');
      
      if (!isAuthenticated) {
        throw Exception('Error de autenticación con Odoo');
      }

      final productService = OdooProductService(odooService);
      final products = await productService.getProducts(limit: 100);
      
      if (products.isEmpty) {
        throw Exception('No se encontraron productos en Odoo');
      }

      setState(() {
        _productosDisponibles.clear();
        _productosDisponibles.addAll(products.where((p) => p.isSellable));
        _isLoading = false;
      });

      print('✅ ${_productosDisponibles.length} productos reales cargados');

    } catch (e) {
      print('❌ Error cargando productos reales: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  List<Product> get _productosFiltrados {
    var productos = _productosDisponibles;
    
    // Filtrar por búsqueda
    if (_buscarProductoController.text.isNotEmpty) {
      productos = productos.where((producto) {
        return producto.name.toLowerCase().contains(_buscarProductoController.text.toLowerCase()) ||
               (producto.defaultCode?.toLowerCase().contains(_buscarProductoController.text.toLowerCase()) ?? false) ||
               (producto.barcode?.toLowerCase().contains(_buscarProductoController.text.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Filtrar por categoría
    if (_filtroCategoria != 'Todas') {
      productos = productos.where((producto) => 
          (producto.categoryName ?? 'Sin categoría') == _filtroCategoria).toList();
    }
    
    return productos;
  }

  List<String> get _categoriasDisponibles {
    final categorias = _productosDisponibles
        .map((p) => p.categoryName ?? 'Sin categoría')
        .toSet()
        .toList();
    categorias.sort();
    return ['Todas', ...categorias];
  }

  void _agregarProducto(Product product) {
    final yaExiste = _productosSeleccionados.any((p) => p.id == product.id);
    
    if (!yaExiste) {
      setState(() {
        _productosSeleccionados.add(InventoryItem.fromProduct(
          product, 
          0 // Inicia en 0 para nueva toma
        ));
      });
      
      _mostrarNotificacionExito('${product.name} agregado al inventario');
    } else {
      _mostrarNotificacionInfo('${product.name} ya está en la lista');
    }
  }

  void _removerProducto(int productId) {
    setState(() {
      _productosSeleccionados.removeWhere((p) => p.id == productId);
    });
    _mostrarNotificacionInfo('Producto removido');
  }

  void _actualizarCantidad(int productId, int nuevaCantidad) {
    setState(() {
      final producto = _productosSeleccionados.firstWhere((p) => p.id == productId);
      producto.physicalCount = nuevaCantidad;
      producto.currentStock = nuevaCantidad;
      producto.status = InventoryStatus.matched;
    });
  }

  void _mostrarNotificacionExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _crearNuevaToma() {
    if (_clienteController.text.isEmpty) {
      _mostrarNotificacionError('Por favor ingresa el nombre del cliente');
      return;
    }

    if (_productosSeleccionados.isEmpty) {
      _mostrarNotificacionError('Agrega al menos un producto al inventario');
      return;
    }

    final nuevaToma = NuevaTomaInventario(
      id: DateTime.now().millisecondsSinceEpoch,
      fechaCreacion: DateTime.now(),
      creadoPor: widget.usuarioActual,
      cliente: _clienteController.text,
      ubicacion: _ubicacionController.text,
      descripcion: _descripcionController.text,
      items: _productosSeleccionados,
    );

    Navigator.pop(context, nuevaToma);
  }

  void _mostrarNotificacionError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _escaneoCodigoBarras() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.blue),
            SizedBox(width: 8),
            Text('Escaneo de Código de Barras'),
          ],
        ),
        content: const Text('Esta funcionalidad se integrará con tu scanner de código de barras para agregar productos rápidamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Toma de Inventario'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF583F80),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _escaneoCodigoBarras,
            tooltip: 'Escanear código de barras',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductosReales,
            tooltip: 'Actualizar productos',
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : Column(
              children: [
                // Formulario de información - MEJORADO
                _buildFormularioInformacion(),
                
                // Búsqueda y filtros - MEJORADO
                _buildBusquedaFiltros(),
                
                // Lista de productos seleccionados
                Expanded(
                  child: _buildListaProductosSeleccionados(),
                ),
                
                // Acciones - MEJORADO
                _buildAcciones(),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF583F80)),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando productos desde Odoo...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioInformacion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Header informativo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Toma de Inventario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Usuario: ${widget.usuarioActual}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Campos del formulario
          _buildCampoFormulario(
            controller: _clienteController,
            label: 'Cliente *',
            icon: Icons.business,
            esRequerido: true,
          ),
          const SizedBox(height: 12),
          _buildCampoFormulario(
            controller: _ubicacionController,
            label: 'Ubicación/Almacén',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildCampoFormulario(
            controller: _descripcionController,
            label: 'Descripción/Observaciones',
            icon: Icons.description,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCampoFormulario({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool esRequerido = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF583F80)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF583F80), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildBusquedaFiltros() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _buscarProductoController,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos por nombre, código...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF583F80)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filtro de categoría
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  onSelected: (categoria) {
                    setState(() {
                      _filtroCategoria = categoria;
                    });
                  },
                  itemBuilder: (context) => _categoriasDisponibles.map((categoria) {
                    return PopupMenuItem(
                      value: categoria,
                      child: Row(
                        children: [
                          Icon(
                            categoria == 'Todas' ? Icons.all_inclusive : Icons.category,
                            color: const Color(0xFF583F80),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(categoria),
                        ],
                      ),
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
                        const Icon(Icons.filter_list, color: Color(0xFF583F80), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _filtroCategoria,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contador de resultados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos disponibles: ${_productosFiltrados.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Seleccionados: ${_productosSeleccionados.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF583F80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Lista de productos disponibles - MEJORADA
          if (_productosFiltrados.isNotEmpty) ...[
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final producto = _productosFiltrados[index];
                  return _buildTarjetaProductoDisponible(producto);
                },
              ),
            ),
          ] else if (_buscarProductoController.text.isNotEmpty) ...[
            _buildEstadoSinResultados(),
          ] else if (_productosDisponibles.isEmpty) ...[
            _buildEstadoSinProductos(),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaProductoDisponible(Product product) {
    final yaAgregado = _productosSeleccionados.any((p) => p.id == product.id);
    
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: yaAgregado 
                  ? [Colors.green[50]!, Colors.green[100]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del tipo de producto
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: product.typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProductIcon(product.type),
                    color: product.typeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Nombre del producto
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // SKU
                if (product.defaultCode != null && product.defaultCode!.isNotEmpty)
                  Text(
                    product.defaultCode!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                
                const Spacer(),
                
                // Precio y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.listPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: yaAgregado ? Colors.green : const Color(0xFF583F80),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          yaAgregado ? Icons.check : Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () => _agregarProducto(product),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoSinResultados() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.orange[400]),
          const SizedBox(height: 8),
          const Text(
            'No se encontraron productos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Para "${_buscarProductoController.text}"',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoSinProductos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          const Text(
            'No hay productos disponibles',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Conecta con Odoo para cargar productos',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductosSeleccionados() {
    if (_productosSeleccionados.isEmpty) {
      return _buildEstadoInventarioVacio();
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _productosSeleccionados.length,
        itemBuilder: (context, index) {
          final producto = _productosSeleccionados[index];
          return _buildItemProductoSeleccionado(producto);
        },
      ),
    );
  }

  Widget _buildEstadoInventarioVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Inventario Vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos usando la búsqueda superior',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Scroll to search section
            },
            icon: const Icon(Icons.search),
            label: const Text('Buscar Productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF583F80),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemProductoSeleccionado(InventoryItem producto) {
    final product = producto.product; // Producto original
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono del producto
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (product?.typeColor ?? Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getProductIcon(product?.type ?? 'consu'),
                  color: product?.typeColor ?? Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (producto.sku != 'N/A' && producto.sku.isNotEmpty)
                      Text(
                        'SKU: ${producto.sku}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      producto.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (product != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.typeDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            color: product.typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Controles de cantidad - MEJORADOS
              Column(
                children: [
                  // Contador
                  Container(
                    width: 120,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: () {
                            if (producto.physicalCount > 0) {
                              _actualizarCantidad(producto.id, producto.physicalCount - 1);
                            }
                          },
                        ),
                        Expanded(
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: '0',
                            ),
                            controller: TextEditingController(text: producto.physicalCount.toString()),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final nuevaCantidad = int.tryParse(value) ?? 0;
                              _actualizarCantidad(producto.id, nuevaCantidad);
                            },
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            _actualizarCantidad(producto.id, producto.physicalCount + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Botón quitar
                  OutlinedButton.icon(
                    onPressed: () => _removerProducto(producto.id),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Quitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
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

  Widget _buildAcciones() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Botón crear inventario
          Expanded(
            child: ElevatedButton(
              onPressed: _crearNuevaToma,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF583F80),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Crear Inventario',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type) {
      case 'consu':
        return Icons.shopping_bag;
      case 'service':
        return Icons.design_services;
      case 'product':
        return Icons.inventory;
      default:
        return Icons.shopping_bag;
    }
  }
}