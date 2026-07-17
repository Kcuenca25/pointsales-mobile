import 'package:flutter/material.dart';
//import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_user.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/cliente_data_page.dart';
import 'package:azlistview/azlistview.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';

import 'package:ecomerce_app/src/services/cache_service.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';


class ClientScreen extends StatefulWidget {
  final Function(Customer) onCustomerPageNavigate;

  const ClientScreen({Key? key, required this.onCustomerPageNavigate})
      : super(key: key);

  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  List<Customer> customerList = [];
  List<Customer> filteredCustomers = [];
  List<_AZCustomer> azCustomerList = []; // ✅ Cambiar a _AZCustomer
  List<_AZCustomer> filteredAzCustomers = []; // ✅ Cambiar a _AZCustomer
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
    _loadCustomers();
  }

 Future<void> _loadCustomers() async {
  // 1️⃣ ESTRATEGIA: Stale-While-Revalidate
  // Primero cargamos lo que hay en caché instantáneamente para que el usuario no espere.
  await _loadCustomersFromCache(silent: true);

  // 2️⃣ Luego verificamos internet y actualizamos 'en segundo plano'
  final tieneInternet = await ConnectivityService.hasInternet();
  
  if (tieneInternet) {
    // ✅ CON INTERNET: Cargar de Odoo + actualizar caché
    await _loadCustomersFromOdoo();
  } else {
    // 🔴 SIN INTERNET: Notificar al usuario que está viendo datos offline
    // Como ya cargamos los datos en el paso 1 (silent=true), solo mostramos el aviso si hay datos.
    if (customerList.isNotEmpty && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Modo Offline: Visualizando ${customerList.length} clientes'),
                ),
              ],
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

Future<void> _loadCustomersFromOdoo() async {
  try {
    print('🔵 Modo Online - Cargando clientes...');
    
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    
    // ✅ USAR CREDENCIALES DEL CONFIG
    bool isAuthenticated = await odooService.login(
      ApiConfig.defaultUsername, 
      ApiConfig.defaultPassword
    );
    
    if (isAuthenticated) {
      final customerService = OdooCustomerService(odooService);
      final allCustomers = await customerService.getCustomers(limit: 10000);
      
      // ✅ GUARDAR EN CACHÉ
      await CacheService.saveCustomers(allCustomers);
      
      setState(() {
        customerList = allCustomers;
        filteredCustomers = allCustomers;
        
        azCustomerList = allCustomers.map((customer) {
          return _AZCustomer(customer: customer, name: customer.name);
        }).toList();
        
        _prepareAzData(azCustomerList);
        filteredAzCustomers = List.from(azCustomerList);
        _isLoading = false;
      });
      
      print('✅ ${allCustomers.length} clientes cargados desde Odoo y guardados en caché');
      
      // Estadísticas
      final individuals = allCustomers.where((c) => !c.isCompany).length;
      final companies = allCustomers.where((c) => c.isCompany).length;
      print('   👥 Personas: $individuals');
      print('   🏢 Empresas: $companies');
    }
  } catch (e) {
    print('❌ Error cargando clientes de Odoo: $e');
    // Fallback: intentar cargar del caché
    await _loadCustomersFromCache(silent: false);
  }
}


Future<void> _loadCustomersFromCache({bool silent = false}) async {
  print('🔴 [DEBUG] _loadCustomersFromCache INICIADO (Silent: $silent)');
  
  try {
    print('${_getTimestamp()} 🔴 Modo Offline - Cargando clientes del caché...');
    
    final clientesCache = await CacheService.getCachedCustomers();
    
    print('🔴 [DEBUG] Clientes del caché: ${clientesCache.length}');
    
    if (clientesCache.isNotEmpty) {
      // ✅ SNACKBAR VISUAL
      print('🔴 [DEBUG] Intentando mostrar SnackBar...');
      if (mounted && !silent) { // ✅ Solo mostrar SnackBar si no es 'silent'
        print('🔴 [DEBUG] Widget está mounted, mostrando SnackBar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text('📦 ${clientesCache.length} clientes cargados del caché'),
                ),
              ],
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
        print('🔴 [DEBUG] SnackBar mostrado exitosamente');
      } else {
        print('🔴 [DEBUG] Widget NO está mounted o es silent mode');
      }
      
      // ✅ ACTUALIZAR TODAS LAS LISTAS
      setState(() {
        customerList = clientesCache;
        filteredCustomers = clientesCache;
        
        // ✅ ACTUALIZAR LAS LISTAS AZ QUE SE USAN EN LA UI
        azCustomerList = clientesCache.map((customer) {
          return _AZCustomer(customer: customer, name: customer.name);
        }).toList();
        
        _prepareAzData(azCustomerList);
        filteredAzCustomers = List.from(azCustomerList);
        _isLoading = false;
      });
      
      print('🔴 [DEBUG] Listas actualizadas:');
      print('   customerList: ${customerList.length}');
      print('   filteredCustomers: ${filteredCustomers.length}');
      print('   azCustomerList: ${azCustomerList.length}');
      print('   filteredAzCustomers: ${filteredAzCustomers.length}');
      
      print('${_getTimestamp()} ✅ ${clientesCache.length} clientes cargados del caché');
    } else {
      print('🔴 [DEBUG] No hay clientes en caché');
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print('❌ Error cargando clientes del caché: $e');
    setState(() {
      _isLoading = false;
    });
  }
  
  print('🔴 [DEBUG] _loadCustomersFromCache FINALIZADO');
}


String _getTimestamp() {
  return '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]';
}
  void filterCustomers(String query) {
    if (query.isEmpty) {  
      setState(() {
        filteredAzCustomers = List.from(azCustomerList);
      });
    } else {
      final filtered = azCustomerList.where((azCustomer) {
        return azCustomer.customer.matchesQuery(query);
      }).toList();
      
      setState(() {
        _prepareAzData(filtered);
        filteredAzCustomers = filtered;
      });
    }
  }

  void _prepareAzData(List<_AZCustomer> list) {
    for (var item in list) {
      if (item.name.isEmpty) continue;
      String firstLetter = item.name[0].toUpperCase();
      // Remover acentos básicos para agrupar mejor
      if (RegExp(r'[ÁÀÂÄ]').hasMatch(firstLetter)) firstLetter = 'A';
      if (RegExp(r'[ÉÈÊË]').hasMatch(firstLetter)) firstLetter = 'E';
      if (RegExp(r'[ÍÌÎÏ]').hasMatch(firstLetter)) firstLetter = 'I';
      if (RegExp(r'[ÓÒÔÖ]').hasMatch(firstLetter)) firstLetter = 'O';
      if (RegExp(r'[ÚÙÛÜ]').hasMatch(firstLetter)) firstLetter = 'U';
      if (!RegExp(r'[A-Z]').hasMatch(firstLetter)) firstLetter = '#';
    }
    SuspensionUtil.sortListBySuspensionTag(list);
    SuspensionUtil.setShowSuspensionStatus(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',

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
        padding: const EdgeInsets.only(top: 18.0, left: 18.0, bottom: 18.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Text(
              'Clientes',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            CustonSearch(
              controller: searchController,
              onTextChanged: filterCustomers,
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: filteredAzCustomers.isEmpty
                    ? const Center(child: Text('No hay clientes disponibles.'))
                    : AzListView(
                        data: filteredAzCustomers,
                        itemCount: filteredAzCustomers.length,
                        itemBuilder: (context, index) {
                          final item = filteredAzCustomers[index];
                          final customer = item.customer;

                          return Dismissible(
                            key: ValueKey(customer.id),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Crear nueva orden',
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
                                Navigator.pop(context, customer);
                              } else if (direction == DismissDirection.endToStart) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerInfoPage(
                                      customer: customer, 
                                      onProductListNavigate: (_) {},
                                    ),
                                  ),
                                );
                              }
                              return false;
                            },
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(item.name),
                                  const SizedBox(width: 6),
                                  // ✅ INDICADOR DE TIPO
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: customer.isCompany ? Colors.orange[100] : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      customer.isCompany ? 'Empresa' : 'Persona',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: customer.isCompany ? Colors.orange[800] : Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ EMAIL
                                  if (customer.email != null && customer.email!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 12, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          customer.email!,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  
                                  // ✅ TELÉFONO Y MÓVIL
                                  if (customer.phone != null && customer.phone!.isNotEmpty || 
                                      customer.mobile != null && customer.mobile!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: 12, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          customer.phone ?? customer.mobile ?? '',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        if (customer.phone != null && customer.mobile != null)
                                          Text(
                                            ' / ${customer.mobile}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  
                                  // ✅ RUT/VAT
                                  if (customer.vat != null && customer.vat!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.badge, size: 12, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'RUT: ${customer.vat!}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  
                                  // ✅ EMPRESA COMERCIAL (si es persona)
                                  if (!customer.isCompany && 
                                      customer.commercialCompanyName != null && 
                                      customer.commercialCompanyName!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.business, size: 12, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text(
                                          customer.commercialCompanyName!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: customer.isCompany ? Colors.orange[100] : Colors.deepPurple[100],
                                child: customer.isCompany 
                                    ? Icon(Icons.business, color: Colors.orange[800], size: 18)
                                    : Text(
                                        customer.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              onTap: () {
                                Navigator.pop(context, customer);
                              },
                            ),
                          );
                        },
                        susItemBuilder: (context, index) {
                          final tag = filteredAzCustomers[index].getSuspensionTag();
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
                            SuspensionUtil.getTagIndexList(filteredAzCustomers),
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
    String firstLetter = name[0].toUpperCase();
    if (RegExp(r'[ÁÀÂÄ]').hasMatch(firstLetter)) return 'A';
    if (RegExp(r'[ÉÈÊË]').hasMatch(firstLetter)) return 'E';
    if (RegExp(r'[ÍÌÎÏ]').hasMatch(firstLetter)) return 'I';
    if (RegExp(r'[ÓÒÔÖ]').hasMatch(firstLetter)) return 'O';
    if (RegExp(r'[ÚÙÛÜ]').hasMatch(firstLetter)) return 'U';
    if (RegExp(r'[A-Z]').hasMatch(firstLetter)) return firstLetter;
    return "#";
  }
}
class CustomerInfoPage extends StatelessWidget {
  final Customer customer;
  final Function(Customer) onProductListNavigate;

  const CustomerInfoPage({
    Key? key,
    required this.customer,
    required this.onProductListNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información de ${customer.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          customer.isCompany ? Icons.business : Icons.person,
                          color: customer.isCompany ? Colors.orange : Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      _buildInfoRow('Email', customer.email!),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      _buildInfoRow('Teléfono', customer.phone!),
                    if (customer.mobile != null && customer.mobile!.isNotEmpty)
                      _buildInfoRow('Móvil', customer.mobile!),
                    if (customer.vat != null && customer.vat!.isNotEmpty)
                      _buildInfoRow('RUT/VAT', customer.vat!),
                    if (!customer.isCompany && 
                        customer.commercialCompanyName != null && 
                        customer.commercialCompanyName!.isNotEmpty)
                      _buildInfoRow('Empresa Comercial', customer.commercialCompanyName!),
                    _buildInfoRow('Tipo', customer.isCompany ? 'Empresa' : 'Persona'),
                  ],
                ),
              ),
            ),
            
            // Dirección
            if (customer.street != null || customer.city != null || customer.zip != null)
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
                      if (customer.street != null && customer.street!.isNotEmpty)
                        Text('Dirección: ${customer.street}'),
                      if (customer.city != null && customer.city!.isNotEmpty)
                        Text('Ciudad: ${customer.city}'),
                      if (customer.zip != null && customer.zip!.isNotEmpty)
                        Text('Código Postal: ${customer.zip}'),
                    ],
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Botón para crear orden
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onProductListNavigate(customer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: customer.isCompany ? Colors.orange : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(customer.isCompany ? 
                  'Crear Orden de Compra' : 'Crear Orden para este Cliente'),
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
            width: 120,
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
