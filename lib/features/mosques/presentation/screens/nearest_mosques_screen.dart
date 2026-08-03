import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' show cos, sqrt, asin;

// To get isDark if needed
import '../../data/mosque_model.dart';
import '../../data/overpass_service.dart';
import '../../data/osrm_service.dart';
import '../../data/mosque_storage.dart';
import '../widgets/mosque_card.dart';

class NearestMosquesScreen extends StatefulWidget {
  const NearestMosquesScreen({Key? key}) : super(key: key);

  @override
  State<NearestMosquesScreen> createState() => _NearestMosquesScreenState();
}

class _NearestMosquesScreenState extends State<NearestMosquesScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final OverpassService _placesService = OverpassService();
  final OsrmService _osrmService = OsrmService();
  final MosqueStorage _mosqueStorage = MosqueStorage();
  
  LatLng? _currentPosition;
  LatLng? _currentMapCenter;
  List<Mosque> _mosques = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  
  Timer? _debounceTimer;
  late StreamSubscription _internetSubscription;

  // Favorites
  List<Mosque> _favorites = [];

  @override
  void initState() {
    super.initState();
    _initNetworkListener();
    _loadFavorites();
    _determinePosition();
  }

  void _initNetworkListener() {
    _internetSubscription = InternetConnection().onStatusChange.listen((InternetStatus status) {
      setState(() {
        _hasInternet = status == InternetStatus.connected;
      });
      if (_hasInternet && _mosques.isEmpty && _currentPosition != null) {
        _fetchMosquesInView();
      }
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await _mosqueStorage.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favs;
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoading = true);

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied.');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentMapCenter = _currentPosition;
    });

    _mapController.move(_currentPosition!, 15.0);
    _fetchMosquesInView();
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentMapCenter = camera.center;
    if (hasGesture) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _fetchMosquesInView();
      });
    }
  }

  Future<void> _fetchMosquesInView() async {
    if (!_hasInternet || _currentPosition == null || _currentMapCenter == null) return;

    setState(() => _isLoading = true);

    final bounds = _mapController.camera.visibleBounds;
    double radius = _calculateDistance(
      _currentMapCenter!.latitude, _currentMapCenter!.longitude,
      bounds.northEast.latitude, bounds.northEast.longitude
    );
    
    if (radius < 5000) {
      radius = 5000;
    }

    final mosques = await _placesService.fetchMosquesAround(_currentMapCenter!, radius);
    
    for (var m in mosques) {
      if (_favorites.any((f) => f.id == m.id)) {
        m.isFavorite = true;
      }
      m.approxDistanceMeters = _calculateDistance(
        _currentPosition!.latitude, _currentPosition!.longitude,
        m.lat, m.lon
      );
    }

    mosques.sort((a, b) => (a.approxDistanceMeters ?? 0).compareTo(b.approxDistanceMeters ?? 0));

    for (int i = 0; i < (mosques.length > 5 ? 5 : mosques.length); i++) {
      final route = await _osrmService.getRoute(start: _currentPosition!, end: mosques[i].latLng, profile: 'driving');
      if (route != null) {
        mosques[i].osrmDistanceMeters = route.distanceMeters;
        mosques[i].osrmDrivingDurationSeconds = route.durationSeconds;
      }
      final walkRoute = await _osrmService.getRoute(start: _currentPosition!, end: mosques[i].latLng, profile: 'foot');
      if (walkRoute != null) {
        mosques[i].osrmWalkingDurationSeconds = walkRoute.durationSeconds;
      }
    }

    if (!mounted) return;
    setState(() {
      _mosques = mosques;
      _isLoading = false;
    });
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)) * 1000; 
  }

  void _recenter() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
      _currentMapCenter = _currentPosition;
      _fetchMosquesInView();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _internetSubscription.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'أقرب المساجد' : 'Nearest Mosques'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(21.4225, 39.8262),
              initialZoom: 15.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.umer.quranzone',
              ),
              MarkerLayer(
                markers: _mosques.map((m) => Marker(
                  point: m.latLng,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      _mosqueStorage.addRecent(m);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(m.name)),
                      );
                    },
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                )).toList(),
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Offline Degradation Overlay
          if (!_hasInternet)
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.black54 : Colors.white70,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey)
                          .animate().fade().scale(),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No Internet Connection',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ).animate().fade(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? 'يرجى التحقق من اتصالك' : 'Please check your connection to load maps.',
                        style: const TextStyle(color: Colors.grey),
                      ).animate().fade(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),

          // Controls
          Positioned(
            top: 16,
            right: isArabic ? null : 16,
            left: isArabic ? 16 : null,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Bottom Sheet
          if (_hasInternet)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: _isLoading 
                          ? _buildSkeletonList() 
                          : _mosques.isEmpty 
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _fetchMosquesInView,
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: _mosques.length,
                                  itemBuilder: (context, index) {
                                    final mosque = _mosques[index];
                                    return MosqueCard(
                                      mosque: mosque,
                                      onTap: () {
                                        _mapController.move(mosque.latLng, 16.0);
                                        _mosqueStorage.addRecent(mosque);
                                      },
                                    ).animate().fade(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.2, end: 0);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 200, height: 20, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 16, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(width: 150, height: 16, color: Colors.grey[300]),
              ],
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat())
         .shimmer(duration: 1200.ms, color: Colors.white54);
      },
    );
  }

  Widget _buildEmptyState() {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لم يتم العثور على مساجد في هذه المنطقة' : 'No mosques found in this area',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _mapController.move(_currentMapCenter!, _mapController.camera.zoom - 1);
            },
            icon: const Icon(Icons.zoom_out_map),
            label: Text(isArabic ? 'البحث في نطاق أوسع' : 'Search in larger radius'),
          ),
        ],
      ),
    );
  }
}
