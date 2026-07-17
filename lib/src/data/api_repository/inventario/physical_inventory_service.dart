import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecomerce_app/src/config/api_config.dart';

class PhysicalInventoryService {
  /// Actualiza la cantidad de un producto enviando una petición POST al endpoint de inventario físico.
  Future<bool> updateProductQuantity(String productId, int quantity) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.physicalInventoryEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'database': ApiConfig.dbName, // A veces Odoo requiere la BD en la petición si no se maneja por sesión
        }),
      );

      if (response.statusCode == 200) {
        // Asumiendo que el servidor retorna un JSON que podemos verificar
        // Por ejemplo: {"status": "success"} o {"result": ...}
        final responseData = jsonDecode(response.body);
        print('✅ Respuesta de Odoo: $responseData');
        
        // Ajusta esto dependiendo de la respuesta real de tu servidor
        return true;
      } else {
        print('❌ Error del servidor: Código ${response.statusCode}');
        print('❌ Detalle: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error al actualizar inventario físico: $e');
      return false;
    }
  }
}
