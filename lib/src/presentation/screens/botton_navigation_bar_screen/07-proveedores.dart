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

import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
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
        
        setState(() {
          supplierList = companies;
          filteredSuppliers = companies;
          
          azSupplierList = companies.map((supplier) {
            return _AZSupplier(supplier: supplier, name: supplier.name);
          }).toList();
          
          filteredAzSuppliers = List.from(azSupplierList);
          _isLoading = false;
        });
        
        print('✅ Proveedores cargados: ${companies.length} empresas');
      }
    } catch (e) {
      print('❌ Error loading suppliers: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      appBar: CustomAppBar(
        title: '',
        onOrdenTerminada: () {
          setState(() {});
        },
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
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Text(
              'Proveedores',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            CustonSearch(
              controller: searchController,
              onTextChanged: filterSuppliers,
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: filteredAzSuppliers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay proveedores disponibles',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
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
                                  Icon(Icons.shopping_bag_outlined,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Crear orden de compra',
                                      style: TextStyle(color: Colors.white)),
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
                                  Text('Información',
                                      style: TextStyle(color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.info_outline, color: Colors.white),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                widget.onSupplierPageNavigate(supplier);
                              } else if (direction == DismissDirection.endToStart) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupplierInfoPage(
                                      supplier: supplier, 
                                      onProductListNavigate: (_) {},
                                    ),
                                  ),
                                );
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
                                widget.onSupplierPageNavigate(supplier);
                              },
                            ),
                          );
                        },
                        susItemBuilder: (context, index) {
                          final tag = filteredAzSuppliers[index].getSuspensionTag();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            color: Colors.grey[200],
                            child: Text(tag,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          );
                        },
                        indexBarData:
                            SuspensionUtil.getTagIndexList(filteredAzSuppliers),
                        indexBarOptions: const IndexBarOptions(
                          needRebuild: true,
                          selectTextStyle: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
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
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
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

class SupplierInfoPage extends StatelessWidget {
  final Customer supplier;
  final Function(Customer) onProductListNavigate;

  const SupplierInfoPage({
    Key? key,
    required this.supplier,
    required this.onProductListNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información de ${supplier.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: Colors.orange[800]),
                        SizedBox(width: 10),
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (supplier.email != null && supplier.email!.isNotEmpty)
                      _buildInfoRow('Email', supplier.email!),
                    if (supplier.phone != null && supplier.phone!.isNotEmpty)
                      _buildInfoRow('Teléfono', supplier.phone!),
                    if (supplier.mobile != null && supplier.mobile!.isNotEmpty)
                      _buildInfoRow('Móvil', supplier.mobile!),
                    if (supplier.vat != null && supplier.vat!.isNotEmpty)
                      _buildInfoRow('RUT/VAT', supplier.vat!),
                    _buildInfoRow('Tipo', 'Empresa'),
                  ],
                ),
              ),
            ),
            
            if (supplier.street != null || supplier.city != null || supplier.zip != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dirección',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (supplier.street != null && supplier.street!.isNotEmpty)
                        Text('Dirección: ${supplier.street}'),
                      if (supplier.city != null && supplier.city!.isNotEmpty)
                        Text('Ciudad: ${supplier.city}'),
                      if (supplier.zip != null && supplier.zip!.isNotEmpty)
                        Text('Código Postal: ${supplier.zip}'),
                    ],
                  ),
                ),
              ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onProductListNavigate(supplier);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Crear Orden de Compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}