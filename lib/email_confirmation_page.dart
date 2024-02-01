import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';

class EmailConfirmationPage extends StatelessWidget {
  final String email;
  final TextEditingController verificationCodeController = TextEditingController();
  final AuthService authService = AuthService();

  EmailConfirmationPage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmación de Correo Electrónico'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Se ha enviado un correo electrónico con un código de verificación a $email.',
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: verificationCodeController,
                decoration: InputDecoration(
                  labelText: 'Código de Verificación',
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final String verificationCode = verificationCodeController.text;

                await authService.verifyVerificationCode(
                  email,
                  verificationCode,
                );

                // Aquí puedes agregar más lógica según sea necesario,
                // por ejemplo, navegar a la siguiente pantalla si el código es verificado exitosamente.
                // Ejemplo: Navigator.pushNamed(context, loginRoute);

                // En tu caso, podrías hacer algo como:
                Navigator.pushNamed(context, loginRoute);
              },
              child: Text('Verificar Código'),
            ),
          ],
        ),
      ),
    );
  }
}
