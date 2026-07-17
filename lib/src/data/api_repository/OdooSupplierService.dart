
// import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
// import 'package:ecomerce_app/src/domain/models/customer_model.dart';


// class OdooSupplierService {
//   final OdooServiceEnhanced odooService;

//   OdooSupplierService(this.odooService);

//   Future<List<Customer>> getSuppliers({int limit = 20}) async {
//     try {
//       // ✅ CORREGIR: usar callKw en lugar de client.callKw
//       final result = await odooService.callKw({
//         'service': 'object',
//         'method': 'execute_kw',
//         'args': [
//           odooService.dbName,
//           odooService.uid,
//           odooService.username,
//           'res.partner',
//           'search_read',
//           [
//             ['supplier_rank', '>', 0] // Filtro para proveedores
//           ],
//           {
//             'fields': ["id", "name", "email", "phone", "city", "is_company"],
//             'limit': limit,
//           }
//         ],
//       });

//       return (result as List).map((item) {
//         return Customer(
//           id: item['id'] as int,
//           name: item['name'] as String,
//           email: item['email'] as String?,
//           phone: item['phone'] as String?,
//           city: item['city'] as String?,
//           isCompany: item['is_company'] as bool? ?? false,
//         );
//       }).toList();
//     } catch (e) {
//       print('❌ Error getting suppliers: $e');
//       rethrow;
//     }
//   }

//   Future<int> getSupplierCount() async {
//     try {
//       final result = await odooService.callKw({
//         'service': 'object',
//         'method': 'execute_kw',
//         'args': [
//           odooService.dbName,
//           odooService.uid,
//           odooService.username,
//           'res.partner',
//           'search_count',
//           [
//             ['supplier_rank', '>', 0]
//           ],
//         ],
//       });
//       return result as int;
//     } catch (e) {
//       print('❌ Error counting suppliers: $e');
//       return 0;
//     }
//   }

//   // ✅ MÉTODO ALTERNATIVO USANDO searchRead
//   Future<List<Customer>> getSuppliersAlternative({int limit = 20}) async {
//     try {
//       final results = await odooService.searchRead(
//         'res.partner',
//         [['supplier_rank', '>', 0]],
//         fields: ["id", "name", "email", "phone", "city", "is_company"],
//         limit: limit,
//       );

//       return results.map((item) {
//         return Customer(
//           id: item['id'] as int,
//           name: item['name'] as String,
//           email: item['email'] as String?,
//           phone: item['phone'] as String?,
//           city: item['city'] as String?,
//           isCompany: item['is_company'] as bool? ?? false,
//         );
//       }).toList();
//     } catch (e) {
//       print('❌ Error getting suppliers (alternative): $e');
//       return [];
//     }
//   }
// }
