import 'package:flutter/material.dart';
import 'personal_info.dart';

class PreferenciasPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferencias'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Esta es la página de preferencias',
              style: TextStyle(fontSize: 20),
            ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Navegar a la página de Datos Personales
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DatosPersonalesPage()),
            );
          },
          child: Text('Continuar'),
        ),
          ],
        ),
      ),
    );
  }
}