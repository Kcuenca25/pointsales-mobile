// lib/services/draft_order_service.dart
import 'package:hive/hive.dart';
import 'package:ecomerce_app/src/domain/models/draft_order.dart';
import 'dart:async';
import 'hive_init.dart';

class DraftOrderService {
  static const String _boxName = 'draft_orders';
  static Box<DraftOrder>? _box; // ✅ Cambiado a Box<DraftOrder> directamente
  static DraftOrderService? _instance;
  
  final StreamController<List<DraftOrder>> _controller = 
      StreamController<List<DraftOrder>>.broadcast();

  factory DraftOrderService() {
    return _instance ??= DraftOrderService._internal();
  }

  DraftOrderService._internal();

  static DraftOrderService get instance {
    return _instance ?? DraftOrderService();
  }

  bool get isInitialized => _box != null && _box!.isOpen;

  Future<void> init() async {
    if (isInitialized) {
      print('✅ DraftOrderService ya está inicializado');
      return;
    }

    try {
      // ✅ Inicializar Hive primero
      await HiveInitializer.initialize();
      
      // ✅ Intentar cerrar si ya está abierta con tipo incorrecto
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      
      // ✅ Abrir la caja con el tipo correcto
      _box = await Hive.openBox<DraftOrder>(_boxName);
      
      print('✅ DraftOrderService inicializado con ${_box!.length} borradores');
      
      // ✅ Emitir valor inicial
      _controller.add(_getAllDraftsSync());
    } catch (e) {
      print('❌ Error inicializando DraftOrderService: $e');
      
      // ✅ Fallback: intentar abrir sin tipo específico
      try {
        final dynamicBox = await Hive.openBox(_boxName);
        _box = dynamicBox as Box<DraftOrder>;
        print('✅ DraftOrderService inicializado con cast');
        _controller.add(_getAllDraftsSync());
      } catch (e2) {
        print('❌ Error alternativo: $e2');
        rethrow;
      }
    }
  }

  Box<DraftOrder> _getBox() {
    if (!isInitialized) {
      throw StateError('DraftOrderService no está inicializado.');
    }
    return _box!;
  }

  // ✅ MÉTODO PRIVADO SINCRONO
  List<DraftOrder> _getAllDraftsSync() {
    try {
      final box = _getBox();
      return box.values
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ Error obteniendo borradores: $e');
      return [];
    }
  }

  // ✅ MÉTODO PÚBLICO ASYNC
  Future<List<DraftOrder>> getAllDrafts() async {
    try {
      await init(); // Asegurar inicialización
      return _getAllDraftsSync();
    } catch (e) {
      print('❌ Error en getAllDrafts(): $e');
      return [];
    }
  }

  // ✅ MÉTODO SINCRONO (opcional)
  List<DraftOrder> getAllDraftsSync() {
    try {
      return _getAllDraftsSync();
    } catch (e) {
      print('❌ Error en getAllDraftsSync(): $e');
      return [];
    }
  }

  void _notifyListeners() {
    if (!_controller.isClosed) {
      _controller.add(_getAllDraftsSync());
    }
  }

  Future<void> saveDraft(DraftOrder draft) async {
    try {
      await init(); // Asegurar inicialización
      await _getBox().put(draft.id, draft);
      print('✅ Borrador guardado: ${draft.id} - ${draft.displayType}');
      _notifyListeners();
    } catch (e) {
      print('❌ Error guardando borrador: $e');
      rethrow;
    }
  }

  Future<void> deleteDraft(String id) async {
    try {
      await init();
      await _getBox().delete(id);
      print('🗑️ Borrador eliminado: $id');
      _notifyListeners();
    } catch (e) {
      print('❌ Error eliminando borrador: $e');
      rethrow;
    }
  }

  Future<void> clearAllDrafts() async {
    try {
      await init();
      await _getBox().clear();
      print('🗑️ Todos los borradores eliminados');
      _notifyListeners();
    } catch (e) {
      print('❌ Error limpiando borradores: $e');
      rethrow;
    }
  }

  bool hasDrafts() {
    try {
      return _getBox().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  int get draftCount {
    try {
      return _getBox().length;
    } catch (e) {
      return 0;
    }
  }

  Stream<List<DraftOrder>> get draftsStream {
    return _controller.stream;
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
