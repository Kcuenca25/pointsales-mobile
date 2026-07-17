// lib/services/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'draft_order_adapter.dart';

class HiveInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar Hive
      await Hive.initFlutter();
      
      // Registrar adaptadores
      if (!Hive.isAdapterRegistered(DraftOrderAdapter().typeId)) {
        Hive.registerAdapter(DraftOrderAdapter());
      }
      
      _initialized = true;
      print('✅ Hive inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando Hive: $e');
      rethrow;
    }
  }

  static Future<void> closeBoxes() async {
    try {
      // Cerrar todas las cajas abiertas
      await Hive.close();
      _initialized = false;
      print('🔒 Todas las cajas de Hive cerradas');
    } catch (e) {
      print('❌ Error cerrando cajas de Hive: $e');
    }
  }
}
