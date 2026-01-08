import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'analytics_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal() {
    initializeSharedPreferences();
  }

  late SharedPreferences _prefs;
  String? currentUserUsername;

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

  static const String apiUrl = 'https://roomier-production.up.railway.app/api/auth';
  static const String api = 'https://roomier-production.up.railway.app/api';
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
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('TIMEOUT: La conexión tardó demasiado. Verifica tu conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        // Hacer la solicitud del perfil en línea sin asignarla a una variable
        currentUserUsername = username;
        final profileDataResponse = await http.get(
          Uri.parse('$api/profile/$username'),
        ).timeout(
          const Duration(seconds: 10),
        );

        // Almacenar el token en SharedPreferences

        if (profileDataResponse.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String token = responseData['token'];
          final bool isAdmin = responseData['isAdmin'] ?? false;
          final profileData = json.decode(profileDataResponse.body);

          await saveUserData('username', username);
          await saveUserData('accessToken', token);
          await saveUserData('isAdmin', isAdmin);
          await saveUserData('profilePhoto', profileData['profilePhoto']);

          // Track login event
          try {
            final analyticsService = AnalyticsService();
            await analyticsService.trackLogin();
          } catch (e) {
            print('Analytics tracking failed: $e');
          }

          Navigator.pushReplacementNamed(
            context,
            homeRoute,
            arguments: {'username': profileData['username']},
          );
        } else {
          print(
              'Error al obtener la información del perfil. Código de estado: ${profileDataResponse.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cargar el perfil. Intenta nuevamente.'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        // Credenciales incorrectas
        print('Credenciales incorrectas para usuario: $username');
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Usuario o contraseña incorrectos';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red[700],
          ),
        );
      } else if (response.statusCode == 429) {
        // Demasiados intentos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Demasiados intentos. Espera un momento e intenta nuevamente.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (response.statusCode >= 500) {
        // Error del servidor
        print('Error del servidor: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 El servidor está experimentando problemas. Intenta más tarde.'),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.deepOrange,
          ),
        );
      } else {
        // Otro error
        print('Inicio de sesión fallido. Código de estado: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado (${response.statusCode}). Intenta nuevamente.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on http.ClientException catch (error) {
      // Error de conexión (DNS, red, etc.)
      print('Error de conexión: $error');
      String errorMessage = '📡 Sin conexión al servidor';
      
      if (error.toString().contains('Failed host lookup')) {
        errorMessage = '🌐 No se pudo conectar al servidor.\n\nVerifica tu conexión a internet.';
      } else if (error.toString().contains('Connection refused')) {
        errorMessage = '🚫 El servidor no está disponible.';
      } else if (error.toString().contains('Connection timed out')) {
        errorMessage = '⏱️ Tiempo de espera agotado.\n\nVerifica tu conexión.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.blue[900],
          action: SnackBarAction(
            label: 'Entendido',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } on Exception catch (error) {
      // Otros errores (timeout, etc.)
      print('Error durante el inicio de sesión: $error');
      String errorMessage = 'Error de conexión. Verifica tu internet.';
      
      if (error.toString().contains('TIMEOUT')) {
        errorMessage = '⏱️ La conexión tardó demasiado.\n\nVerifica tu conexión a internet.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.indigo[900],
        ),
      );
    } catch (error) {
      // Error genérico
      print('Error inesperado durante el inicio de sesión: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error inesperado. Intenta nuevamente.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Logout: Cierra la sesión y revoca el token en el servidor
  Future<bool> logout(BuildContext context) async {
    try {
      final String? accessToken = _prefs.getString('accessToken');
      
      if (accessToken != null) {
        // Llamar al endpoint de logout para agregar el token a la blacklist
        final String logoutUrl = '$apiUrl/logout';
        try {
          final response = await http.post(
            Uri.parse(logoutUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('TIMEOUT');
            },
          );

          if (response.statusCode == 200) {
            print('Token agregado a blacklist exitosamente');
          } else {
            print('Error al revocar token en servidor: ${response.statusCode}');
            // Continuar con logout local aunque falle el servidor
          }
        } catch (e) {
          print('Error al contactar servidor para logout: $e');
          // Continuar con logout local aunque falle el servidor
        }
      }

      // Limpiar datos locales
      await _prefs.remove('accessToken');
      await _prefs.remove('username');
      await _prefs.remove('isAdmin');
      await _prefs.remove('profilePhoto');
      currentUserUsername = null;

      return true;
    } catch (error) {
      print('Error durante el logout: $error');
      return false;
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

  // Método para completar el registro con todos los datos a la vez
  Future<Map<String, dynamic>> completeRegistration(Map<String, dynamic> registrationData) async {
    try {
      // Usar ruta correcta para el endpoint de registro completo
      final String completeRegisterUrl = 'https://roomier-production.up.railway.app/api/register/complete';
      final response = await http.post(
        Uri.parse(completeRegisterUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      if (response.statusCode == 201) {
        print('Registro completo exitoso');
        return json.decode(response.body);
      } else {
        print('Error en el registro completo. Status code: ${response.statusCode}');
        throw Exception('Error en el registro: ${response.body}');
      }
    } catch (error) {
      print('Error durante el registro completo: $error');
      rethrow;
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
      String username, Map<String, Map<String, List<String>>> preferences) async {
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

  Future<void> updateRoommatePreferences(
    String username,
    String gender,
    int ageMin,
    int ageMax,
  ) async {
    try {
      final String updateRoommatePreferencesUrl = '$api/register/roommate-preferences';
      final response = await http.post(
        Uri.parse(updateRoommatePreferencesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'gender': gender,
          'ageMin': ageMin,
          'ageMax': ageMax,
        }),
      );

      if (response.statusCode == 200) {
        print('Preferencias de roommate actualizadas exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar las preferencias de roommate. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar las preferencias de roommate: $error');
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

  Future<void> updateLivingHabits(
    String username,
    Map<String, dynamic> livingHabitsData,
    Map<String, dynamic> dealBreakersData,
  ) async {
    try {
      final String updateLivingHabitsUrl = '$api/register/living_habits';
      final response = await http.post(
        Uri.parse(updateLivingHabitsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'livingHabits': livingHabitsData,
          'dealBreakers': dealBreakersData,
        }),
      );

      if (response.statusCode == 200) {
        print('Hábitos de convivencia actualizados exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar hábitos de convivencia. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar hábitos de convivencia: $error');
      throw error;
    }
  }

  Future<void> updateHousingInfo(
    String username,
    Map<String, dynamic> housingInfoData,
  ) async {
    try {
      final String updateHousingInfoUrl = '$api/register/housing_info';
      final response = await http.post(
        Uri.parse(updateHousingInfoUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'housingInfo': housingInfoData,
        }),
      );

      if (response.statusCode == 200) {
        print('Información de vivienda actualizada exitosamente');
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
      } else {
        print(
            'Error al actualizar información de vivienda. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar información de vivienda: $error');
      throw error;
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
      // Obtener el username actual
      final currentUsername = await loadUserData('username');
      
      if (currentUsername == null) {
        print('No hay usuario actual');
        return [];
      }

      final response = await http.get(
        Uri.parse('$api/home?currentUser=$currentUsername')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch profiles: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching profiles: $error');
      return [];
    }
  }

  Future<List<dynamic>> fetchReceivedLikes(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$api/home/received-likes?currentUser=$username')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch received likes: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching received likes: $error');
      return [];
    }
  }

  Future<void> updateProfile(String username,
      {String? job,
      String? religion,
      String? politicPreference,
      String? aboutMe,
      String? accessToken}) async {
    try {
      final String updateProfileUrl = '$api/profile/$username';
      final response = await http.put(
        Uri.parse(updateProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Asegúrate de incluir el token de autenticación en los encabezados
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

  Future<void> matchProfile(
      String username, bool addToIsMatch, String accessToken, String currentUserUsername) async {
    try {
      final String matchProfileUrl = '$api/profile/match_profile/$username';
      final response = await http.post(
        Uri.parse(matchProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'isMatched': addToIsMatch,
          'currentUserUsername': currentUserUsername
        }), // Aquí se envía correctamente el valor isMatched
      );

      if (response.statusCode == 200) {
        print('Perfil actualizado correctamente');
      } else {
        print('Error al actualizar el perfil: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al conectar con el servidor: $error');
    }
  }

  Future<bool> checkMatch(String accessToken, String username, String currentUserUsername) async {
    try {
      final String matchCheckUrl = '$api/profile/check_match/$username';
      final response = await http.post(
        Uri.parse(matchCheckUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'currentUserUsername': currentUserUsername,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['isMatch'];
      } else {
        print('Error al verificar la coincidencia: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Error al conectar con el servidor: $error');
      return false;
    }
  }

  Future<bool> unmatchProfile(String username, String currentUserUsername) async {
    try {
      final String unmatchUrl = '$api/profile/unmatch/$username';
      final response = await http.post(
        Uri.parse(unmatchUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentUserUsername': currentUserUsername,
        }),
      );

      if (response.statusCode == 200) {
        print('Match deshecho correctamente');
        return true;
      } else {
        print('Error al deshacer el match: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Error al conectar con el servidor: $error');
      return false;
    }
  }

  Future<bool> revealInformation(
    String currentUsername,
    String matchedUsername,
    String infoType,
  ) async {
    try {
      final String revealInfoUrl = '$api/profile/reveal_info';
      final response = await http.post(
        Uri.parse(revealInfoUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentUsername': currentUsername,
          'matchedUsername': matchedUsername,
          'infoType': infoType, // 'zones', 'budget', 'contact'
        }),
      );

      if (response.statusCode == 200) {
        print('Información revelada correctamente');
        return true;
      } else {
        print('Error al revelar información: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Error al conectar con el servidor: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>> reportUser({
    required String reportedUsername,
    required String reason,
    required String description,
  }) async {
    try {
      final String? token = loadUserData('accessToken');
      if (token == null) {
        return {'success': false, 'message': 'No hay token de autenticación'};
      }

      final String reportUrl = '$api/moderation/report';
      final response = await http.post(
        Uri.parse(reportUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reportedUsername': reportedUsername,
          'reason': reason,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Reporte enviado correctamente'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al enviar el reporte'};
      }
    } catch (error) {
      print('Error al reportar usuario: $error');
      return {'success': false, 'message': 'Error al conectar con el servidor'};
    }
  }

  Future<Map<String, dynamic>> blockUser(String blockedUsername) async {
    try {
      final String? token = loadUserData('accessToken');
      if (token == null) {
        return {'success': false, 'message': 'No hay token de autenticación'};
      }

      final String blockUrl = '$api/moderation/block';
      final response = await http.post(
        Uri.parse(blockUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'blockedUsername': blockedUsername,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario bloqueado correctamente'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al bloquear el usuario'};
      }
    } catch (error) {
      print('Error al bloquear usuario: $error');
      return {'success': false, 'message': 'Error al conectar con el servidor'};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String blockedUsername) async {
    try {
      final String? token = loadUserData('accessToken');
      if (token == null) {
        return {'success': false, 'message': 'No hay token de autenticación'};
      }

      final String unblockUrl = '$api/moderation/unblock';
      final response = await http.post(
        Uri.parse(unblockUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'blockedUsername': blockedUsername,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario desbloqueado correctamente'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al desbloquear el usuario'};
      }
    } catch (error) {
      print('Error al desbloquear usuario: $error');
      return {'success': false, 'message': 'Error al conectar con el servidor'};
    }
  }
}
