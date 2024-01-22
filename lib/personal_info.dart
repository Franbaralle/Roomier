import 'package:flutter/material.dart';

class DatosPersonalesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos Personales'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Esta es la página de Datos Personales',
              style: TextStyle(fontSize: 20),
            ),
            // Puedes agregar más contenido según tus necesidades
          ],
        ),
      ),
    );
  }
}