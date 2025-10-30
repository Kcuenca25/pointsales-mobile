import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


const kGoogleApiKey = "AIzaSyB3ZFuCBWRPkZBS_rMMkUKxK7mCvQA6MfQ";  // Reemplaza con tu clave API

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlaceSearchScreen(),
    );
  }
}

class PlaceSearchScreen extends StatefulWidget {
  @override
  _PlaceSearchScreenState createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> predictions = [];

Future<void> searchPlaces(String input) async {
  const apiKey = "AIzaSyB3ZFuCBWRPkZBS_rMMkUKxK7mCvQA6MfQ";  
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data['predictions']);
  } else {
    print("Error: ${response.statusCode}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Places")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Search places",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Realiza la búsqueda cada vez que el usuario escribe algo
                if (value.isNotEmpty) {
                  searchPlaces(value);
                } else {
                  setState(() {
                    predictions = [];
                  });
                }
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(predictions[index]['description']),
                    onTap: () {
                      // Aquí puedes manejar lo que ocurre cuando el usuario selecciona un lugar
                      print('Selected: ${predictions[index]['description']}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
