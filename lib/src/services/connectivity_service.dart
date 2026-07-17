// connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  // ✅ Verificar si hay conexión a internet
  static Future<bool> hasInternet() async {
  try {
    // 1. Verificar si hay conexión de red
    var connectivityResult = await _connectivity.checkConnectivity();
    
    // Si no hay ninguna conexión (modo avión)
    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No hay conexión de red disponible - Modo Avión');
      return false;
    }

    // 2. Verificar SI REALMENTE HAY INTERNET (más estricto)
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    
    final hasRealInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    
    print('📡 Estado de conexión: $connectivityResult - Internet REAL: $hasRealInternet');
    return hasRealInternet;
    
  } on SocketException catch (_) {
    print('❌ No hay acceso a internet REAL (SocketException)');
    return false;
  } on TimeoutException catch (_) {
    print('⏰ Timeout - No hay internet REAL');
    return false;
  } catch (e) {
    print('❌ Error verificando conectividad: $e');
    return false;
  }
}

  // ✅ Stream para escuchar cambios de conexión (CORREGIDO)
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  // ✅ Verificar tipo de conexión (CORREGIDO)
  static Future<List<ConnectivityResult>> getConnectionType() async {
    return await _connectivity.checkConnectivity();
  }
}
