import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadImage(File file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary is not configured. Set cloud name and unsigned upload preset first.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = json['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload did not return a secure URL.');
    }

    return secureUrl;
  }
}
