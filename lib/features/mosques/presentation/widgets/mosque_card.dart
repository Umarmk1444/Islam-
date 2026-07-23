import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/mosque_model.dart';
import '../../data/mosque_storage.dart';

class MosqueCard extends StatefulWidget {
  final Mosque mosque;
  final VoidCallback onTap;

  const MosqueCard({
    Key? key,
    required this.mosque,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MosqueCard> createState() => _MosqueCardState();
}

class _MosqueCardState extends State<MosqueCard> {
  final MosqueStorage _storage = MosqueStorage();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.mosque.isFavorite;
  }

  void _toggleFavorite() async {
    await _storage.toggleFavorite(widget.mosque);
    setState(() {
      _isFavorite = widget.mosque.isFavorite;
    });
  }

  void _copyCoordinates() {
    Clipboard.setData(ClipboardData(text: '${widget.mosque.lat}, ${widget.mosque.lon}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied to clipboard')),
    );
  }

  void _shareMosque() {
    Share.share('Check out ${widget.mosque.name} at https://maps.google.com/?q=${widget.mosque.lat},${widget.mosque.lon}');
  }

  void _openStreetView() async {
    final url = Uri.parse('google.streetview:cbll=${widget.mosque.lat},${widget.mosque.lon}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${widget.mosque.lat},${widget.mosque.lon}');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatDistance() {
    if (widget.mosque.displayDistanceMeters > 1000) {
      return '${(widget.mosque.displayDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${widget.mosque.displayDistanceMeters.toStringAsFixed(0)} m';
  }

  String _formatTime(double? seconds) {
    if (seconds == null) return '';
    final int mins = (seconds / 60).round();
    if (mins > 60) {
      final int hrs = mins ~/ 60;
      final int remainingMins = mins % 60;
      return '${hrs}h ${remainingMins}m';
    }
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.mosque.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Distance & Times Row
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(),
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                    if (widget.mosque.osrmDistanceMeters == null) ...[
                      const SizedBox(width: 8),
                      const Text('(Approximate)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    if (widget.mosque.osrmWalkingDurationSeconds != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(widget.mosque.osrmWalkingDurationSeconds),
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (widget.mosque.osrmDrivingDurationSeconds != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.directions_car, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(widget.mosque.osrmDrivingDurationSeconds),
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(Icons.copy, 'Copy', _copyCoordinates),
                  _buildActionButton(Icons.share, 'Share', _shareMosque),
                  _buildActionButton(Icons.streetview, 'Street View', _openStreetView),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
