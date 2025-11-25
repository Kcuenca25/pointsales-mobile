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
        baseUrl: 'https://solutions.tailorw.net',
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
            
            // ✅ SOLO LAS CARDS PRINCIPALES - CON PRIMER CLIENTE REAL
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
                        
          ],
        ),
      ),
    );
  }
}