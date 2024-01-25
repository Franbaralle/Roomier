import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rommier/my_image_picker.dart';
import 'date.dart';
import 'dart:convert';
import 'routes.dart';

class AuthService {
  static const String apiUrl = 'http://localhost:3000/api/auth';

  Future<void> login(
      String username, String password, BuildContext context) async {
    final String loginUrl = '$apiUrl/login';

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // La solicitud fue exitosa
        print('Login successful');

        // Navegar a la página MyImagePicker
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyImagePickerPage()),
        );
      } else {
        // La solicitud no fue exitosa
        print('Login failed. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during login: $error');
    }
  }

  Future<void> register(String username, String password, String email,
      BuildContext context) async {
    final String registerUrl = '$apiUrl/register';

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        // Registro exitoso
        print('Registro exitoso');

        // Puedes navegar a la página de inicio de sesión o realizar alguna otra acción.
      } else {
        // Error en el registro
        print('Error en el registro. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error durante el registro: $error');
    }
  }

  Future<void> resetPassword(String username, String newPassword,
      TextEditingController usernameController) async {
    print('Username:$username');
    final String resetPasswordUrl = '$apiUrl/update-password/$username';

    print('Reset Password URL: $resetPasswordUrl');
    print('New Password: $newPassword');

    try {
      final response = await http.put(
        Uri.parse(resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('Contraseña actualizada exitosamente');
      } else {
        print('Error al actualizar la contraseña: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Error al actualizar la contraseña: $error');
    }
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController profileNameController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool obscurePassword = true;

  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    // Otros inicializadores de controladores si los hay
  }

  @override
  void dispose() {
    usernameController.dispose();
    // Otros disposers de controladores si los hay
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300, // Ajusta este valor según tus necesidades
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: obscurePassword,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    authService.login(
                      usernameController.text,
                      passwordController.text,
                      context,
                    );
                  },
                  child: const Text('Iniciar Sesión'),
                ),
                SizedBox(width: 10), // Espacio entre los botones
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                    registerDateRoute
                    );
                  },
                  child: const Text('Crear Cuenta'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('¿Haz olvidado tu contraseña?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DatePage()),
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restablecer Contraseña'),
          content: Column(
            children: [
              TextField(
                onChanged: (value) {
                  usernameController.text = value;
                },
                controller: profileNameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre de Perfil'),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nueva Contraseña'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty) {
                  authService.resetPassword(profileNameController.text,
                      newPasswordController.text, usernameController);
                } else {
                  print("El nombre de usuario no puede venir vacio");
                }
                Navigator.of(context).pop();
              },
              child: const Text('Restablecer'),
            ),
          ],
        );
      },
    );
  }
}
