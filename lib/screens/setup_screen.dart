import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../core/database/database_helper.dart';
import 'main_navigation_screen.dart';

/// Top-level worker executed in background isolate via compute.
/// Being top-level ensures it captures no class, BuildContext, or WidgetsBinding state.
Future<bool> _extractDatabaseZip(Map<String, dynamic> params) async {
  final Uint8List bytes = params['bytes'] as Uint8List;
  final String dbFileDest = params['dbFileDest'] as String;
  final String tempDest = params['tempDest'] as String;

  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive) {
    if (file.isFile && file.name.endsWith('.db')) {
      final extractedData = file.content as List<int>;
      final tmpFile = File(tempDest);
      await tmpFile.writeAsBytes(extractedData, flush: true);
      if (await tmpFile.exists() && await tmpFile.length() > 5 * 1024 * 1024) {
        final destFile = File(dbFileDest);
        if (await destFile.exists()) {
          await destFile.delete();
        }
        await tmpFile.rename(dbFileDest);
        return true;
      }
      break;
    }
  }
  return false;
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _statusMessage = 'Setting up your offline Islamic library...\nPlease wait a moment.';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Start setup after first frame render
    Future.delayed(const Duration(milliseconds: 300), _startSetupProcess);
  }

  Future<void> _startSetupProcess() async {
    try {
      // 1. Load the zip file from assets
      final assetData = await rootBundle.load('assets/muslim_house.zip');
      final bytes = assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      );

      // 2. Prepare the destination directory
      final docDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(p.join(docDir.path, 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      final dbFileDest = p.join(dbDir.path, 'muslim_house.db');
      final tempDest = '$dbFileDest.tmp';

      // 3. Decode the zip in a background isolate so low-end devices do not freeze or ANR
      final success = await compute(_extractDatabaseZip, {
        'bytes': bytes,
        'dbFileDest': dbFileDest,
        'tempDest': tempDest,
      });

      if (!success) {
        throw Exception('Database file was not successfully extracted.');
      }

      // 4. Initialize the Database so it's ready for the app
      await DatabaseHelper.instance.init();

      // Buffer to allow GC memory to settle before route transition
      await Future.delayed(const Duration(milliseconds: 250));

      // 5. Navigate to Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      debugPrint('Setup error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Error setting up database: $e\nPlease click Retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4F3C), // Matching Islamic theme green
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.library_books_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Initial Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                if (!_hasError)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _statusMessage =
                            'Setting up your offline Islamic library...\nPlease wait a moment.';
                      });
                      _startSetupProcess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF0D4F3C),
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
