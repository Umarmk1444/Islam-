import 'package:url_launcher/url_launcher.dart';

/// Opens the native Google Maps app (or web browser fallback) 
/// searching for nearby mosques using LaunchMode.externalApplication.
Future<bool> findNearestMosques() async {
  final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=mosques');
  return await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );
}
