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
    // Dimensiones responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06; // 6% padding
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    final logoSize = screenWidth * 0.2; // 20% del ancho
    final titleFontSize = screenWidth * 0.07; // 7% del ancho
    final subtitleFontSize = screenWidth * 0.035; // 3.5% del ancho
    final buttonHeight = screenHeight * 0.06; // 6% de la altura
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.all(padding * 1.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Image.asset(
                        'assets/ChatGPT Image 5 ene 2026, 08_41_59.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  SizedBox(height: screenHeight * 0.01),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        authService.login(
                          usernameController.text,
                          passwordController.text,
                          context,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: BoxConstraints(minHeight: buttonHeight),
                          child: Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: subtitleFontSize * 1.2, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Text(
                          'o',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, genderSelectionRoute);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB7A7E3), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: subtitleFontSize * 1.2,
                          color: Color(0xFFB7A7E3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, termsRoute);
                        },
                        child: const Text(
                          'Términos y Condiciones',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(' | ', style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, privacyRoute);
                        },
                        child: const Text(
                          'Política de Privacidad',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
