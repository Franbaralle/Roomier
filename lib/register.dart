import 'package:flutter/material.dart';
import 'package:rommier/login_page.dart';
import 'preferences.dart';


class RegisterPage extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: RegisterForm(authService: authService,),
        ),
      ),
    );
  }
}

// En register.dart

class RegisterForm extends StatefulWidget {
  final AuthService authService;

  RegisterForm({required this.authService});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child:TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PreferenciasPage()),
            );
          },
          child: Text('Continuar'),
        ),
      ],
    );
  }

  void _register() async {
    // Obtener los valores de los controladores
    String username = usernameController.text;
    String password = passwordController.text;
    String email = emailController.text;

    // Validar que los campos no estén vacíos (puedes agregar más validaciones según tus necesidades)
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      // Muestra un mensaje de error o realiza alguna acción si los campos están vacíos
      print('Por favor, complete todos los campos.');
      return;
    }

    // Llamar a la función de registro en el AuthService
    try {
      await widget.authService.register(username, password, email, context);

      // Registro exitoso
      print('Registro exitoso');

      // Puedes realizar otras acciones aquí después del registro exitoso, como navegar a otra página.
      Navigator.pop(context); // Cierra la página de registro
    } catch (error) {
      // Manejar errores durante el registro
      print('Error durante el registro: $error');
      // Puedes mostrar un mensaje de error al usuario o realizar alguna otra acción según tus necesidades.
    }
  }
}