import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Models a saved annotation record for persistent storage
class SavedAnnotationRecord {
  final String id;
  final String type; // 'highlight' or 'underline'
  final int colorValue;
  final int pageNumber;
  final String selectedText;
  final int createdAt;
  final List<Map<String, dynamic>> lines;

  SavedAnnotationRecord({
    required this.id,
    required this.type,
    required this.colorValue,
    required this.pageNumber,
    required this.selectedText,
    required this.createdAt,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'colorValue': colorValue,
        'pageNumber': pageNumber,
        'selectedText': selectedText,
        'createdAt': createdAt,
        'lines': lines,
      };

  factory SavedAnnotationRecord.fromJson(Map<String, dynamic> json) =>
      SavedAnnotationRecord(
        id: json['id'] as String? ?? UniqueKey().toString(),
        type: json['type'] as String? ?? 'highlight',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFFFE082,
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
        selectedText: json['selectedText'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        lines: (json['lines'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
}

class PdfAnnotationService {
  static final PdfAnnotationService _instance = PdfAnnotationService._internal();
  factory PdfAnnotationService() => _instance;
  PdfAnnotationService._internal();

  Directory? _annotationsDir;

  Future<Directory> _getAnnotationsDir() async {
    if (_annotationsDir != null && await _annotationsDir!.exists()) {
      return _annotationsDir!;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'imported_books', 'annotations'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _annotationsDir = dir;
    return dir;
  }

  File _getAnnotationFile(Directory dir, int bookId) {
    return File(p.join(dir.path, 'book_${bookId}_annotations.json'));
  }

  /// Loads all persistent annotations for a given book and reconstructs Syncfusion Annotation objects.
  Future<List<Annotation>> loadAnnotations(int bookId) async {
    try {
      final dir = await _getAnnotationsDir();
      final file = _getAnnotationFile(dir, bookId);
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      final List<Annotation> results = [];

      for (final raw in jsonList) {
        if (raw is! Map<String, dynamic>) continue;
        final record = SavedAnnotationRecord.fromJson(raw);

        final textLines = record.lines.map((line) {
          final double left = (line['left'] as num).toDouble();
          final double top = (line['top'] as num).toDouble();
          final double right = (line['right'] as num).toDouble();
          final double bottom = (line['bottom'] as num).toDouble();
          final String text = line['text'] as String? ?? '';
          final int pageNumber = (line['pageNumber'] as num?)?.toInt() ?? record.pageNumber;

          return PdfTextLine(
            Rect.fromLTRB(left, top, right, bottom),
            text,
            pageNumber,
          );
        }).toList();

        if (textLines.isEmpty) continue;

        if (record.type == 'underline') {
          final underline = UnderlineAnnotation(textBoundsCollection: textLines);
          underline.color = Color(record.colorValue);
          underline.subject = record.id;
          results.add(underline);
        } else {
          final highlight = HighlightAnnotation(textBoundsCollection: textLines);
          highlight.color = Color(record.colorValue);
          highlight.subject = record.id;
          results.add(highlight);
        }
      }

      return results;
    } catch (e) {
      debugPrint('[PdfAnnotationService] Error loading annotations: $e');
      return [];
    }
  }

  /// Saves a new highlight or underline annotation persistently to disk.
  Future<String> saveAnnotation({
    required int bookId,
    required String type, // 'highlight' or 'underline'
    required List<PdfTextLine> lines,
    required Color color,
    String? selectedText,
  }) async {
    if (lines.isEmpty) return '';

    final annotationId = '${DateTime.now().millisecondsSinceEpoch}_${lines.first.pageNumber}';

    try {
      final dir = await _getAnnotationsDir();
      final file = _getAnnotationFile(dir, bookId);

      List<SavedAnnotationRecord> existing = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          existing = jsonList
              .whereType<Map<String, dynamic>>()
              .map(SavedAnnotationRecord.fromJson)
              .toList();
        }
      }

      final serializableLines = lines.map((line) => {
            'left': line.bounds.left,
            'top': line.bounds.top,
            'right': line.bounds.right,
            'bottom': line.bounds.bottom,
            'text': line.text,
            'pageNumber': line.pageNumber,
          }).toList();

      final combinedText = selectedText ?? lines.map((l) => l.text).join(' ');

      final newRecord = SavedAnnotationRecord(
        id: annotationId,
        type: type,
        colorValue: color.toARGB32(),
        pageNumber: lines.first.pageNumber,
        selectedText: combinedText,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lines: serializableLines,
      );

      existing.add(newRecord);

      final updatedJson = jsonEncode(existing.map((e) => e.toJson()).toList());
      await file.writeAsString(updatedJson, flush: true);
    } catch (e) {
      debugPrint('[PdfAnnotationService] Error saving annotation: $e');
    }
    return annotationId;
  }

  /// Removes an annotation matching the annotation's unique subject ID or page number.
  Future<void> removeAnnotation(int bookId, Annotation annotation) async {
    try {
      final dir = await _getAnnotationsDir();
      final file = _getAnnotationFile(dir, bookId);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      final List<dynamic> jsonList = jsonDecode(content);
      final records = jsonList
          .whereType<Map<String, dynamic>>()
          .map(SavedAnnotationRecord.fromJson)
          .toList();

      final targetId = annotation.subject;

      if (targetId != null && targetId.isNotEmpty) {
        records.removeWhere((rec) => rec.id == targetId);
      } else {
        // Fallback: match by page number and creation if subject wasn't set
        records.removeWhere((rec) => rec.pageNumber == annotation.pageNumber);
      }

      final updatedJson = jsonEncode(records.map((e) => e.toJson()).toList());
      await file.writeAsString(updatedJson, flush: true);
    } catch (e) {
      debugPrint('[PdfAnnotationService] Error removing annotation: $e');
    }
  }

  /// Deletes all saved annotations for a book when the book is deleted.
  Future<void> deleteAnnotationsForBook(int bookId) async {
    try {
      final dir = await _getAnnotationsDir();
      final file = _getAnnotationFile(dir, bookId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
