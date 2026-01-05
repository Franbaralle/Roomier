import 'package:flutter/material.dart';
import 'routes.dart';
import 'auth_service.dart';

class RegisterPage extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
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
  bool acceptedTerms = false;

  String? usernameError;
  String? passwordError;
  String? emailError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/ChatGPT Image 5 ene 2026, 08_41_59.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa los datos para comenzar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  hintText: 'Elige un nombre de usuario',
                  errorText: usernameError,
                  prefixIcon: const Icon(Icons.account_circle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                  errorText: emailError,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Mínimo 6 caracteres',
                  errorText: passwordError,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Checkbox de términos y condiciones
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        acceptedTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          acceptedTerms = !acceptedTerms;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/legal/terms');
                                  },
                                  child: const Text(
                                    'Términos y Condiciones',
                                    style: TextStyle(
                                      color: Color(0xFFB7A7E3),
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' y la '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/legal/privacy');
                                  },
                                  child: const Text(
                                    'Política de Privacidad',
                                    style: TextStyle(
                                      color: Color(0xFFB7A7E3),
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: acceptedTerms ? () {
                    _registerWithAuthService();
                  } : null,
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
                      gradient: acceptedTerms ? const LinearGradient(
                        colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ) : null,
                      color: acceptedTerms ? null : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 50),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        
        // Verificar que la fecha de nacimiento esté seleccionada
        DateTime? birthdate = AuthService.getSelectedDate();
        if (birthdate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Fecha de nacimiento no seleccionada'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await widget.authService.register(
            username, password, email, birthdate, context);
        Navigator.pushNamed(context, registerPreferencesRoute, arguments: {'username': usernameController.text, 'email': emailController.text});
      } catch (error) {
        print('Error durante el registro: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error durante el registro: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
