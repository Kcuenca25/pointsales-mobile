// lib/services/config_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:ecomerce_app/src/domain/models/odoo_config.dart';
import 'dart:convert'; // ← AÑADE ESTA LÍNEA

class ConfigManager {
  static const String _configsKey = 'odoo_configurations';
  static const String _activeConfigIdKey = 'active_configuration_id';
  
  // Verificar si es primera vez
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList(_configsKey);
    return configsJson == null || configsJson.isEmpty;
  }
  
  // Obtener configuración activa
  static Future<OdooConfig?> getActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeConfigIdKey);
    
    if (activeId == null) return null;
    
    final allConfigs = await getAllConfigs();
    return allConfigs.firstWhere(
      (config) => config.id == activeId,
      orElse: () => allConfigs.isNotEmpty ? allConfigs.first : throw Exception('No hay configuraciones'),
    );
  }
  
  // Obtener todas las configuraciones
  static Future<List<OdooConfig>> getAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList(_configsKey) ?? [];
    
    return configsJson
        .map((json) => OdooConfig.fromJson(jsonDecode(json)))
        .toList();
  }
  
  // Guardar nueva configuración
  static Future<void> saveConfig(OdooConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final existingConfigs = await getAllConfigs();
    
    // Reemplazar si ya existe, o agregar nueva
    final List<OdooConfig> updatedConfigs = [];
    bool found = false;
    
    for (final existing in existingConfigs) {
      if (existing.id == config.id) {
        updatedConfigs.add(config);
        found = true;
      } else {
        updatedConfigs.add(existing);
      }
    }
    
    if (!found) {
      updatedConfigs.add(config);
    }
    
    // Guardar todas las configuraciones
    final configsJson = updatedConfigs
        .map((config) => jsonEncode(config.toJson()))
        .toList();
    
    await prefs.setStringList(_configsKey, configsJson);
    
    // Si esta configuración está activa, guardar como activa
    if (config.isActive) {
      await prefs.setString(_activeConfigIdKey, config.id);
    }
  }
  
  // Cambiar configuración activa
  static Future<void> switchActiveConfig(String configId) async {
    final configs = await getAllConfigs();
    
    // Desactivar todas, activar la seleccionada
    for (final config in configs) {
      config.isActive = (config.id == configId);
      await saveConfig(config);
    }
  }
  
  // Eliminar configuración
  static Future<void> deleteConfig(String configId) async {
    final configs = await getAllConfigs();
    final filteredConfigs = configs.where((c) => c.id != configId).toList();
    
    final prefs = await SharedPreferences.getInstance();
    final configsJson = filteredConfigs
        .map((config) => jsonEncode(config.toJson()))
        .toList();
    
    await prefs.setStringList(_configsKey, configsJson);
    
    // Si eliminamos la activa, establecer primera como activa
    final activeId = prefs.getString(_activeConfigIdKey);
    if (activeId == configId && filteredConfigs.isNotEmpty) {
      await prefs.setString(_activeConfigIdKey, filteredConfigs.first.id);
    }
  }
}
