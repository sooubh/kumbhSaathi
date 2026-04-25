import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final startLng = 73.7898;
  final startLat = 19.9975;
  final endLng = 73.8000;
  final endLat = 20.0000;
  final url = Uri.parse('http://router.project-osrm.org/route/v1/foot/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=polyline&steps=true');

  try {
    final res = await http.get(url);
    print(res.statusCode);
    if(res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print(data['routes'][0]['distance']);
      print(data['routes'][0]['duration']);
      print(data['routes'][0]['geometry'].substring(0, 20)); // Polyline
    }
  } catch (e) {
    print(e);
  }
}
