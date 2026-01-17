import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'services/tag_service.dart';
import 'models/tag_models.dart';

class LivingHabitsPage extends StatefulWidget {
  final String username;
  final String email;

  LivingHabitsPage({required this.username, required this.email});

  @override
  _LivingHabitsPageState createState() => _LivingHabitsPageState();
}

class _LivingHabitsPageState extends State<LivingHabitsPage> {
  final TagService _tagService = TagService();
  TagSection? _livingHabitsSection;
  
  // Mapa para almacenar las selecciones: categoryId -> selectedTagId
  Map<String, String?> _selections = {};

  @override
  void initState() {
    super.initState();
    _loadLivingHabits();
  }

  void _loadLivingHabits() {
    setState(() {
      _livingHabitsSection = _tagService.getSection('living_habits');
      // Inicializar selecciones vacías para cada categoría
      if (_livingHabitsSection != null) {
        for (var category in _livingHabitsSection!.categories) {
          _selections[category.id] = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    // Dimensiones responsivas
    final horizontalPadding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 24.0);
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final descriptionFontSize = isSmallScreen ? 12.0 : 14.0;
    final categoryFontSize = isSmallScreen ? 16.0 : 18.0;
    final verticalSpacing = screenHeight * 0.02;
    final buttonWidth = screenWidth > 600 ? 250.0 : screenWidth * 0.6;
    
    if (_livingHabitsSection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hábitos de Convivencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_livingHabitsSection!.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuéntanos sobre tus hábitos',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.4),
                Text(
                  _livingHabitsSection!.description,
                  style: TextStyle(
                    fontSize: descriptionFontSize,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: verticalSpacing * 1.2),

                // Renderizar categorías dinámicamente
                ..._livingHabitsSection!.categories.map((category) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategorySection(category, categoryFontSize),
                      Divider(height: verticalSpacing * 1.6),
                    ],
                  );
                }).toList(),

                SizedBox(height: verticalSpacing * 0.8),

                // Botón Continuar
                Center(
                  child: SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(buttonWidth, isSmallScreen ? 45 : 50),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(TagCategory category, double categoryFontSize) {
    final screenHeight = MediaQuery.of(context).size.height;
    final itemSpacing = screenHeight * 0.015;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la categoría con emoji
        Text(
          category.question ?? category.label,
          style: TextStyle(
            fontSize: categoryFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: itemSpacing),
        
        // Renderizar tags como RadioListTile
        ...category.directTags!.map((tag) {
          return RadioListTile<String>(
            title: Text('${tag.icon} ${tag.label}'),
            value: tag.id,
            groupValue: _selections[category.id],
            onChanged: (value) {
              setState(() {
                _selections[category.id] = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ],
    );
  }

  Future<void> _handleContinue() async {
    try {
      // Validar que todas las categorías requeridas estén respondidas
      final missingCategories = _livingHabitsSection!.categories
          .where((cat) => cat.required && _selections[cat.id] == null)
          .toList();

      if (missingCategories.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor completa todas las secciones requeridas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Recopilar los IDs de tags seleccionados (arquitectura nueva)
      final List<String> selectedTagIds = _selections.values
          .where((tagId) => tagId != null)
          .cast<String>()
          .toList();

      // Guardar temporalmente en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_register_living_habits_tags', json.encode(selectedTagIds));

      print('🏠 Hábitos guardados: $selectedTagIds');

      // Navegar a la página de información de vivienda
      Navigator.pushNamed(
        context,
        housingInfoRoute,
        arguments: {
          'username': widget.username,
          'email': widget.email,
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
