import 'dart:typed_data';

import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.6:8000/api";
  final Dio _dio = Dio();

  Future<List<dynamic>> getTemplates() async {
    final response = await _dio.get("$baseUrl/templates/");
    return response.data;
  }

  Future<void> saveEdit(int templateId, Map<String, dynamic> editedJson) async {
    await _dio.post(
      "$baseUrl/templates/edit/",
      data: {
        "template": templateId,
        "user_id": "user123",
        "edited_json": editedJson,
      },
    );
  }

  String getPreviewUrl(int templateId) {
    return "$baseUrl/preview/$templateId/";
  }

  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        "$baseUrl/upload/",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<List<int>> generatePreviewImage(
    int templateId,
    Map<String, dynamic> editedJson,
  ) async {
    _dio.options.responseType = ResponseType.bytes;
    final response = await _dio.post(
      getPreviewUrl(templateId),
      data: {
        'template_id': templateId,
        'edited_json': editedJson,
      },
    );

    if (response.statusCode == 200) {
      return Uint8List.fromList(response.data);
    } else {
      throw Exception('Failed to generate preview image');
    }
  }
}

final apiService = ApiService();
