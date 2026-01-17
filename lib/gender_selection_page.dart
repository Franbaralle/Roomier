import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'auth_service.dart';

class GenderSelectionPage extends StatefulWidget {
  @override
  _GenderSelectionPageState createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage> {
  String? selectedGender;

  void _continue() async {
    if (selectedGender != null) {
      // Guardar género en SharedPreferences temporal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_register_gender', selectedGender!);
      
      // Continuar al siguiente paso (fecha de nacimiento)
      Navigator.pushNamed(context, dateRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona tu género'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dimensiones responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06; // 6% padding
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    final iconSize = screenWidth * 0.2; // 20% del ancho
    final titleFontSize = screenWidth * 0.06; // 6% del ancho
    final subtitleFontSize = screenWidth * 0.035; // 3.5% del ancho
    final buttonHeight = screenHeight * 0.06; // 6% de la altura
    final genderOptionPadding = screenWidth * 0.04; // 4% del ancho
    final optionIconSize = screenWidth * 0.08; // 8% del ancho
    final labelFontSize = screenWidth * 0.045; // 4.5% del ancho
    final checkIconSize = screenWidth * 0.07; // 7% del ancho
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tu Género'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.all(padding * 1.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: iconSize * 0.6,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    '¿Cuál es tu género?',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Esta información nos ayuda a encontrar mejores matches',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  
                  _buildGenderOption('Masculino', 'male', Icons.man, genderOptionPadding, optionIconSize, labelFontSize, checkIconSize),
                  SizedBox(height: screenHeight * 0.015),
                  _buildGenderOption('Femenino', 'female', Icons.woman, genderOptionPadding, optionIconSize, labelFontSize, checkIconSize),
                  SizedBox(height: screenHeight * 0.015),
                  _buildGenderOption('Otro', 'other', Icons.person, genderOptionPadding, optionIconSize, labelFontSize, checkIconSize),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: selectedGender != null ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: selectedGender != null
                              ? const LinearGradient(
                                  colors: [Color(0xFF9AD9C7), Color(0xFFB7A7E3)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: selectedGender != null ? null : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: BoxConstraints(minHeight: buttonHeight),
                          child: Text(
                            'Continuar',
                            style: TextStyle(fontSize: subtitleFontSize * 1.15, color: Colors.white),
                          ),
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
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon, double padding, double iconSize, double fontSize, double checkSize) {
    final isSelected = selectedGender == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5F0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF9AD9C7) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(padding * 0.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF9AD9C7) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: iconSize,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF9AD9C7),
                size: checkSize,
              ),
          ],
        ),
      ),
    );
  }
}
