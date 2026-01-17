import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    
    // Escalamiento responsive
    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 24.0 : 32.0);
    final cardWidth = isSmallScreen ? screenWidth * 0.95 : (isMediumScreen ? 500.0 : 600.0);
    final cardPadding = isSmallScreen ? 20.0 : (isMediumScreen ? 28.0 : 32.0);
    final iconSize = isSmallScreen ? 48.0 : (isMediumScreen ? 56.0 : 64.0);
    final titleSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
    final subtitleSize = isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
    final sectionTitleSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final verticalSpacingSmall = isSmallScreen ? 6.0 : 8.0;
    final verticalSpacingMedium = isSmallScreen ? 12.0 : 16.0;
    final verticalSpacingLarge = isSmallScreen ? 24.0 : 32.0;
    final buttonHeight = isSmallScreen ? 45.0 : 50.0;
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Preferencias de Roommate',
          style: TextStyle(fontSize: isSmallScreen ? 16.0 : 18.0),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
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
                  Center(
                    child: Icon(
                      Icons.people_outline,
                      size: iconSize,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: verticalSpacingMedium),
                  Center(
                    child: Text(
                      '¿Con quién te gustaría convivir?',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalSpacingSmall),
                  Center(
                    child: Text(
                      'Esto nos ayudará a encontrar el mejor match para ti',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalSpacingLarge),
                  
                  // Sección de género
                  Text(
                    'Género preferido',
                    style: TextStyle(
                      fontSize: sectionTitleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: verticalSpacingMedium),
                  
                  _buildGenderOption('Hombres', 'male', Icons.man, isSmallScreen),
                  SizedBox(height: verticalSpacingSmall),
                  _buildGenderOption('Mujeres', 'female', Icons.woman, isSmallScreen),
                  SizedBox(height: verticalSpacingSmall),
                  _buildGenderOption('Ambos', 'both', Icons.people, isSmallScreen),
                  
                  SizedBox(height: verticalSpacingLarge),
                  
                  // Sección de rango de edad
                  Text(
                    'Rango de edad',
                    style: TextStyle(
                      fontSize: sectionTitleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: verticalSpacingMedium),
                  
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'a ${maxAge.round()} años',
                              style: TextStyle(
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalSpacingSmall),
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
                      padding: EdgeInsets.only(top: verticalSpacingSmall),
                      child: Text(
                        'La edad mínima no puede ser mayor que la máxima',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isSmallScreen ? 11.0 : 12.0,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: verticalSpacingLarge),
                  
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _canContinue()
                          ? () async {
                              // Guardar temporalmente en SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('temp_register_roommate_gender', selectedGender!);
                              await prefs.setInt('temp_register_roommate_min_age', minAge.round());
                              await prefs.setInt('temp_register_roommate_max_age', maxAge.round());
                              
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
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: buttonTextSize,
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

  Widget _buildGenderOption(String label, String value, IconData icon, bool isSmallScreen) {
    final isSelected = selectedGender == value;
    final optionPadding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final spacingWidth = isSmallScreen ? 12.0 : 16.0;
    final textSize = isSmallScreen ? 14.0 : 16.0;
    final checkIconSize = isSmallScreen ? 20.0 : 24.0;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(optionPadding),
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
              size: iconSize,
            ),
            SizedBox(width: spacingWidth),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue.shade700,
                size: checkIconSize,
              ),
          ],
        ),
      ),
    );
  }
}
