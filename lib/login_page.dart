import 'package:flutter/material.dart';
import 'routes.dart';
import 'auth_service.dart';


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
                // Guarda el nombre de usuario en el controlador
                usernameController.text = value;
              },
              decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
            ),
            TextField(
              // Asegúrate de que newPasswordController esté definido previamente
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Verifica si el nombre de usuario y la nueva contraseña no están vacíos
              if (usernameController.text.isNotEmpty && newPasswordController.text.isNotEmpty) {
                // Llama a la función resetPassword con los datos ingresados
                authService.resetPassword(
                    usernameController.text,
                    newPasswordController.text);
              } else {
                // Muestra un mensaje si falta información
                print("Por favor, ingrese el nombre de usuario y la nueva contraseña");
              }
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text('Restablecer'),
          ),
        ],
      );
    },
  );
}
}
