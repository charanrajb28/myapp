import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FileSaver {
  /// Saves or shares the file based on the platform.
  /// [fileName] is the suggested file name (e.g. 'export.csv')
  /// [content] is the file content as String (for CSV)
  /// [bytes] is the file content as bytes (for Excel/PDF/Binary files)
  static Future<String?> saveAndShareFile({
    required String fileName,
    String? content,
    List<int>? bytes,
  }) async {
    if (kIsWeb) {
      // For web, handled via browser actions
      return null;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platform: Write to a temporary file and invoke Share sheet
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
      } else if (content != null) {
        await file.writeAsString(content, flush: true);
      }
      
      // Share file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Exported File: $fileName',
        ),
      );
      return file.path;
    } else {
      // Desktop platform (Windows, macOS, Linux): Save file dialog
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
      );
      if (result == null) return null;

      final file = File(result.path);
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
      } else if (content != null) {
        await file.writeAsString(content, flush: true);
      }
      return result.path;
    }
  }

  /// Downloads the file from a [url] on mobile and shows share sheet, or launches [url] in browser as a fallback.
  static Future<void> downloadOrLaunchUrl(BuildContext context, String url, String fileName) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid document link.')),
      );
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final lowerUrl = url.toLowerCase();
      final isGoogleDrive = lowerUrl.contains('drive.google.com') || lowerUrl.contains('docs.google.com');

      if (!isGoogleDrive) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading file...'), duration: Duration(seconds: 2)),
          );
          final response = await http.get(uri);
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            // Try to extract extension from mime-type or path
            String ext = '';
            if (!fileName.contains('.')) {
              final mimeType = response.headers['content-type']?.toLowerCase() ?? '';
              if (mimeType.contains('pdf')) {
                ext = '.pdf';
              } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
                ext = '.xlsx';
              } else if (mimeType.contains('csv')) {
                ext = '.csv';
              } else if (mimeType.contains('png')) {
                ext = '.png';
              } else if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
                ext = '.jpg';
              }
            }
            final file = File('${tempDir.path}/$fileName$ext');
            await file.writeAsBytes(response.bodyBytes, flush: true);
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                text: fileName,
              ),
            );
            return;
          }
        } catch (e) {
          debugPrint('Direct download failed, falling back to browser launch: $e');
        }
      }
    }

    // Google Drive URLs / Desktop / Web / Fallback
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open document.')),
      );
    }
  }
}
