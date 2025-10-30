//import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_cards/custon_cards.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';

import 'package:ecomerce_app/src/domain/models/customer_model.dart';

class HomeScreenContent extends StatefulWidget {
  final Function(Customer) onUserPageNavigate;

  const HomeScreenContent({Key? key, required this.onUserPageNavigate}) : super(key: key);

  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<Customer>> futureCustomers;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    futureCustomers = _loadCustomers();
  }

  Future<List<Customer>> _loadCustomers() async {
    try {
      print('🚀 Iniciando carga de clientes...');
      
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      print('🔐 Intentando login...');
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        print('✅ Login exitoso - UID: ${odooService.uid}');
        
        final customerService = OdooCustomerService(odooService);
        final customers = await customerService.getCustomers(limit: 10);
        
        print('🎯 Clientes obtenidos: ${customers.length}');
        
        if (customers.isEmpty) {
          print('⚠️  Lista de clientes vacía');
        } else {
          for (var customer in customers) {
            print('   👤 ${customer.name} (ID: ${customer.id}) - Email: ${customer.email ?? "N/A"}');
          }
        }
        
        return customers;
      } else {
        print('❌ Error de autenticación');
        return [];
      }
    } catch (e) {
      print('💥 Error crítico en _loadCustomers: $e');
      return [];
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // ✅ CARDS PRINCIPALES - CON PRIMER CLIENTE REAL
            FutureBuilder<List<Customer>>(
              future: futureCustomers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  // Si no hay clientes, mostrar cards vacías o alternativa
                  return Custon_Cards(
                    customer: Customer(
                      id: 0,
                      name: 'Seleccionar Cliente',
                      companyType: 'person',
                      isCompany: false,
                    ),
                  );
                }
                
                // ✅ Usar el primer cliente real para las cards
                final firstCustomer = snapshot.data!.first;
                return Custon_Cards(
                  customer: firstCustomer,
                );
              },
            ),
            const SizedBox(height: 30),
            
            // ✅ SECCIÓN DE CLIENTES RECIENTES
            FutureBuilder<List<Customer>>(
              future: futureCustomers,
              builder: (context, snapshot) {
                print('🔄 FutureBuilder estado: ${snapshot.connectionState}');
                print('📊 FutureBuilder datos: ${snapshot.hasData}');
                print('❌ FutureBuilder error: ${snapshot.error}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      Center(child: CircularProgressIndicator()),
                      SizedBox(height: 10),
                      Text('Cargando clientes...'),
                    ],
                  );
                }
                
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            futureCustomers = _loadCustomers();
                          });
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Column(
                    children: [
                      const Text(
                        'No hay clientes disponibles',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            futureCustomers = _loadCustomers();
                          });
                        },
                        child: const Text('Recargar'),
                      ),
                    ],
                  );
                }
                
                final customers = snapshot.data!;
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Clientes Recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              futureCustomers = _loadCustomers();
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // ✅ LISTA DE CLIENTES
                    ...customers.map((customer) => _buildCustomerListItem(customer)),
                    
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientScreen(
                              onCustomerPageNavigate: widget.onUserPageNavigate,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Ver todos los clientes'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerListItem(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple[100],
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.deepPurple),
          ),
        ),
        title: Text(customer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.email != null && customer.email!.isNotEmpty)
              Text(
                customer.email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Text(
                customer.phone!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
          onPressed: () {
            widget.onUserPageNavigate(customer);
          },
        ),
        onTap: () {
          widget.onUserPageNavigate(customer);
        },
      ),
    );
  }
}