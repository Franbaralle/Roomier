import 'package:flutter/material.dart';
import 'routes.dart';
import 'auth_service.dart';

class RoommatePreferencesPage extends StatefulWidget {
  final String username;
  final String email;

  RoommatePreferencesPage({required this.username, required this.email});

  @override
  _RoommatePreferencesPageState createState() => _RoommatePreferencesPageState();
}

class _RoommatePreferencesPageState extends State<RoommatePreferencesPage> {
  String? selectedGender = 'both';
  double minAge = 18;
  double maxAge = 65;
  
  String? userGender;
  bool isLoadingUserGender = true;

  @override
  void initState() {
    super.initState();
    _loadUserGender();
  }

  Future<void> _loadUserGender() async {
    try {
      // Aquí podrías cargar el género del usuario si ya lo tiene guardado
      // Por ahora lo dejamos como opcional
      setState(() {
        isLoadingUserGender = false;
      });
    } catch (e) {
      print('Error cargando género del usuario: $e');
      setState(() {
        isLoadingUserGender = false;
      });
    }
  }

  bool _canContinue() {
    return selectedGender != null && minAge <= maxAge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Preferencias de Roommate'),
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
                  Center(
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '¿Con quién te gustaría convivir?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Esto nos ayudará a encontrar el mejor match para ti',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Sección de género
                  Text(
                    'Género preferido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGenderOption('Hombres', 'male', Icons.man),
                  const SizedBox(height: 8),
                  _buildGenderOption('Mujeres', 'female', Icons.woman),
                  const SizedBox(height: 8),
                  _buildGenderOption('Ambos', 'both', Icons.people),
                  
                  const SizedBox(height: 32),
                  
                  // Sección de rango de edad
                  Text(
                    'Rango de edad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'De ${minAge.round()} años',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'a ${maxAge.round()} años',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: RangeValues(minAge, maxAge),
                          min: 18,
                          max: 100,
                          divisions: 82,
                          activeColor: Colors.blue.shade700,
                          inactiveColor: Colors.blue.shade200,
                          labels: RangeLabels(
                            minAge.round().toString(),
                            maxAge.round().toString(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              minAge = values.start;
                              maxAge = values.end;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  if (minAge > maxAge)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'La edad mínima no puede ser mayor que la máxima',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canContinue()
                          ? () async {
                              await AuthService().updateRoommatePreferences(
                                widget.username,
                                selectedGender!,
                                minAge.round(),
                                maxAge.round(),
                              );
                              Navigator.pushNamed(
                                context,
                                livingHabitsRoute,
                                arguments: {
                                  'username': widget.username,
                                  'email': widget.email,
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon) {
    final isSelected = selectedGender == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue.shade700,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
