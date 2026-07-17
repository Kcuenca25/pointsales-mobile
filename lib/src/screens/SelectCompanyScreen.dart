// lib/screens/select_company_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class SelectCompanyScreen extends StatefulWidget {
  const SelectCompanyScreen({super.key});

  @override
  _SelectCompanyScreenState createState() => _SelectCompanyScreenState();
}

class _SelectCompanyScreenState extends State<SelectCompanyScreen> {
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _sessionValid = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _validateAndLoadCompanies();
  }

    Future<void> _validateAndLoadCompanies() async {
    try {
      // Verificar si hay sesión válida
      _sessionValid = await _checkSession();
      
      if (!_sessionValid) {
        // Redirigir a login si no hay sesión válida
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/credentials');
        });
        return;
      }
      
      // Cargar empresas si la sesión es válida
      await _loadCompanies();
      
    } catch (e) {
      print('❌ Error validando sesión: $e');
      setState(() {
        _errorMessage = 'Sesión expirada. Vuelve a iniciar sesión.';
      });
      
      // Redirigir después de mostrar el error
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/credentials');
      });
    }
  }

  Future<bool> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUid = prefs.getInt('current_uid') != null;
    final hasPassword = prefs.getString('session_password') != null;
    return hasUid && hasPassword;
  }

  Future<void> _loadCompanies() async {
    try {
      // Obtener datos de sesión
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('odoo_domain');
      final database = prefs.getString('odoo_database');
      final uid = prefs.getInt('current_uid');
      final password = prefs.getString('session_password'); // ← Obtener contraseña guardada
      
      print('🏢 Cargando empresas...');
      print('   🌐 Dominio: $domain');
      print('   💾 BD: $database');
      print('   👤 UID: $uid');
      
      if (domain == null || database == null || uid == null || password == null) {
        throw Exception('Sesión no válida. Vuelve a iniciar sesión.');
      }
      
      // Conectar y listar empresas
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://$domain',
        dbName: database,
      )..uid = uid;
      
      // Obtener empresas disponibles
      final result = await odooService.callKw({
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          database,
          uid,
          password, // ← Usar la contraseña guardada
          'res.company',
          'search_read',
          [],
          {'fields': ['id', 'name', 'display_name']}
        ],
      });
      
      if (result is List) {
        _companies = result.cast<Map<String, dynamic>>();
        print('✅ Empresas encontradas: ${_companies.length}');
        
        // Si solo hay una, seleccionarla automáticamente
        if (_companies.length == 1) {
          _selectedCompanyId = _companies[0]['id'].toString();
          // Auto-continuar después de 1 segundo
          Future.delayed(const Duration(seconds: 1), () {
            _continueToLogo();
          });
        }
      } else {
        throw Exception('Formato de respuesta no válido');
      }
      
    } catch (e) {
      print('❌ Error cargando empresas: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString().replaceAll("Exception: ", "")}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _continueToLogo() async {
    if (_selectedCompanyId == null) {
      setState(() => _errorMessage = 'Selecciona una empresa para continuar');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Guardar empresa seleccionada
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_company_id', _selectedCompanyId!);
      final selectedComp = _companies.firstWhere(
        (c) => c['id'].toString() == _selectedCompanyId,
        orElse: () => {'name': 'Mi Empresa'}
      );
      final companyNameToSave = selectedComp['name'] ?? selectedComp['display_name'] ?? 'Mi Empresa';
      await prefs.setString('selected_company_name', companyNameToSave.toString());
      
      print('✅ Empresa seleccionada: $_selectedCompanyId');
      
      // Mantenemos la contraseña de sesión para evitar errores de NoneType en re-logins de diversas pantallas
      
      // Ir al logo
      Navigator.pushReplacementNamed(context, '/company-logo');
      
    } catch (e) {
      print('❌ Error guardando empresa: $e');
      setState(() {
        _errorMessage = 'Error al guardar la selección';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seleccionar Empresa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 20),
                      Text('Cargando empresas...'),
                    ],
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/credentials');
                          },
                          child: const Text('Volver a Iniciar Sesión'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Selecciona la empresa con la que trabajarás:',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        
                        // Lista de empresas
                        Expanded(
                          child: ListView.builder(
                            itemCount: _companies.length,
                            itemBuilder: (context, index) {
                              final company = _companies[index];
                              final companyId = company['id'].toString();
                              final companyName = company['display_name'] ?? company['name'] ?? 'Empresa';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedCompanyId == companyId 
                                        ? Colors.deepPurple 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple[50],
                                    child: Text(
                                      companyName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    companyName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: Radio<String>(
                                    value: companyId,
                                    groupValue: _selectedCompanyId,
                                    onChanged: (value) {
                                      setState(() => _selectedCompanyId = value);
                                    },
                                    activeColor: Colors.deepPurple,
                                  ),
                                  onTap: () {
                                    setState(() => _selectedCompanyId = companyId);
                                  },
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Botón Continuar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedCompanyId == null ? null : _continueToLogo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
