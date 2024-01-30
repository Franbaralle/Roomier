import 'package:flutter/material.dart';
import 'routes.dart';
import 'auth_service.dart';

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
              _registerWithAuthService();
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

  void _registerWithAuthService() async {
    if (_validateFields()) {
      try {
        String username = usernameController.text;
        String password = passwordController.text;
        String email = emailController.text;

        await widget.authService.register(
            username, password, email, AuthService.getSelectedDate()!, context);
        Navigator.pushNamed(context, registerPreferencesRoute, arguments: {'username': usernameController.text});
      } catch (error) {
        print('Error durante el registro: $error');
      }
    }
  }
}
