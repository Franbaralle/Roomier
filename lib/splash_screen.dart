import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authService = AuthService();
    final prefs = await SharedPreferences.getInstance();
    
    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(seconds: 1));
    
    // Verificar si ya aceptó el consentimiento de cookies
    final cookiesAccepted = prefs.getBool('cookies_accepted') ?? false;
    
    if (!cookiesAccepted) {
      // Mostrar banner de cookies (Ley 25.326)
      if (mounted) {
        await _showCookieConsent(prefs);
      }
    }
    
    // Verificar si hay sesión activa
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // Si hay sesión, ir a Home
      final username = authService.loadUserData('username');
      Navigator.pushReplacementNamed(
        context,
        homeRoute,
        arguments: {'username': username},
      );
    } else {
      // Si no hay sesión, ir a Login
      Navigator.pushReplacementNamed(context, loginRoute);
    }
  }

  Future<void> _showCookieConsent(SharedPreferences prefs) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.cookie, color: Colors.orange, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uso de Cookies',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Roomier utiliza tecnologías de almacenamiento local (cookies móviles) para:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('• Mantener tu sesión activa'),
                const Text('• Recordar tus preferencias'),
                const Text('• Mejorar tu experiencia en la app'),
                const Text('• Analizar el uso de la aplicación'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'Cumplimos con la Ley 25.326 de Protección de Datos Personales de Argentina.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Al continuar, aceptas el uso de estas tecnologías según nuestra Política de Privacidad.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Rechazar cookies = cerrar la app
                Navigator.of(context).pop();
                // En producción, podrías cerrar la app o limitar funcionalidad
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Funcionalidad Limitada'),
                    content: const Text(
                      'Sin aceptar cookies, algunas funciones de la app no estarán disponibles. Puedes aceptar en cualquier momento desde Configuración.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Guardar consentimiento
                await prefs.setBool('cookies_accepted', true);
                await prefs.setString('cookies_accepted_date', DateTime.now().toIso8601String());
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar y Continuar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9AD9C7), // Verde pastel
              Color(0xFFB7A7E3), // Lila
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la app
              Image.asset(
                'assets/logo_en_blanco.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              // Indicador de carga
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 30),
              // Tagline de la app
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Roomier. Más que un match, un compañero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
