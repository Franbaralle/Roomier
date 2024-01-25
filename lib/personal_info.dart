import 'package:flutter/material.dart';
import 'routes.dart';

class PersonalInfoPage extends StatelessWidget {
  // Controladores para los campos de texto
  final TextEditingController trabajoController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController preferenciaPoliticaController = TextEditingController();
  final TextEditingController cuentaloController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos Personales'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Esta es la página de Datos Personales',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            // Cuadro de texto para Trabajo
            TextField(
              controller: trabajoController,
              decoration: InputDecoration(labelText: 'Trabajo'),
            ),
            const SizedBox(height: 10),
            // Cuadro de texto para Religión
            TextField(
              controller: religionController,
              decoration: InputDecoration(labelText: 'Religión'),
            ),
            const SizedBox(height: 10),
            // Cuadro de texto para Preferencia Política
            TextField(
              controller: preferenciaPoliticaController,
              decoration: InputDecoration(labelText: 'Preferencia Política'),
            ),
            const SizedBox(height: 10),
            // Cuadro de texto para "Cuéntame más sobre ti"
            TextField(
              controller: cuentaloController,
              maxLines: 5, // Puedes ajustar el número de líneas según tu preferencia
              maxLength: 300,
              decoration: InputDecoration(labelText: 'Cuéntame más sobre ti (300 palabras)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página para subir fotos
                Navigator.pushNamed(context, registerProfilePhotoRoute);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
