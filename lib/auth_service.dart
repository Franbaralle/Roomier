import 'package:flutter/material.dart';
import 'my_image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String apiUrl = 'http://localhost:3000/api/auth';
  static DateTime? _selectedDate;

  static void setSelectedDate(DateTime date) {
    _selectedDate = date;
  }

  static DateTime? getSelectedDate(){
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
        print('Login successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyImagePickerPage()),
        );
      } else {
        print('Login failed. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during login: $error');
      // Puedes lanzar una excepción aquí si es necesario.
    }
  }


  Future<void> register(String username, String password, String email, DateTime birthdate,
      BuildContext context) async {
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
      print('Error al actualizar la contraseña. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }
  } catch (error) {
    print('Error al actualizar la contraseña: $error');
  }
}
}
