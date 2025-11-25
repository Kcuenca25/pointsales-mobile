import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:azlistview/azlistview.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_user.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
import 'package:ecomerce_app/src/data/api_repository/odooProveedorService.dart';

import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_compra.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden.dart';
import 'package:ecomerce_app/src/services/service_company.dart';

import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
class ProveedoresScreen extends StatefulWidget {
  final Function(Customer) onSupplierPageNavigate;

  const ProveedoresScreen({Key? key, required this.onSupplierPageNavigate})
      : super(key: key);

  @override
  _ProveedoresScreenState createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Customer> supplierList = [];
  List<Customer> filteredSuppliers = [];
  List<_AZSupplier> azSupplierList = [];
  List<_AZSupplier> filteredAzSuppliers = [];
  TextEditingController searchController = TextEditingController();
  int _selectedIndex = 1;
  bool _isLoading = true;

  // 🎯 CACHE PARA MEJORAR RENDIMIENTO
  static List<Customer>? _cachedSuppliers;
  static DateTime? _lastCacheTime;

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: index),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    // ✅ VERIFICAR CACHE PRIMERO (válido por 5 minutos)
    final now = DateTime.now();
    if (_cachedSuppliers != null && 
        _lastCacheTime != null && 
        now.difference(_lastCacheTime!).inMinutes < 5) {
      print('📦 Usando proveedores en caché: ${_cachedSuppliers!.length} empresas');
      _setSuppliersData(_cachedSuppliers!);
      return;
    }

    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        final customerService = OdooCustomerService(odooService);
        // ✅ FILTRAR SOLO EMPRESAS (isCompany = true)
        final allCustomers = await customerService.getCustomers(limit: 100);
        final companies = allCustomers.where((customer) => customer.isCompany).toList();
        
        // ✅ GUARDAR EN CACHE
        _cachedSuppliers = companies;
        _lastCacheTime = DateTime.now();
        
        _setSuppliersData(companies);
        
        print('✅ Proveedores cargados: ${companies.length} empresas');
      }
    } catch (e) {
      print('❌ Error loading suppliers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🎯 MÉTODO PARA ESTABLECER DATOS
  void _setSuppliersData(List<Customer> companies) {
    setState(() {
      supplierList = companies;
      filteredSuppliers = companies;
      
      azSupplierList = companies.map((supplier) {
        return _AZSupplier(supplier: supplier, name: supplier.name);
      }).toList();
      
      filteredAzSuppliers = List.from(azSupplierList);
      _isLoading = false;
    });
  }

  // 🎯 MÉTODO PARA FORZAR RECARGA
  Future<void> _refreshSuppliers() async {
    _cachedSuppliers = null; // Limpiar cache
    _lastCacheTime = null;
    
    setState(() {
      _isLoading = true;
    });
    
    await _loadSuppliers();
  }

  void filterSuppliers(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredAzSuppliers = List.from(azSupplierList);
      });
    } else {
      final filtered = azSupplierList.where((azSupplier) {
        return azSupplier.supplier.matchesQuery(query);
      }).toList();
      
      setState(() {
        filteredAzSuppliers = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshSuppliers,
            tooltip: 'Actualizar proveedores',
          ),
        ],
      ),
      drawer: AppDrawer(
        onItemTapped: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
          );
        },
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (supplierList.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildSuppliersList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando proveedores...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay proveedores disponibles',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refreshSuppliers,
            child: const Text('Cargar proveedores'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList() {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar proveedores...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: filterSuppliers,
          ),
        ),
        
        // Contador de resultados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filteredAzSuppliers.length} proveedores encontrados',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Lista de proveedores
        Expanded(
          child: filteredAzSuppliers.isEmpty
              ? const Center(
                  child: Text('No se encontraron proveedores'),
                )
              : AzListView(
                  data: filteredAzSuppliers,
                  itemCount: filteredAzSuppliers.length,
                  itemBuilder: (context, index) {
                    final item = filteredAzSuppliers[index];
                    final supplier = item.supplier;

                    return Dismissible(
                      key: ValueKey(supplier.id),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Crear orden de compra', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Información', style: TextStyle(color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.info_outline, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _navigateToCreatePurchaseOrder(supplier);
                        } else if (direction == DismissDirection.endToStart) {
                          _showSupplierOptions(supplier);
                        }
                        return false;
                      },
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.email != null && supplier.email!.isNotEmpty)
                              Text(supplier.email!),
                            if (supplier.phone != null && supplier.phone!.isNotEmpty)
                              Text(supplier.phone!),
                            if (supplier.vat != null && supplier.vat!.isNotEmpty)
                              Text(
                                'RUT: ${supplier.vat!}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(
                            Icons.business,
                            color: Colors.orange[800],
                            size: 20,
                          ),
                        ),
                        onTap: () {
                          _showSupplierOptions(supplier);
                        },
                      ),
                    );
                  },
                  susItemBuilder: (context, index) {
                    final tag = filteredAzSuppliers[index].getSuspensionTag();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: Colors.grey[200],
                      child: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  },
                  indexBarData: SuspensionUtil.getTagIndexList(filteredAzSuppliers),
                  indexBarOptions: const IndexBarOptions(
                    needRebuild: true,
                    selectTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    selectItemDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    indexHintAlignment: Alignment.centerRight,
                    indexHintDecoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // 🎯 MÉTODO PARA NAVEGAR A CREAR ORDEN DE COMPRA
  void _navigateToCreatePurchaseOrder(Customer supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearOrdenCompraScreen(
          proveedor: supplier,
          onOrdenCreada: (orden, proveedor, articulos) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Orden de compra creada para ${proveedor.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // 🎯 MÉTODO PARA MOSTRAR OPCIONES DEL PROVEEDOR
  void _showSupplierOptions(Customer supplier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.business,
                      color: Colors.orange[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      supplier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // BOTONES DE ACCIÓN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Crear Orden de Compra'),
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToCreatePurchaseOrder(supplier);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF583F80),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AZSupplier extends ISuspensionBean {
  final Customer supplier;
  final String name;

  _AZSupplier({required this.supplier, required this.name});

  @override
  String getSuspensionTag() {
    if (name.isEmpty) return "#";
    return name[0].toUpperCase();
  }
}