import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';

class PersonalInfoPage extends StatefulWidget {
  final String username;
  final String email;

  PersonalInfoPage({required this.username, required this.email});

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  // Controladores para los campos de texto
  final TextEditingController jobController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController politicPreferencesController =
      TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos Personales'),
      ),
      body: Center(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Esta es la página de Datos Personales',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: jobController,
                decoration: const InputDecoration(labelText: 'Trabajo'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: TextField(
                controller: religionController,
                decoration: const InputDecoration(labelText: 'Religión'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: TextField(
                controller: politicPreferencesController,
                decoration:
                    const InputDecoration(labelText: 'Preferencia Política'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: TextField(
                controller: aboutMeController,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(
                    labelText: 'Cuéntame más sobre ti (300 palabras)'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await AuthService().updatePersonalInfo(
                  widget.username,
                  jobController.text,
                  religionController.text,
                  politicPreferencesController.text,
                  aboutMeController.text,
                );
                Navigator.pushNamed(context, registerProfilePhotoRoute,
                    arguments: {
                      'username': widget.username,
                      'email': widget.email
                    });
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
