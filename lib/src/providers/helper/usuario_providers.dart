import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_auth_service.dart'; // ✅ IMPORT CORRECTO

class UsuarioProvider with ChangeNotifier {
  List<User> usuarios = [];
  String nombre = ""; 
  String email = "";
  String password = "";
  bool isAuthenticated = false;
  String? accessToken;
  int? userId;
  String? companyName; // ✅ NUEVO: Nombre de la empresa
  String? userName;  // ✅ AGREGAR para Odoo user ID

  UsuarioProvider() {
    _loadUser(); // Cargar usuario autenticado
    getUsuarios(); // Cargar usuarios al inicializar el provider
  }

  // ✅ MÉTODO PARA LOGIN CON ODDO
    Future<bool> loginWithOdoo(String username, String password) async {
    try {
      final authService = OdooAuthService();
      final result = await authService.authenticate(
        username: username,
        password: password,
      );
      
      if (result['success'] == true) {
        // ✅ GUARDAR TODA LA INFORMACIÓN
        await saveEmail('$username@tailorw.com');
        await saveUser(username);
        await saveAccessToken(result['sessionId'] ?? '');
        await saveCompanyName(result['companyName'] ?? 'Mi Empresa');
        await saveUserName(result['userName'] ?? username);
        
        userId = result['userId'];
        isAuthenticated = true;
        
        print('✅ Login Odoo exitoso - User ID: $userId');
        print('🏢 Empresa: $companyName');
        print('👤 Usuario: $userName');
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login con Odoo: $e');
      return false;
    }
  }

  // ✅ NUEVO: Guardar nombre de la empresa
  Future<void> saveCompanyName(String companyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', companyName);
    this.companyName = companyName;
    notifyListeners();
  }

  // ✅ NUEVO: Guardar nombre completo del usuario
  Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    this.userName = userName;
    notifyListeners();
  }

  // ✅ MÉTODO SIMPLIFICADO PARA MODO LOCAL
  Future<void> loginLocal() async {
    try {
      // Simular usuario de prueba
      await saveEmail('admin@tailorw.com');
      await saveUser('Admin Local');
      isAuthenticated = true;
      
      print('✅ Sesión local iniciada - Modo desarrollo');
      notifyListeners();
    } catch (e) {
      print('Error en login local: $e');
    }
  }

  // Método para registrar un nuevo usuario
  Future<bool> registerUser(String username, String email, String password) async {
    try {
      final nuevoUsuario = User(id: 0, username: username, email: email, password: password);
      await DatabaseHelper().insertUser(nuevoUsuario);
      await saveEmail(email);
      return true;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return false;
    }
  }

  // ✅ CORREGIR: quitar el espacio en ' username'
  Future<void> saveUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username); // ✅ SIN ESPACIO
    this.nombre = username;
    notifyListeners();
  }

  // Método para guardar la contraseña en SharedPreferences
  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', password);
    this.password = password;
    notifyListeners();
  }

  // Método para cargar el nombre del usuario autenticado desde SharedPreferences
  Future<String?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Método para cerrar sesión y eliminar el nombre guardado
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username'); // ✅ CORREGIR: 'username' sin espacio
    nombre = "";
    notifyListeners();
  }

  // Insertar usuario en la base de datos
  Future<void> insertUsuario(String username, String email, String password) async {
    final nuevoUsuario = User(id: 0, username: username, email: email, password: password);
    await DatabaseHelper().insertUser(nuevoUsuario);
    getUsuarios();
  }

  // Obtener todos los usuarios desde la base de datos
  Future<void> getUsuarios() async {
    usuarios = await DatabaseHelper().getUsers();
    notifyListeners();
  }

  // Actualizar un usuario existente en la base de datos
  Future<void> updateUsuario(User usuarioActualizado) async {
    await DatabaseHelper().updateUser(usuarioActualizado);
    getUsuarios();
  }

  // Eliminar un usuario de la base de datos
  Future<void> deleteUsuario(int id) async {
    await DatabaseHelper().deleteUser(id);
    getUsuarios();
  }

  // Guardar el email del usuario autenticado en SharedPreferences
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    this.email = email;
    isAuthenticated = true;
    notifyListeners();
  }

  // Cargar el usuario autenticado desde SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? "";
    nombre = prefs.getString('username') ?? "";
    accessToken = prefs.getString('accessToken');
    companyName = prefs.getString('companyName'); // ✅ Cargar empresa
    userName = prefs.getString('userName');       // ✅ Cargar nombre usuario
    
    if (email.isNotEmpty) {
      isAuthenticated = true;
    }
    notifyListeners();
  }


  // ✅ Método para guardar el token de acceso
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    accessToken = token;
    notifyListeners();
  }

  // Método para obtener el token de acceso
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
    return accessToken;
  }

  // Método para verificar si hay un usuario autenticado
  Future<bool> checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    return email != null && email.isNotEmpty;
  }

  // ✅ Método para cargar el token al iniciar
  Future<void> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
    notifyListeners();
  }

  // ✅ Método para cerrar sesión completo
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('username');
    await prefs.remove('accessToken');
    await prefs.remove('password');
    await prefs.remove('companyName'); // ✅ Eliminar empresa
    await prefs.remove('userName');    // ✅ Eliminar nombre usuario
    
    email = "";
    nombre = "";
    password = "";
    accessToken = null;
    userId = null;
    companyName = null; // ✅ Limpiar empresa
    userName = null;    // ✅ Limpiar nombre usuario
    isAuthenticated = false;
    
    notifyListeners();
    print('✅ Sesión cerrada correctamente');
  }
}