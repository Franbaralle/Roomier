import 'package:flutter/material.dart';
import 'routes.dart';

class PersonalInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos Personales'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Esta es la página de Datos Personales',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página para subir fotos
                    Navigator.pushNamed(
                      context,
                      registerProfilePhotoRoute
                    );
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}