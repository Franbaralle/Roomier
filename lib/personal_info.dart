import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Información Personal'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 32,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuéntanos sobre ti',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Esta información aparecerá en tu perfil',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: jobController,
                    decoration: InputDecoration(
                      labelText: 'Trabajo',
                      hintText: 'Ej: Estudiante, Ingeniero, etc.',
                      prefixIcon: const Icon(Icons.work_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: religionController,
                    decoration: InputDecoration(
                      labelText: 'Religión',
                      hintText: 'Opcional',
                      prefixIcon: const Icon(Icons.church_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: politicPreferencesController,
                    decoration: InputDecoration(
                      labelText: 'Preferencia Política',
                      hintText: 'Opcional',
                      prefixIcon: const Icon(Icons.how_to_vote_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: aboutMeController,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: 'Sobre mí',
                      hintText: 'Cuéntanos más sobre ti (máx. 300 caracteres)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.edit_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Guardar temporalmente en SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('temp_register_job', jobController.text);
                        await prefs.setString('temp_register_religion', religionController.text);
                        await prefs.setString('temp_register_politic_preferences', politicPreferencesController.text);
                        await prefs.setString('temp_register_about_me', aboutMeController.text);
                        
                        Navigator.pushNamed(context, registerProfilePhotoRoute,
                            arguments: {
                              'username': widget.username,
                              'email': widget.email
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
