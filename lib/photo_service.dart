import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class PhotoService {
  static const String apiUrl = 'https://roomier-production.up.railway.app/api/photos';

  // ======== FOTOS DE PERFIL ========

  /// Subir múltiples fotos de perfil (hasta 10)
  static Future<Map<String, dynamic>> uploadProfilePhotos(
    String username,
    List<Uint8List> photoDataList,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/profile'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = username;

      // Agregar cada foto al request
      for (var i = 0; i < photoDataList.length; i++) {
        var multipartFile = http.MultipartFile.fromBytes(
          'photos',
          photoDataList[i],
          filename: 'profile_photo_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Error al subir fotos: ${response.statusCode} - $responseBody');
      }
    } catch (error) {
      print('Error en uploadProfilePhotos: $error');
      rethrow;
    }
  }

  /// Obtener todas las fotos de perfil de un usuario
  static Future<List<Map<String, dynamic>>> getProfilePhotos(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile/$username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['photos']);
      } else {
        throw Exception('Error al obtener fotos: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en getProfilePhotos: $error');
      rethrow;
    }
  }

  /// Eliminar una foto de perfil
  static Future<void> deleteProfilePhoto(String publicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/profile/$publicId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar foto: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en deleteProfilePhoto: $error');
      rethrow;
    }
  }

  /// Establecer una foto como principal
  static Future<void> setPrimaryPhoto(String publicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/profile/$publicId/primary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al establecer foto principal: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en setPrimaryPhoto: $error');
      rethrow;
    }
  }

  // ======== FOTOS DEL HOGAR ========

  /// Subir múltiples fotos del hogar
  static Future<Map<String, dynamic>> uploadHomePhotos(
    String username,
    List<Uint8List> photoDataList,
    List<String>? descriptions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/home'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = username;

      // Agregar descripciones si existen
      if (descriptions != null && descriptions.isNotEmpty) {
        request.fields['descriptions'] = json.encode(descriptions);
      }

      // Agregar cada foto al request
      for (var i = 0; i < photoDataList.length; i++) {
        var multipartFile = http.MultipartFile.fromBytes(
          'photos',
          photoDataList[i],
          filename: 'home_photo_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Error al subir fotos del hogar: ${response.statusCode} - $responseBody');
      }
    } catch (error) {
      print('Error en uploadHomePhotos: $error');
      rethrow;
    }
  }

  /// Obtener todas las fotos del hogar de un usuario
  static Future<List<Map<String, dynamic>>> getHomePhotos(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/home/$username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['photos']);
      } else {
        throw Exception('Error al obtener fotos del hogar: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en getHomePhotos: $error');
      rethrow;
    }
  }

  /// Eliminar una foto del hogar
  static Future<void> deleteHomePhoto(String publicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/home/$publicId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar foto del hogar: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en deleteHomePhoto: $error');
      rethrow;
    }
  }

  /// Actualizar descripción de una foto del hogar
  static Future<void> updateHomePhotoDescription(String publicId, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/home/$publicId/description'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'description': description}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar descripción: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en updateHomePhotoDescription: $error');
      rethrow;
    }
  }
}
