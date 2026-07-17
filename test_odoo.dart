import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://lmhlast.tailorw.net/jsonrpc';
  final db = 'pointsales-v18';
  final user = 'admin@tailorw.com';
  final pass = 'A001admin';

  print('Logueando...');
  var res = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "id": 1,
      "params": {
        "service": "common",
        "method": "login",
        "args": [db, user, pass]
      }
    })
  );
  
  final uid = jsonDecode(res.body)['result'];
  print('UID: $uid');

  print('Buscando ordenes de venta...');
  res = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "id": 2,
      "params": {
        "service": "object",
        "method": "execute_kw",
        "args": [
          db, uid, pass,
          'sale.order',
          'search_read',
          [[]],
          {
            'fields': ['id', 'name', 'partner_id', 'state'],
            'limit': 5
          }
        ]
      }
    })
  );

  print(res.body);
}
