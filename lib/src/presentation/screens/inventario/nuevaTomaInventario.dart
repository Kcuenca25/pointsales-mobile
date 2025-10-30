import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/08-toma_de_inventario.dart';
import 'package:ecomerce_app/src/domain/models/inventario_models.dart';


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
  final List<Producto> _productosDisponibles = [];
  String _filtroCategoria = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarProductosDisponibles();
  }

  void _cargarProductosDisponibles() {
    // Simular carga de productos - reemplaza con tu data real
    setState(() {
      _productosDisponibles.addAll([
        Producto(
          id: 1,
          nombre: 'Laptop Dell XPS 13',
          sku: 'DL-XPS13-2024',
          categoria: 'Tecnología',
          precio: 1599.00,
          costo: 1200.00,
        ),
        Producto(
          id: 2,
          nombre: 'Mouse Inalámbrico Logitech',
          sku: 'LG-MX-MASTER3',
          categoria: 'Accesorios',
          precio: 129.99,
          costo: 89.99,
        ),
        Producto(
          id: 3,
          nombre: 'Monitor 27" 4K Samsung',
          sku: 'SS-MON27UHD',
          categoria: 'Tecnología',
          precio: 499.00,
          costo: 350.00,
        ),
        Producto(
          id: 4,
          nombre: 'Teclado Mecánico RGB',
          sku: 'RK-K61-RGB',
          categoria: 'Accesorios',
          precio: 89.99,
          costo: 65.00,
        ),
        Producto(
          id: 5,
          nombre: 'Dock Station USB-C',
          sku: 'CK-DOCK-PRO',
          categoria: 'Accesorios',
          precio: 179.00,
          costo: 120.00,
        ),
      ]);
    });
  }

  List<Producto> get _productosFiltrados {
    var productos = _productosDisponibles;
    
    // Filtrar por búsqueda
    if (_buscarProductoController.text.isNotEmpty) {
      productos = productos.where((producto) {
        return producto.nombre.toLowerCase().contains(_buscarProductoController.text.toLowerCase()) ||
               producto.sku.toLowerCase().contains(_buscarProductoController.text.toLowerCase());
      }).toList();
    }
    
    // Filtrar por categoría
    if (_filtroCategoria != 'Todas') {
      productos = productos.where((producto) => producto.categoria == _filtroCategoria).toList();
    }
    
    return productos;
  }

  List<String> get _categoriasDisponibles {
    final categorias = _productosDisponibles.map((p) => p.categoria).toSet().toList();
    categorias.insert(0, 'Todas');
    return categorias;
  }

  void _agregarProducto(Producto producto) {
    final yaExiste = _productosSeleccionados.any((p) => p.id == producto.id);
    
    if (!yaExiste) {
      setState(() {
        _productosSeleccionados.add(InventoryItem(
          id: producto.id,
          name: producto.nombre,
          sku: producto.sku,
          category: producto.categoria,
          currentStock: 0, // Inicia en 0
          physicalCount: 0, // Inicia en 0
          cost: producto.costo,
          price: producto.precio,
          status: InventoryStatus.matched, // Inicia como correcto
        ));
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${producto.nombre} agregado')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${producto.nombre} ya está en la lista')),
      );
    }
  }

  void _removerProducto(int productId) {
    setState(() {
      _productosSeleccionados.removeWhere((p) => p.id == productId);
    });
  }

  void _actualizarCantidad(int productId, int nuevaCantidad) {
    setState(() {
      final producto = _productosSeleccionados.firstWhere((p) => p.id == productId);
      producto.physicalCount = nuevaCantidad;
      producto.currentStock = nuevaCantidad; // En nueva toma, ambos son iguales
      producto.status = _calcularEstado(nuevaCantidad, nuevaCantidad);
    });
  }

  InventoryStatus _calcularEstado(int stockSistema, int stockFisico) {
    return InventoryStatus.matched; // En nueva toma, siempre coinciden
  }

  void _crearNuevaToma() {
    if (_clienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del cliente')),
      );
      return;
    }

    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto al inventario')),
      );
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

    // Navegar de vuelta con el resultado
    Navigator.pop(context, nuevaToma);
  }

  void _escaneoCodigoBarras() {
    // Integrar con tu scanner de código de barras
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escaneo de Código de Barras'),
        content: const Text('Esta funcionalidad se integrará con tu scanner de código de barras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        foregroundColor: const Color.fromARGB(255, 88, 63, 128),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _escaneoCodigoBarras,
            tooltip: 'Escanear código de barras',
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulario de información
          _buildFormularioInformacion(),
          
          // Búsqueda y filtros
          _buildBusquedaFiltros(),
          
          // Lista de productos seleccionados
          Expanded(
            child: _buildListaProductosSeleccionados(),
          ),
          
          // Acciones
          _buildAcciones(),
        ],
      ),
    );
  }

  Widget _buildFormularioInformacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _clienteController,
            decoration: const InputDecoration(
              labelText: 'Cliente *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ubicacionController,
            decoration: const InputDecoration(
              labelText: 'Ubicación/Almacén',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción/Observaciones',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBusquedaFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscarProductoController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (categoria) {
                  setState(() {
                    _filtroCategoria = categoria;
                  });
                },
                itemBuilder: (context) => _categoriasDisponibles.map((categoria) {
                  return PopupMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_filtroCategoria),
                      const SizedBox(width: 4),
                      const Icon(Icons.filter_list, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Lista de productos disponibles
          if (_productosFiltrados.isNotEmpty) ...[
            SizedBox(
              height: 120,
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
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No se encontraron productos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaProductoDisponible(Producto producto) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                producto.sku,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _agregarProducto(producto),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  Widget _buildListaProductosSeleccionados() {
    if (_productosSeleccionados.isEmpty) {
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
            const Text(
              'No hay productos en el inventario',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega productos usando la búsqueda superior',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _productosSeleccionados.length,
      itemBuilder: (context, index) {
        final producto = _productosSeleccionados[index];
        return _buildItemProductoSeleccionado(producto);
      },
    );
  }

  Widget _buildItemProductoSeleccionado(InventoryItem producto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                  Text(
                    producto.sku,
                    style: const TextStyle(
                      color: Colors.grey,
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
                ],
              ),
            ),
            
            // Controles de cantidad
            Column(
              children: [
                Container(
                  width: 100,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
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
                OutlinedButton(
                  onPressed: () => _removerProducto(producto.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Quitar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
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
              onPressed: _crearNuevaToma,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 88, 63, 128),
              ),
              child: const Text('Crear Inventario'),
            ),
          ),
        ],
      ),
    );
  }
}

// Modelo temporal para productos disponibles
class Producto {
  final int id;
  final String nombre;
  final String sku;
  final String categoria;
  final double precio;
  final double costo;

  Producto({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.categoria,
    required this.precio,
    required this.costo,
  });
}