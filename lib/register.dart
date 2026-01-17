import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: RegisterForm(
              authService: authService,
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    final logoSize = screenWidth * 0.15;
    final titleFontSize = screenWidth * 0.06;
    final subtitleFontSize = screenWidth * 0.035;
    final buttonHeight = screenHeight * 0.06;
    final spacingSmall = screenHeight * 0.01;
    final spacingMedium = screenHeight * 0.02;
    final spacingLarge = screenHeight * 0.03;
    
    return Padding(
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
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(padding * 0.5),
                child: Image.asset(
                  'assets/ChatGPT Image 5 ene 2026, 08_41_59.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: spacingMedium),
              Text(
                'Crea tu cuenta',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacingSmall),
              Text(
                'Completa los datos para comenzar',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: spacingLarge * 1.1),
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
              SizedBox(height: spacingMedium),
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
              SizedBox(height: spacingMedium),
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
              SizedBox(height: spacingLarge),
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
                        padding: EdgeInsets.only(top: spacingSmall * 1.2),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: subtitleFontSize * 0.95,
                              color: Colors.grey[700],
                            ),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, termsRoute);
                                  },
                                  child: Text(
                                    'Términos y Condiciones',
                                    style: TextStyle(
                                      color: Color(0xFFB7A7E3),
                                      decoration: TextDecoration.underline,
                                      fontSize: subtitleFontSize * 0.95,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' y la '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, privacyRoute);
                                  },
                                  child: Text(
                                    'Política de Privacidad',
                                    style: TextStyle(
                                      color: Color(0xFFB7A7E3),
                                      decoration: TextDecoration.underline,
                                      fontSize: subtitleFontSize * 0.95,
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
              SizedBox(height: spacingSmall),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
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
                      constraints: BoxConstraints(minHeight: buttonHeight),
                      child: Text(
                        'Continuar',
                        style: TextStyle(fontSize: subtitleFontSize * 1.15, color: Colors.white),
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

        // NUEVO: Guardar datos temporalmente en SharedPreferences
        // Ya NO crear el usuario en el backend
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_register_username', username);
        await prefs.setString('temp_register_password', password);
        await prefs.setString('temp_register_email', email);
        await prefs.setString('temp_register_birthdate', birthdate.toIso8601String());

        // Continuar al siguiente paso
        Navigator.pushNamed(context, registerPreferencesRoute, arguments: {'username': username, 'email': email});
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
