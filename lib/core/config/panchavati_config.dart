import 'package:latlong2/latlong.dart';

/// Panchavati Area Boundaries and Configuration
class PanchavatiConfig {
  // Panchavati area boundary (polygon)
 static final List<LatLng> panchavatiAreaBoundary = [
  LatLng(20.0125, 73.8070), // North-East corner 
  LatLng(20.0125, 73.7870), // North-West corner
  LatLng(19.9950, 73.7870), // South-West corner
  LatLng(19.9950, 73.8070), // South-East corner
  LatLng(20.0125, 73.8070), // Close polygon back to start
];

  // Center point of Panchavati (Ram Ghat)
  static const LatLng panchavatiCenter = LatLng(19.9987, 73.7883);

  // Optimal zoom level for Panchavati view
  static const double optimalZoom = 15.5;

  // Minimum zoom to see all ghats clearly
  static const double minZoom = 14.0;

  // Maximum zoom for detail
  static const double maxZoom = 18.0;

  // Bounding box for Panchavati area
  static final LatLng southWest = LatLng(19.9950, 73.7860);
  static final LatLng northEast = LatLng(20.0020, 73.7905);

  // Walking routes within Panchavati (main pilgrimage path)
  static final List<LatLng> mainPilgrimageRoute = [
    LatLng(19.9960, 73.7870), // Someshwar Ghat
    LatLng(19.9970, 73.7878), // Ahilya Ghat
    LatLng(19.9978, 73.7890), // Naroshankar Ghat
    LatLng(19.9987, 73.7883), // Ram Ghat (main)
    LatLng(19.9995, 73.7875), // Kala Ram Ghat
    LatLng(20.0005, 73.7888), // Ganga Ghat
    LatLng(20.0012, 73.7895), // Tapovan Ghat
  ];

  // Important landmarks in Panchavati
  static const Map<String, LatLng> landmarks = {
    'Kala Ram Temple': LatLng(19.9990, 73.7870),
    'Sita Gufa': LatLng(19.9982, 73.7865),
    'Kalaram Mandir': LatLng(19.9993, 73.7868),
    'Panchavati Parking': LatLng(20.0000, 73.7870),
  };

  // Best viewing bounds to show all Panchavati ghats
  static List<LatLng> get viewingBounds => [southWest, northEast];

  // Check if a location is within Panchavati area
  static bool isInPanchavati(LatLng point) {
    return point.latitude >= southWest.latitude &&
        point.latitude <= northEast.latitude &&
        point.longitude >= southWest.longitude &&
        point.longitude <= northEast.longitude;
  }

  // Get ghat order for pilgrimage (south to north)
  static List<String> get ghatPilgrimageOrder => [
        'someshwar_ghat',
        'ahilya_ghat',
        'naroshankar_ghat',
        'ram_ghat', // Main ghat
        'kala_ram_ghat',
        'ganga_ghat',
        'tapovan_ghat',
      ];
}
