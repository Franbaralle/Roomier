import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'auth_service.dart';
import 'services/tag_service.dart';
import 'models/tag_models.dart';

class PreferencesPage extends StatefulWidget {
  final String username;
  final String email;

  PreferencesPage({required this.username, required this.email});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final TagService _tagService = TagService();
  
  // Tags seleccionados como array plano (v3.0)
  List<String> selectedTagIds = [];
  
  // Sección de intereses desde master_tags.json
  TagSection? _interestsSection;
  
  // Categoría actualmente expandida
  String? expandedCategory;
  
  bool _isLoading = true;
  
  // ScrollController para manejar el scroll
  final ScrollController _scrollController = ScrollController();
  
  // Keys para cada categoría
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _loadInterestsSection();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInterestsSection() async {
    try {
      _interestsSection = _tagService.getSection('interests');
      
      // Crear keys para cada categoría
      if (_interestsSection != null) {
        for (var category in _interestsSection!.categories) {
          _categoryKeys[category.id] = GlobalKey();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando sección interests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Contar total de tags seleccionados
  int getTotalSelectedCount() {
    return selectedTagIds.length;
  }

  // Contar tags seleccionados en una subcategoría específica
  int getSubcategoryCount(TagSubCategory subcategory) {
    return subcategory.tags.where((tag) => selectedTagIds.contains(tag.id)).length;
  }

  // Toggle de un tag
  void toggleTag(String tagId) {
    setState(() {
      if (selectedTagIds.contains(tagId)) {
        selectedTagIds.remove(tagId);
      } else {
        // Verificar límite global de 25 tags
        final maxGlobal = _tagService.config.maxGlobalInterests;
        if (selectedTagIds.length < maxGlobal) {
          selectedTagIds.add(tagId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Máximo $maxGlobal tags totales'),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxGlobal = _tagService.config.maxGlobalInterests;
    
    // Loading state
    if (_isLoading || _interestsSection == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Tus Intereses'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue.shade700,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_interestsSection!.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header con contador
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.01,
                    offset: Offset(0, screenHeight * 0.002),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _interestsSection!.description,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Text(
                      '$totalSelected / $maxGlobal tags seleccionados',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
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
                controller: _scrollController,
                padding: EdgeInsets.all(screenWidth * 0.04),
                itemCount: _interestsSection!.categories.length,
                itemBuilder: (context, index) {
                  final category = _interestsSection!.categories[index];
                  final isExpanded = expandedCategory == category.id;
                  
                  return Card(
                    key: _categoryKeys[category.id],
                    margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              final wasExpanded = isExpanded;
                              expandedCategory = isExpanded ? null : category.id;
                              
                              // Si se está expandiendo (no estaba expandido), hacer scroll al inicio de la categoría
                              if (!wasExpanded && _categoryKeys[category.id] != null) {
                                // Esperar a que el widget se expanda antes de hacer scroll
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final RenderBox? renderBox = _categoryKeys[category.id]!.currentContext?.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    final position = renderBox.localToGlobal(Offset.zero);
                                    final scrollPosition = _scrollController.position.pixels + position.dy - 100; // 100 es un offset para dejar espacio arriba
                                    
                                    _scrollController.animateTo(
                                      scrollPosition,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                });
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.label,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.blue.shade700,
                                  size: screenWidth * 0.06,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded && category.subcategories != null)
                          ...category.subcategories!.map((subcategory) {
                            final selectedCount = getSubcategoryCount(subcategory);
                            
                            return Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
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
                                        subcategory.label,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.0375,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.002,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedCount > 0
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                        ),
                                        child: Text(
                                          '$selectedCount seleccionados',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.bold,
                                            color: selectedCount > 0
                                                ? Colors.blue.shade700
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  Wrap(
                                    spacing: screenWidth * 0.02,
                                    runSpacing: screenHeight * 0.01,
                                    children: subcategory.tags.map((tag) {
                                      final isSelected = selectedTagIds.contains(tag.id);
                                      
                                      return FilterChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (tag.icon != null) ...[
                                              Text(
                                                tag.icon!,
                                                style: TextStyle(fontSize: screenWidth * 0.035),
                                              ),
                                              SizedBox(width: screenWidth * 0.01),
                                            ],
                                            Text(
                                              tag.label,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.0325,
                                                color: isSelected ? Colors.white : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) => toggleTag(tag.id),
                                        selectedColor: Colors.blue.shade600,
                                        checkmarkColor: Colors.white,
                                        backgroundColor: Colors.grey[100],
                                        elevation: isSelected ? 3 : 1,
                                        pressElevation: 5,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.01,
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
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.01,
                    offset: Offset(0, -screenHeight * 0.002),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: totalSelected > 0
                      ? () async {
                          // Guardar tags seleccionados como array plano (v3.0)
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('temp_register_interests_tags', json.encode(selectedTagIds));
                          
                          print('🏷️ Tags de intereses guardados: $selectedTagIds');
                          
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}