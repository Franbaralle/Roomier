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
  
  // Consentimiento para datos sensibles (Ley 25.326)
  bool _consentSensitiveData = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final cardWidth = isSmallScreen ? size.width * 0.95 : 500.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final cardPadding = isSmallScreen ? 20.0 : 32.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Información Personal'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: iconSize,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cuéntanos sobre ti',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Esta información aparecerá en tu perfil',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 32),
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
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Sección de datos sensibles (Ley 25.326)
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade700, size: isSmallScreen ? 18 : 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Datos Sensibles (Opcional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Religión y preferencia política son datos sensibles (Ley 25.326). Son opcionales y se usarán solo para mejorar tu compatibilidad.',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _consentSensitiveData,
                              onChanged: (value) {
                                setState(() {
                                  _consentSensitiveData = value ?? false;
                                  // Si desmarca, limpiar los campos sensibles
                                  if (!_consentSensitiveData) {
                                    religionController.clear();
                                    politicPreferencesController.clear();
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Doy mi consentimiento expreso para el tratamiento de mis datos sensibles (religión y preferencia política)',
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: religionController,
                    enabled: _consentSensitiveData,
                    decoration: InputDecoration(
                      labelText: 'Religión',
                      hintText: 'Opcional - Requiere consentimiento',
                      prefixIcon: Icon(
                        Icons.church_outlined,
                        color: _consentSensitiveData ? null : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _consentSensitiveData ? Colors.grey[50] : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: politicPreferencesController,
                    enabled: _consentSensitiveData,
                    decoration: InputDecoration(
                      labelText: 'Preferencia Política',
                      hintText: 'Opcional - Requiere consentimiento',
                      prefixIcon: Icon(
                        Icons.how_to_vote_outlined,
                        color: _consentSensitiveData ? null : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _consentSensitiveData ? Colors.grey[50] : Colors.grey[200],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  TextField(
                    controller: aboutMeController,
                    maxLines: isSmallScreen ? 4 : 5,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: 'Sobre mí',
                      hintText: 'Cuéntanos más sobre ti (máx. 300 caracteres)',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 60 : 80),
                        child: const Icon(Icons.edit_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      alignLabelWithHint: true,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 48 : 50,
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
                      child: Text(
                        'Continuar',
                        style: TextStyle(fontSize: isSmallScreen ? 15 : 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
