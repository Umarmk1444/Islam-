import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/database/database_helper.dart';
import 'main_navigation_screen.dart';

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
      // 1. Prepare destination directory using getApplicationDocumentsDirectory
      final docDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(p.join(docDir.path, 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      final dbFileDest = p.join(dbDir.path, 'muslim_house.db');
      final tempDest = p.join(dbDir.path, 'muslim_house_temp.db');

      // 2. Protect existing user data: if already valid (> 50 MB), never overwrite!
      final existingFile = File(dbFileDest);
      if (await existingFile.exists() && await existingFile.length() > 50 * 1024 * 1024) {
        _navigateToHome();
        return;
      }

      // 3. Clean up any stale temp file
      final tempFile = File(tempDest);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // 4. Directly load raw asset bytes and stream to temp file (non-blocking, no isolate needed)
      final byteData = await rootBundle.load('assets/muslim_house.db');
      await tempFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );

      // 5. Verify integrity (> 50 MB) and atomically rename to final destination
      if (await tempFile.exists() && await tempFile.length() > 50 * 1024 * 1024) {
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
        await tempFile.rename(dbFileDest);
      } else {
        throw Exception('Database file was incomplete or corrupted.');
      }

      // 6. Initialize the Database so it's ready for the app
      await DatabaseHelper.instance.init();

      // Buffer to allow GC memory to settle before route transition
      await Future.delayed(const Duration(milliseconds: 250));

      if (mounted) {
        _navigateToHome();
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

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
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
