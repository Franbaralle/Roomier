import 'package:flutter/material.dart';
import 'dart:typed_data';
//import 'my_image_picker.dart';
import 'routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal() {
    initializeSharedPreferences();
  }

  late SharedPreferences _prefs;

  Future<void> saveUserData(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      throw Exception('Tipo de dato no compatible con SharedPreferences');
    }
  }

  dynamic loadUserData(String key) {
    return _prefs.get(key);
  }

  // Inicializa SharedPreferences
  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String apiUrl = 'http://localhost:3000/api/auth';
  static const String api = 'http://localhost:3000/api';
  static DateTime? _selectedDate;

  static void setSelectedDate(DateTime date) {
    _selectedDate = date;
  }

  static DateTime? getSelectedDate() {
    return _selectedDate;
  }

  Future<void> login(
      String username, String password, BuildContext context) async {
    try {
      final String loginUrl = '$apiUrl/login';
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Hacer la solicitud del perfil en línea sin asignarla a una variable
        final profileDataResponse = await http.get(
          Uri.parse('$api/profile/$username'),
          // Puedes agregar encabezados u otros parámetros según sea necesario
        );

        // Almacenar el token en SharedPreferences

        if (profileDataResponse.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String token = responseData['token'];
          final profileData = json.decode(profileDataResponse.body);

          await saveUserData('username', username);
          await saveUserData('accessToken', token);
          await saveUserData('profilePhoto', profileData['profilePhoto']);

          Navigator.pushReplacementNamed(
            context,
            homeRoute,
            arguments: {'username': profileData['username']},
          );
        } else {
          print(
              'Error al obtener la información del perfil. Código de estado: ${profileDataResponse.statusCode}');
          // Mostrar un mensaje de error al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al obtener la información del perfil.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print(
            'Inicio de sesión fallido. Código de estado: ${response.statusCode}');
        // Mostrar un mensaje de error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Inicio de sesión fallido. Verifica tus credenciales.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('Error durante el inicio de sesión: $error');
      // Mostrar un mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error durante el inicio de sesión. Inténtalo de nuevo.'),
          duration: Duration(seconds: 3),
        ),
      );
      // Puedes lanzar una excepción aquí si es necesario.
    }
  }

  Future<Map<String, dynamic>?> getUserInfoFromToken(
      String accessToken, String username) async {
    try {
      final String profileUrl = '$api/profile/$username';
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Incluir el token de acceso en los encabezados de autorización
          'username': username
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
            'Error al obtener los datos del perfil del usuario. Código de estado: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error al obtener los datos del perfil del usuario: $error');
      return null;
    }
  }

  Future<void> register(String username, String password, String email,
      DateTime birthdate, BuildContext context) async {
    try {
      final String registerUrl = '$apiUrl/register';
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
          'birthdate': birthdate.toIso8601String()
        }),
      );

      if (response.statusCode == 201) {
        print('Registro exitoso');
      } else {
        print('Error en el registro. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error durante el registro: $error');
    }
  }

  Future<void> resetPassword(String username, String newPassword) async {
    try {
      final String resetPasswordUrl = '$apiUrl/update-password/$username';
      final response = await http.put(
        Uri.parse(resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('Contraseña actualizada exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar la contraseña. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar la contraseña: $error');
    }
  }

  Future<void> updatePreferences(
      String username, List<String> preferences) async {
    try {
      final String updatePreferencesUrl = '$api/register/preferences';
      final response = await http.post(
        Uri.parse(updatePreferencesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'preferences': preferences,
        }),
      );

      if (response.statusCode == 200) {
        print('Preferencias actualizadas exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar las preferencias. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar las preferencias: $error');
    }
  }

  Future<void> updatePersonalInfo(
    String username,
    String job,
    String religion,
    String politicPreference,
    String aboutMe,
  ) async {
    try {
      final String updatePersonalInfoUrl = '$api/register/personal_info';
      final response = await http.post(
        Uri.parse(updatePersonalInfoUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'personalInfo': {
            'job': job,
            'religion': religion,
            'politicPreference': politicPreference,
            'aboutMe': aboutMe,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Información personal actualizada exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar la información personal. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar la información personal: $error');
    }
  }

  Future<void> updateProfilePhoto(
      String username, String email, Uint8List profilePhoto) async {
    try {
      final String updateProfilePhotoUrl = '$api/register/profile_photo';

      var request =
          http.MultipartRequest('POST', Uri.parse(updateProfilePhotoUrl));
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.files.add(
        http.MultipartFile.fromBytes(
          'profilePhoto',
          profilePhoto,
          filename: 'profile_photo.jpg',
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Foto de perfil actualizada exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar la foto de perfil. Status code: ${response.statusCode}');
        print('Response Body: ${await response.stream.bytesToString()}');
      }
    } catch (error) {
      print('Error al actualizar la foto de perfil: $error');
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String username) async {
    try {
      final String userInfoUrl =
          '$api/profile/$username'; // Asegúrate de tener una ruta válida en tu backend
      final response = await http.get(Uri.parse(userInfoUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
            'Error al obtener la información del usuario. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error al obtener la información del usuario: $error');
      return null;
    }
  }

  Future<void> verifyVerificationCode(
      String email, String verificationCode) async {
    try {
      final String verifyCodeUrl = '$api/register/verify';
      print('Verify Code URL: $verifyCodeUrl');
      final response = await http.post(
        Uri.parse(verifyCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      );

      if (response.statusCode == 200) {
        print('Código verificado exitosamente');
      } else {
        print(
            'Error al verificar el código. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error durante la verificación del código: $error');
    }
  }

  Future<List<dynamic>> fetchHomeProfiles() async {
    try {
      final response = await http.get(Uri.parse('$api/home'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch random profiles');
        return [];
      }
    } catch (error) {
      print('Error fetching random profiles: $error');
      return [];
    }
  }

Future<void> updateProfile(
    String username, {
    String? job,
    String? religion,
    String? politicPreference,
    String? aboutMe,
    String? accessToken
  }) async {
    try {
      final String updateProfileUrl = '$api/profile/$username';
      final response = await http.put(
        Uri.parse(updateProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Asegúrate de incluir el token de autenticación en los encabezados
        },
        body: json.encode({
          'job': job,
          'religion': religion,
          'politicPreference': politicPreference,
          'aboutMe': aboutMe,
        }),
      );

      if (response.statusCode == 200) {
        //print('Perfil actualizado correctamente');
      } else {
        print('Error al actualizar el perfil: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al conectar con el servidor: $error');
    }
  }
}
