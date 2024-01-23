import 'package:flutter/material.dart';
import 'package:rommier/login_page.dart';
import 'preferences.dart';

class RegisterPage extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: RegisterForm(
            authService: authService,
          ),
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

  String? usernameError;
  String? passwordError;
  String? emailError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: usernameController,
            decoration: InputDecoration(
                labelText: 'Username', errorText: usernameError),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: passwordError,
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
            decoration:
                InputDecoration(labelText: 'Email', errorText: emailError),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (_validateFields())
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PreferenciasPage()),
              );
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  bool _validateFields() {
    setState(() {
      usernameError = null;
      passwordError = null;
      emailError = null;
    });

    String username = usernameController.text;
    String password = passwordController.text;
    String email = emailController.text;

    bool isValid = true;

    if (username.isEmpty) {
      setState(() {
        usernameError = 'Campo obligatorio';
      });
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = 'Campo obligatorio';
      });
      isValid = false;
    }

    if (email.isEmpty) {
      setState(() {
        emailError = 'Campo obligatorio';
      });
      isValid = false;
    }

    return isValid;
  }

  void _register() async {
    String username = usernameController.text;
    String password = passwordController.text;
    String email = emailController.text;

    try {
      await widget.authService.register(username, password, email, context);
      print('Registro exitoso');
      Navigator.pop(context); // Cierra la página de registro
    } catch (error) {
      print('Error durante el registro: $error');
    }
  }
}
