import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart'; 
//import 'package:ecomerce_app/src/presentation/components/custon_select/articulo_select.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_select/articulo_select_grid.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_select/articuloSelectSimple.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/screens/user/articuloSelectorCompleto.dart';
import 'package:flutter/animation.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odooOrderService.dart';

import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'dart:math';

//import 'package:ecomerce_app/src/domain/models/articulo.dart'; 

class NuevaOrdenPage extends StatefulWidget {
  final Customer customer; 
  final User? usuario;
  final Function(Order, Customer, List<ArticuloItem>) onOrdenCreada;
  final bool clienteFijo; 

  const NuevaOrdenPage({
    super.key,
    required this.customer,
    this.usuario,
    this.clienteFijo = false,
    required this.onOrdenCreada,
  });

  @override
  State<NuevaOrdenPage> createState() => _NuevaOrdenPageState();
}

class _NuevaOrdenPageState extends State<NuevaOrdenPage>   with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.upcA],
    facing: CameraFacing.back,
  );

  List<Product> _productosDisponibles = []; 

  String _estadoSeleccionado = "Pendiente";
  int _selectedIndex = 2;
  User? _selectedUser;
  Customer? _selectedCustomer; 
  bool _clienteBloqueado = false;
  bool _isProcessingScan = false;
  bool _mostrarScanner = false;
  
  //variables de animacion 
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  List<ArticuloItem> _articulos = [];

  @override
  void initState() {
    super.initState();

    _clienteBloqueado = true; 
    _selectedCustomer = widget.customer;
    _cargarProductos();

    _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8), // Más lento
  );
  
    _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.0), // Posición inicial normal
    end: const Offset(-0.3, 0.0),  // Se mueve solo un poco a la izquierda
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  ));
  

      // LIMPIAR BORRADOR SI VIENE DESDE ORDEN DE COMPRA (sin usuario)
    if (widget.usuario == null) {
      _limpiarDraft();
    }

    if (widget.usuario != null) {
      // Si viene desde Cliente
      _selectedUser = widget.usuario;
      _clienteBloqueado = true;
    } else if (OrderDraftState.hasDraft && OrderDraftState.draftUser != null) {
      // Si hay borrador y viene desde Orden de compra
      _selectedUser = OrderDraftState.draftUser;
      _clienteBloqueado = _selectedUser != null;
      _articulos = List<ArticuloItem>.from(OrderDraftState.draftArticulos);
      _actualizarTotal();
    }
  }
  ArticuloItem? _buscarProductoPorCodigoQR(String codigoQR) {
  print('🔍 Buscando producto con código: $codigoQR');
  
  // Buscar en la lista de productos disponibles de Odoo por default_code
  final product = _productosDisponibles.firstWhere(
    (p) => p.defaultCode == codigoQR,
    orElse: () => Product(
      id: -1,
      name: '',
      defaultCode: '',
      listPrice: 0.0,
      type: 'consu',
    ),
  );

  // Si no se encontró el producto
  if (product.id == -1) {
    print('❌ Producto no encontrado para código: $codigoQR');
    return null;
  }

  print('✅ Producto encontrado: ${product.name} (ID: ${product.id})');
  
  // Convertir el Product de Odoo a ArticuloItem
  return ArticuloItem(
    id: product.id,
    nombre: product.name,
    categoria: product.categoryName ?? 'Sin categoría',
    subcategoria: product.typeDisplay,
    precio: product.listPrice,
    descripcion: product.description ?? product.name,
    cantidad: 1,
    imagen: 'default_product',
    rating: 4.0,
    reviews: 0,
  );
}

// ✅ Método mejorado para manejar el escaneo
void _handleScan(BarcodeCapture capture) async {
  if (_isProcessingScan || capture.barcodes.isEmpty) {
    print('⚠️ No se detectaron códigos en el escaneo');
    return;
  }
  
  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) {
    print('⚠️ Código QR vacío o sin datos');
    
    // Opcional: Mostrar feedback al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Código QR vacío - intente con otro código"),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  _isProcessingScan = true;
  
  print('📱 Código escaneado: $code');
  
  // ✅ Buscar el producto por código QR en productos de Odoo
  ArticuloItem? productoEscaneado = _buscarProductoPorCodigoQR(code);
  
  if (productoEscaneado != null) {
    // ✅ Producto encontrado - abrir pantalla de detalle
    print('🎯 Abriendo detalle del producto: ${productoEscaneado.nombre}');
    _mostrarDetalleProductoEscaneado(productoEscaneado);
  } else {
    // ✅ Producto no encontrado - mostrar error y opción para agregar genérico
    print('⚠️ Producto no encontrado, mostrando diálogo de opciones');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Producto no encontrado"),
        content: Text("No se encontró un producto con el código: $code"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),


        ],
      ),
    );

    if (result == true) {
      // Agregar producto genérico
      final nuevo = ArticuloItem(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: "Producto Escaneado",
        categoria: "Genérico",
        cantidad: 1,
        precio: 0.0, // Precio 0 para que el usuario lo ajuste después
        descripcion: "Código: $code",
      );

      setState(() {
        _articulos.add(nuevo);
        _actualizarTotal();
        _guardarDraft();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Producto genérico agregado - ajuste el precio"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  setState(() {
    _mostrarScanner = false;
  });
  _isProcessingScan = false;
}
// ✅ Método auxiliar para mostrar mensajes de error
void _mostrarMensajeError(String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ),
  );
}

// ✅ Método mejorado para mostrar detalle del producto escaneado
void _mostrarDetalleProductoEscaneado(ArticuloItem producto) {
  final cantidadExistente = _articulos
      .where((a) => a.id == producto.id)
      .fold(0, (sum, a) => sum + a.cantidad);

  // ✅ BUSCAR EL PRODUCTO CORRESPONDIENTE EN LA LISTA DE ODDO
  final product = _productosDisponibles.firstWhere(
    (p) => p.id == producto.id,
    orElse: () => Product(
      id: producto.id,
      name: producto.nombre,
      defaultCode: '',
      listPrice: producto.precio,
      type: producto.subcategoria == 'Servicio' ? 'service' : 'consu',
      categoryName: producto.categoria,
    ),
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailScreen(
        articulo: producto,
        product: product,
        cantidadInicial: cantidadExistente,
        onAgregarArticulo: (articulo, cantidad) {
          _agregarArticulo(articulo, cantidad);
        },
      ),
    ),
  );
}

Future<void> _cargarProductos() async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: 'https://pointsalesqa.tailorw.net',
      dbName: 'pointsales_prodv18',
    );
    
    bool isAuthenticated = await odooService.login('admin', 'admin');
    
    if (isAuthenticated) {
      final productService = OdooProductService(odooService);
      final products = await productService.getProducts(limit: 200); // Aumenta el límite
      
      setState(() {
        _productosDisponibles = products;
      });
      
      print('✅ Productos cargados en NuevaOrdenPage: ${products.length}');
      
      // Debug: mostrar algunos productos para verificar
      for (var i = 0; i < min(5, products.length); i++) {
        print('   📦 ${products[i].name} - Código: ${products[i].defaultCode}');
      }
    }
  } catch (e) {
    print('❌ Error cargando productos: $e');
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _totalController.dispose();
    _scannerController.dispose();
    super.dispose();
  }


 Widget _buildAnimatedTitle(String titulo, String subtitulo) {
  final bool isLongTitle = titulo.length > 25;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Para títulos largos, no usar animación para mejor legibilidad
      if (isLongTitle)
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
      else
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Stack(
            children: [
              SlideTransition(
                position: _offsetAnimation,
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      
      // Subtítulo con el email
      if (subtitulo.isNotEmpty)
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
    ],
  );
}

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filtros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(
                        title: 'Estado',
                        children: [
                          _buildFilterCheckbox("Todas", _estadoSeleccionado == "Todas",
                              (value) => setState(() => _estadoSeleccionado = "Todas")),
                          _buildFilterCheckbox("Pendiente", _estadoSeleccionado == "Pendiente",
                              (value) => setState(() => _estadoSeleccionado = "Pendiente")),
                          _buildFilterCheckbox("Pagada", _estadoSeleccionado == "Pagada",
                              (value) => setState(() => _estadoSeleccionado = "Pagada")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aplicar"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  Widget _buildFilterSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  void _agregarArticulo(ArticuloItem articulo, int cantidad) {
  setState(() {
    final existingIndex = _articulos.indexWhere((a) => a.id == articulo.id);
    if (existingIndex >= 0) {
      // Si ya existe, actualiza la cantidad pero NO cambia la posición
      _articulos[existingIndex].cantidad += cantidad;
    } else {
      // Agrega el nuevo artículo al INICIO de la lista
      _articulos.insert(0, ArticuloItem(
        id: articulo.id,
        nombre: articulo.nombre,
        categoria: articulo.categoria,
        subcategoria: articulo.subcategoria,
        cantidad: cantidad,
        precio: articulo.precio,
        descripcion: articulo.descripcion,
      ));
    }
    _actualizarTotal();
    _guardarDraft();
  });
}

  void _eliminarArticulo(int index) {
    setState(() {
      _articulos.removeAt(index);
      _actualizarTotal();
      _guardarDraft();
    });
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
  setState(() {
    if (nuevaCantidad < 1) {
      // Si la cantidad sería 0 o menos, eliminar el artículo
      _eliminarArticulo(index);
    } else {
      _articulos[index].cantidad = nuevaCantidad;
      _actualizarTotal();
      _guardarDraft();
    }
  });
}

  void _actualizarTotal() {
    double total = 0;
    for (var a in _articulos) total += a.precio * a.cantidad;
    _totalController.text = total.toStringAsFixed(2);
  }

  void _guardarDraft() {
    if (_selectedUser != null || _articulos.isNotEmpty) {
      OrderDraftState.hasDraft = true;
      OrderDraftState.draftUser = _selectedUser;
      OrderDraftState.draftArticulos = List<ArticuloItem>.from(_articulos);
    }
  }

  void _limpiarDraft() {
    OrderDraftState.hasDraft = false;
    OrderDraftState.draftUser = null;
    OrderDraftState.draftArticulos = [];
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(initialIndex: index)),
      );
    }
  }

  void _mostrarSelectorArticulosCompleto() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ArticuloSelectorScreen(
        onArticuloAgregado: (articulo, cantidad) {
          _agregarArticulo(articulo, cantidad);
        },
        onArticuloEliminado: (articulo) {
          // ✅ Eliminar el artículo de la lista
          setState(() {
            _articulos.removeWhere((a) => a.id == articulo.id);
            _actualizarTotal();
            _guardarDraft();
          });
        },
        articulosSeleccionadosIniciales: _articulos,
      ),
    ),
  );
}


  Widget _buildCantidadSelector(int index) {
  final articulo = _articulos[index];
  final bool mostrarEliminar = articulo.cantidad == 1;
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Botón para disminuir cantidad o eliminar
      GestureDetector(
        onTap: () => _actualizarCantidad(index, articulo.cantidad - 1),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300], 
            shape: BoxShape.circle
          ),
          child: Icon(
            mostrarEliminar ? Icons.delete : Icons.remove,
            size: 18,
            color: mostrarEliminar ? Colors.red : Colors.black,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey), 
          borderRadius: BorderRadius.circular(4)
        ),
        child: Text(
          articulo.cantidad.toString(), 
          style: const TextStyle(fontSize: 16)
        ),
      ),
      GestureDetector(
        onTap: () => _actualizarCantidad(index, articulo.cantidad + 1),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300], 
            shape: BoxShape.circle
          ),
          child: const Icon(Icons.add, size: 18),
        ),
      ),
    ],
  );
}  Widget _buildArticuloItem(int index) {
  final articulo = _articulos[index];
  
  // Widget para el contenido del artículo
  Widget contenidoArticulo = Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200], 
              borderRadius: BorderRadius.circular(8)
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articulo.nombre, 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                Text(
                  articulo.categoria, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                ),
                Text(
                  "\$${articulo.precio.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.green
                  ),
                ),
              ],
            ),
          ),
          _buildCantidadSelector(index),
        ],
      ),
    ),
  );

  return Dismissible(
    key: Key(articulo.id.toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white, size: 30),
    ),
    confirmDismiss: (direction) async {
      return await _mostrarConfirmacionEliminar(context);
    },
    onDismissed: (direction) {
      _eliminarArticulo(index);
    },
    child: contenidoArticulo,
  );
}


Future<bool> _mostrarConfirmacionEliminar(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Eliminar artículo"),
        content: const Text("¿Estás seguro de que quieres eliminar este artículo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  ) ?? false;
}


  Widget _buildBottomStaticSection() {
    int totalArticulos = _articulos.fold(0, (sum, articulo) => sum + articulo.cantidad);
    double totalPagar = _articulos.fold(0, (sum, articulo) => sum + (articulo.precio * articulo.cantidad));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Fila compacta de totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total de artículos
              Row(
                children: [
                  const Icon(Icons.shopping_basket, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$totalArticulos artículos',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              
              // Total a pagar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total a pagar:',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    '\$${totalPagar.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          
           SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () async {
  if (_articulos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Agregue al menos un artículo")));
    return;
  }
  
  // ✅ MOSTRAR LOADING
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // ✅ 1. PREPARAR DATOS PARA ODDO
    final orderLines = _articulos.map((articulo) {
      return {
        'product_id': articulo.id,
        'quantity': articulo.cantidad,
        'price_unit': articulo.precio,
      };
    }).toList();

    // ✅ 2. CREAR ORDEN EN ODDO CON FLUJO AUTOMÁTICO
    final odooService = OdooServiceEnhanced(
      baseUrl: 'https://pointsalesqa.tailorw.net',
      dbName: 'pointsales_prodv18',
    );
    
    await odooService.login('admin', 'admin');
    final orderService = OdooOrderService(odooService);
    
    final result = await orderService.createSaleOrder(
      partnerId: _selectedCustomer!.id!,
      orderLines: orderLines,
    );

    // ✅ 3. CERRAR LOADING
    Navigator.pop(context);

    if (result['success'] == true) {
      print('🎉 Orden creada exitosamente en Odoo - ID: ${result['order_id']}');
      
      // ✅ 4. CREAR ORDEN LOCAL PARA LA APP
      final nuevaOrden = Order(
        id: result['order_id'].toString(),
        date: DateTime.now(),
        total: totalPagar,
        status: 'draft', // Estado inicial de Odoo
      );

      // ✅ 5. NOTIFICAR Y CERRAR
      widget.onOrdenCreada(nuevaOrden, _selectedCustomer!, _articulos);
      _limpiarDraft();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Orden creada - Flujo automático iniciado"),
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${result['error']}"),
          backgroundColor: Colors.red,
        ),
      );
    }
    
  } catch (e) {
    Navigator.pop(context); // Cerrar loading
    print('❌ Error creando orden: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
},

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Guardar Orden',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
       String titulo = "Nueva orden de ${_selectedCustomer?.name ?? 'Cliente'}";
    String subtitulo = _selectedCustomer?.email ?? "";


     return WillPopScope(
      onWillPop: () async {
        _guardarDraft();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Orden guardada como borrador"), duration: Duration(seconds: 2)),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildAnimatedTitle(titulo, subtitulo),
                ),
              ),
            ],
          ),
          toolbarHeight: 100,
          actions: [
            if (widget.usuario == null && _selectedUser != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: _desbloquearCliente,
                  tooltip: 'Cambiar cliente',
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _abrirFiltros,
              ),
            ),
          ],
        ),
        drawer: AppDrawer(onItemTapped: _onItemTapped),
        body: Column(
          children: [
            // Sección superior FIJA (botones y título)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  
                      
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text("Seleccionar Artículos"),
                            onPressed: _mostrarSelectorArticulosCompleto,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.document_scanner),
                          onPressed: () => setState(() => _mostrarScanner = !_mostrarScanner),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                   if (_mostrarScanner)
  Container(
    margin: const EdgeInsets.symmetric(vertical: 10), // Menos margen vertical
    height: MediaQuery.of(context).size.height * 0.35, // 35% de la altura de la pantalla
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: MobileScanner(controller: _scannerController, onDetect: _handleScan),
  ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            
            // Sección media con SCROLL (solo productos)
            Expanded(
              child: _articulos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No hay artículos seleccionados", 
                        style: TextStyle(color: Colors.grey, fontSize: 16)
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: List.generate(_articulos.length, _buildArticuloItem),
                  ),
            ),
            
            // Sección inferior FIJA (totales y botón)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _buildBottomStaticSection(),
            ),
          ],
        ),
        
        bottomNavigationBar: CustomCircleNavBar(
          selectedIndex: _selectedIndex, 
          onItemTapped: _onItemTapped
        ),
      ),
    );
  }

  // Método para desbloquear cliente (descomenta este método)
  void _desbloquearCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar cliente'),
        content: const Text('¿Estás seguro de que quieres cambiar de cliente? Se perderán los artículos seleccionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedUser = null;
                _clienteBloqueado = false;
                _articulos.clear();
                _actualizarTotal();
              });
              _limpiarDraft();
              Navigator.pop(context);
            },
            child: const Text('Cambiar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}