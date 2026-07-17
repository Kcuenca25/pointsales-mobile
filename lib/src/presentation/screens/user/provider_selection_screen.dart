import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_user.dart';
import 'package:azlistview/azlistview.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:ecomerce_app/src/services/odoo_purchase_service.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';

class ProviderSelectionScreen extends StatefulWidget {
  final Function(Customer) onProviderSelected;

  const ProviderSelectionScreen({Key? key, required this.onProviderSelected})
      : super(key: key);

  @override
  _ProviderSelectionScreenState createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  List<Customer> providerList = [];
  List<_AZCustomer> azProviderList = [];
  List<_AZCustomer> filteredAzProviders = [];
  TextEditingController searchController = TextEditingController();
  int _selectedIndex = 3; // Purchase Orders index usually
  bool _isLoading = true;
  late OdooPurchaseService _purchaseService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadProviders();
  }

  void _initializeServices() {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    _purchaseService = OdooPurchaseService(odooService);
  }

  Future<void> _loadProviders() async {
    final tieneInternet = await ConnectivityService.hasInternet();
    
    if (tieneInternet) {
      await _loadProvidersFromOdoo();
    } else {
      // Offline fallback if needed, for now just show error or empty
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sin conexión a internet. No se pueden cargar proveedores.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProvidersFromOdoo() async {
    try {
      print('🔵 Cargando proveedores de Odoo...');
      
      // Ensure login
       await _purchaseService.odooService.login(
        ApiConfig.defaultUsername, 
        ApiConfig.defaultPassword
      );

      final rawSuppliers = await _purchaseService.getSuppliers();
      
      final suppliers = rawSuppliers.map((data) {
        return Customer(
          id: data['id'],
          name: data['name'] ?? 'Sin Nombre',
          email: data['email'] is String ? data['email'] : null,
          phone: data['phone'] is String ? data['phone'] : null,
          vat: data['vat'] is String ? data['vat'] : null,
          isCompany: true, // Suppliers are usually companies or treated as such
        );
      }).toList();

      setState(() {
        providerList = suppliers;
        azProviderList = suppliers.map((customer) {
          return _AZCustomer(customer: customer, name: customer.name);
        }).toList();
        
        filteredAzProviders = List.from(azProviderList);
        _isLoading = false;
      });
      
      print('✅ ${suppliers.length} proveedores cargados');

    } catch (e) {
      print('❌ Error cargando proveedores: $e');
      setState(() => _isLoading = false);
    }
  }

  void filterProviders(String query) {
    if (query.isEmpty) {  
      setState(() {
        filteredAzProviders = List.from(azProviderList);
      });
    } else {
      final filtered = azProviderList.where((azCustomer) {
        return azCustomer.customer.matchesQuery(query);
      }).toList();
      
      setState(() {
        filteredAzProviders = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        showTitle: false,
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
              'Seleccionar Proveedor',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            CustonSearch(
              controller: searchController,
              onTextChanged: filterProviders,
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: filteredAzProviders.isEmpty
                    ? const Center(child: Text('No hay proveedores disponibles.'))
                    : AzListView(
                        data: filteredAzProviders,
                        itemCount: filteredAzProviders.length,
                        itemBuilder: (context, index) {
                          final item = filteredAzProviders[index];
                          final provider = item.customer;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange[100],
                              child: Icon(Icons.business, color: Colors.orange[800], size: 18),
                            ),
                            title: Text(provider.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (provider.email != null && provider.email!.isNotEmpty)
                                  Text(provider.email!, style: TextStyle(fontSize: 12)),
                                if (provider.phone != null && provider.phone!.isNotEmpty)
                                  Text(provider.phone!, style: TextStyle(fontSize: 12)),
                                if (provider.vat != null && provider.vat!.isNotEmpty)
                                  Text('RUT: ${provider.vat!}', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                              ],
                            ),
                            onTap: () {
                               // Return selected provider
                               Navigator.pop(context, provider);
                            },
                          );
                        },
                        susItemBuilder: (context, index) {
                          final tag = filteredAzProviders[index].getSuspensionTag();
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
                            SuspensionUtil.getTagIndexList(filteredAzProviders),
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
    );
  }
}

class _AZCustomer extends ISuspensionBean {
  final Customer customer;
  final String name;

  _AZCustomer({required this.customer, required this.name});

  @override
  String getSuspensionTag() {
    if (name.isEmpty) return "#";
    return name[0].toUpperCase();
  }
}
