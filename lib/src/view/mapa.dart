import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-0.2232523, -78.5141064); // Coordenadas iniciales
  final String _googleApiKey = "AIzaSyB3ZFuCBWRPkZBS_rMMkUKxK7mCvQA6MfQ"; // Tu clave de API
  final Map<MarkerId, Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _activeTravelMode = "DRIVING";

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    final Marker originMarker = Marker(
      markerId: MarkerId('origin'),
      position: _center,
      infoWindow: InfoWindow(title: "Origen"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers[MarkerId('origin')] = originMarker;
    });
  }

  Future<void> _addDestination(String origin, String destination) async {
    LatLng? originPosition = await _getCoordinatesFromAddress(origin);
    LatLng? destinationPosition = await _getCoordinatesFromAddress(destination);

    if (originPosition != null && destinationPosition != null) {
      setState(() {
        _markers[MarkerId('origin')] = Marker(
          markerId: MarkerId('origin'),
          position: originPosition,
          infoWindow: InfoWindow(title: "Origen"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        _markers[MarkerId('destination')] = Marker(
          markerId: MarkerId('destination'),
          position: destinationPosition,
          infoWindow: InfoWindow(title: "Destino"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });

      await _getDirections(originPosition, destinationPosition);
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$_googleApiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    final Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$_activeTravelMode&key=$_googleApiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      final overviewPolyline = route['overview_polyline']['points'];
      final decodedPolyline = _decodePolyline(overviewPolyline);

      setState(() {
        _polylines.add(Polyline(
          polylineId: PolylineId('route_${_polylines.length}'),
          color: Colors.blue,
          width: 5,
          points: decodedPolyline,
        ));
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa con Rutas'),
        backgroundColor: Colors.green[700],
      ),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 14,
        ),
        markers: Set<Marker>.of(_markers.values),
        polylines: _polylines,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRouteDialog,
        child: Icon(Icons.add),
      ),
    );
  }

 void _showAddRouteDialog() {
  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController _originController = TextEditingController();
      final TextEditingController _destinationController = TextEditingController();
      return AlertDialog(
        title: Text('Agregar Ruta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _originController,
              decoration: InputDecoration(
                labelText: 'Dirección de origen',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Dirección de destino',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _addDestination(
                _originController.text,
                _destinationController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Agregar'),
          ),
        ],
      );
    },
  );
}

}
