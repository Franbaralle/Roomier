import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'auth_service.dart';
import 'preferences_data.dart';

class PreferencesPage extends StatefulWidget {
  final String username;
  final String email;

  PreferencesPage({required this.username, required this.email});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // Mapa para almacenar las preferencias seleccionadas por categoría y subcategoría
  Map<String, Map<String, List<String>>> selectedPreferences = {};
  
  // Categoría actualmente expandida
  String? expandedCategory;

  @override
  void initState() {
    super.initState();
    // Inicializar estructura vacía
    for (var mainCat in PreferencesData.categories.keys) {
      selectedPreferences[mainCat] = {};
      for (var subCat in PreferencesData.categories[mainCat]!.keys) {
        selectedPreferences[mainCat]![subCat] = [];
      }
    }
  }

  // Contar total de tags seleccionados
  int getTotalSelectedCount() {
    int count = 0;
    selectedPreferences.forEach((mainCat, subCats) {
      subCats.forEach((subCat, tags) {
        count += tags.length;
      });
    });
    return count;
  }

  // Contar tags seleccionados en una subcategoría específica
  int getSubcategoryCount(String mainCat, String subCat) {
    return selectedPreferences[mainCat]?[subCat]?.length ?? 0;
  }

  // Toggle de un tag
  void toggleTag(String mainCat, String subCat, String tag) {
    setState(() {
      final currentTags = selectedPreferences[mainCat]![subCat]!;
      if (currentTags.contains(tag)) {
        currentTags.remove(tag);
      } else {
        // Limitar a 5 por subcategoría
        if (currentTags.length < 5) {
          currentTags.add(tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Máximo 5 tags por subcategoría'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = getTotalSelectedCount();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tus Intereses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // Header con contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Selecciona hasta 5 tags por subcategoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalSelected tags seleccionados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de categorías
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: PreferencesData.categories.length,
              itemBuilder: (context, index) {
                final mainCat = PreferencesData.categories.keys.elementAt(index);
                final subCategories = PreferencesData.categories[mainCat]!;
                final isExpanded = expandedCategory == mainCat;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            expandedCategory = isExpanded ? null : mainCat;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  PreferencesData.categoryLabels[mainCat] ?? mainCat,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        ...subCategories.entries.map((subCatEntry) {
                          final subCat = subCatEntry.key;
                          final tags = subCatEntry.value;
                          final selectedCount = getSubcategoryCount(mainCat, subCat);
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      PreferencesData.subcategoryLabels[subCat] ?? subCat,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedCount > 0
                                            ? Colors.blue.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$selectedCount/5',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: selectedCount > 0
                                              ? Colors.blue.shade700
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((tag) {
                                    final isSelected = selectedPreferences[mainCat]![subCat]!.contains(tag);
                                    
                                    return FilterChip(
                                      label: Text(
                                        PreferencesData.tagLabels[tag] ?? tag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : Colors.grey[800],
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (_) => toggleTag(mainCat, subCat, tag),
                                      selectedColor: Colors.blue.shade600,
                                      checkmarkColor: Colors.white,
                                      backgroundColor: Colors.grey[100],
                                      elevation: isSelected ? 3 : 1,
                                      pressElevation: 5,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Botón de continuar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: totalSelected > 0
                      ? () async {
                          // Guardar preferencias temporalmente
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('temp_register_preferences', json.encode(selectedPreferences));
                          
                          Navigator.pushNamed(
                            context,
                            roommatePreferencesRoute,
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
            ),
          ),
        ],
      ),
    );
  }
}
