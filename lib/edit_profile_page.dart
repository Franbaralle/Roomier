import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'preferences_data.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final Map<String, dynamic> currentUserData;

  const EditProfilePage({
    Key? key,
    required this.username,
    required this.currentUserData,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService authService = AuthService();
  bool _isLoading = false;

  // Mapa para almacenar las preferencias seleccionadas por categoría y subcategoría
  Map<String, Map<String, List<String>>> selectedPreferences = {};
  
  // Categoría actualmente expandida en la sección de intereses
  String? expandedInterestCategory;

  // Variables para hábitos de convivencia
  String? _smoker;
  String? _pets;
  String? _cleanliness;
  String? _noiseLevel;
  String? _scheduleType;
  String? _socialLevel;
  String? _guestsFrequency;
  String? _drinker;

  // Controllers para vivienda
  bool _hasPlace = false;
  final TextEditingController _moveInDateController = TextEditingController();
  String? _stayDuration;
  final TextEditingController _originProvinceController = TextEditingController();
  final TextEditingController _destinationProvinceController = TextEditingController();
  String? _selectedOriginProvince;
  String? _selectedDestinationProvince;
  List<String> _selectedNeighborhoodsOrigin = [];
  List<String> _selectedNeighborhoodsDestination = [];
  
  // Legacy fields (mantener para compatibilidad)
  final TextEditingController _cityController = TextEditingController();
  String? _generalZone;
  List<String> _preferredZones = [];
  
  final TextEditingController _budgetMinController = TextEditingController();
  final TextEditingController _budgetMaxController = TextEditingController();
  
  // API Georef data
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _neighborhoodsOrigin = []; // Cambiar a Map
  List<Map<String, dynamic>> _neighborhoodsDestination = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    // Inicializar estructura vacía para preferencias
    for (var mainCat in PreferencesData.categories.keys) {
      selectedPreferences[mainCat] = {};
      for (var subCat in PreferencesData.categories[mainCat]!.keys) {
        selectedPreferences[mainCat]![subCat] = [];
      }
    }
    _loadCurrentData();
    _loadProvinces();
  }

  // Cargar provincias desde API Georef
  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://apis.datos.gob.ar/georef/api/provincias?campos=id,nombre'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _provinces = List<Map<String, dynamic>>.from(data['provincias']);
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      print('Error loading provinces: $e');
      setState(() => _isLoadingProvinces = false);
    }
  }

  // Cargar localidades de una provincia (para después buscar barrios)
  Future<void> _loadNeighborhoods(String provinceName, bool isOrigin) async {
    setState(() => _isLoadingNeighborhoods = true);
    
    try {
      // Primero obtener las localidades/ciudades de la provincia
      final citiesResponse = await http.get(
        Uri.parse(
          'https://apis.datos.gob.ar/georef/api/localidades?provincia=$provinceName&campos=id,nombre&max=5000'
        ),
      );
      
      if (citiesResponse.statusCode == 200) {
        final citiesData = json.decode(citiesResponse.body);
        final localities = List<Map<String, dynamic>>.from(citiesData['localidades']);
        
        // Intentar cargar barrios desde el backend
        List<Map<String, dynamic>> allNeighborhoods = [];
        
        for (var locality in localities) {
          try {
            final neighborhoodsResponse = await http.get(
              Uri.parse('${AuthService.apiUrl}/neighborhoods?cityId=${locality['id']}'),
            );
            
            if (neighborhoodsResponse.statusCode == 200) {
              final neighborhoodsData = json.decode(neighborhoodsResponse.body);
              if (neighborhoodsData['count'] > 0) {
                // Si la ciudad tiene barrios cargados, usarlos
                for (var neighborhood in neighborhoodsData['data']) {
                  allNeighborhoods.add({
                    'id': neighborhood['_id'],
                    'name': neighborhood['name'],
                    'cityName': neighborhood['cityName'],
                    'cityId': locality['id'],
                    'hasData': true // Indica que son datos reales de barrios
                  });
                }
              }
            }
          } catch (e) {
            print('Error loading neighborhoods for ${locality['nombre']}: $e');
          }
        }
        
        // Si no hay barrios cargados, mostrar las ciudades como opciones
        if (allNeighborhoods.isEmpty) {
          allNeighborhoods = localities.map((l) => {
            'id': l['id'],
            'name': l['nombre'] as String,
            'cityName': l['nombre'] as String,
            'cityId': l['id'],
            'hasData': false // Indica que son ciudades, no barrios
          }).toList();
        }
        
        allNeighborhoods.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        
        setState(() {
          if (isOrigin) {
            _neighborhoodsOrigin = allNeighborhoods;
          } else {
            _neighborhoodsDestination = allNeighborhoods;
          }
          _isLoadingNeighborhoods = false;
        });
      }
    } catch (e) {
      print('Error loading neighborhoods: $e');
      setState(() => _isLoadingNeighborhoods = false);
    }
  }

  void _loadCurrentData() {
    // Debug: Imprimir la estructura de datos recibida
    print('=== DEBUG EDIT PROFILE ===');
    print('personalInfo: ${widget.currentUserData['personalInfo']}');
    print('livingHabits: ${widget.currentUserData['livingHabits']}');
    print('housingInfo: ${widget.currentUserData['housingInfo']}');
    print('preferences: ${widget.currentUserData['preferences']}');
    print('========================');
    
    try {
      // Cargar preferencias estructuradas
      final preferencesData = widget.currentUserData['preferences'];
      if (preferencesData != null && preferencesData is Map) {
        preferencesData.forEach((mainCat, subCats) {
          if (subCats is Map && selectedPreferences.containsKey(mainCat)) {
            subCats.forEach((subCat, tags) {
              if (tags is List && selectedPreferences[mainCat]!.containsKey(subCat)) {
                selectedPreferences[mainCat]![subCat] = 
                  tags.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
              }
            });
          }
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }

    try {
      // Cargar hábitos de convivencia - mapear valores del backend a UI
      // smoker: boolean → 'Sí' / 'No'
      final smokerVal = widget.currentUserData['livingHabits']?['smoker'];
      _smoker = smokerVal == true ? 'Sí' : smokerVal == false ? 'No' : null;
      
      // hasPets: boolean → 'Sí' / 'No' / 'Tal vez'
      final hasPetsVal = widget.currentUserData['livingHabits']?['hasPets'];
      _pets = hasPetsVal == true ? 'Sí' : hasPetsVal == false ? 'No' : null;
      
      // cleanliness: 'low' / 'normal' / 'high' → 'Desordenado' / 'Promedio' / 'Muy limpio'
      final cleanlinessVal = widget.currentUserData['livingHabits']?['cleanliness']?.toString();
      _cleanliness = cleanlinessVal == 'low' ? 'Desordenado' 
                   : cleanlinessVal == 'normal' ? 'Promedio' 
                   : cleanlinessVal == 'high' ? 'Muy limpio' : null;
      
      // noiseLevel: 'quiet' / 'normal' / 'social' → 'Bajo' / 'Medio' / 'Alto'
      final noiseLevelVal = widget.currentUserData['livingHabits']?['noiseLevel']?.toString();
      _noiseLevel = noiseLevelVal == 'quiet' ? 'Bajo' 
                  : noiseLevelVal == 'normal' ? 'Medio' 
                  : noiseLevelVal == 'social' ? 'Alto' : null;
      
      // schedule: 'early' / 'normal' / 'night' → 'Diurno' / 'Flexible' / 'Nocturno'
      final scheduleVal = widget.currentUserData['livingHabits']?['schedule']?.toString();
      _scheduleType = scheduleVal == 'early' ? 'Diurno' 
                    : scheduleVal == 'normal' ? 'Flexible' 
                    : scheduleVal == 'night' ? 'Nocturno' : null;
      
      // socialLevel: 'independent' / 'friendly' / 'very_social' → 'Introvertido' / 'Moderado' / 'Muy social'
      final socialLevelVal = widget.currentUserData['livingHabits']?['socialLevel']?.toString();
      _socialLevel = socialLevelVal == 'independent' ? 'Introvertido' 
                   : socialLevelVal == 'friendly' ? 'Moderado' 
                   : socialLevelVal == 'very_social' ? 'Muy social' : null;
      
      // hasGuests: boolean → 'Frecuente' / 'Ocasional' / 'Rara vez'
      final hasGuestsVal = widget.currentUserData['livingHabits']?['hasGuests'];
      _guestsFrequency = hasGuestsVal == true ? 'Frecuente' : hasGuestsVal == false ? 'Rara vez' : null;
      
      // drinker: 'never' / 'social' / 'regular' → 'No' / 'Ocasionalmente' / 'Sí'
      final drinkerVal = widget.currentUserData['livingHabits']?['drinker']?.toString();
      _drinker = drinkerVal == 'never' ? 'No' 
               : drinkerVal == 'social' ? 'Ocasionalmente' 
               : drinkerVal == 'regular' ? 'Sí' : null;
    } catch (e) {
      print('Error loading living habits: $e');
    }

    try {
      // Cargar información de vivienda
      final hasPlaceData = widget.currentUserData['housingInfo']?['hasPlace'];
      _hasPlace = hasPlaceData == true || hasPlaceData == 'true' || hasPlaceData == 1;
      _moveInDateController.text = widget.currentUserData['housingInfo']?['moveInDate']?.toString() ?? '';
      _stayDuration = widget.currentUserData['housingInfo']?['stayDuration']?.toString();
      
      // Nuevos campos
      _selectedOriginProvince = widget.currentUserData['housingInfo']?['originProvince']?.toString();
      _selectedDestinationProvince = widget.currentUserData['housingInfo']?['destinationProvince']?.toString();
      _originProvinceController.text = _selectedOriginProvince ?? '';
      _destinationProvinceController.text = _selectedDestinationProvince ?? '';
      
      // Cargar barrios específicos
      final neighborhoodsOrigin = widget.currentUserData['housingInfo']?['specificNeighborhoodsOrigin'];
      if (neighborhoodsOrigin != null && neighborhoodsOrigin is List) {
        _selectedNeighborhoodsOrigin = neighborhoodsOrigin.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      
      final neighborhoodsDestination = widget.currentUserData['housingInfo']?['specificNeighborhoodsDestination'];
      if (neighborhoodsDestination != null && neighborhoodsDestination is List) {
        _selectedNeighborhoodsDestination = neighborhoodsDestination.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      
      // Legacy fields (mantener para compatibilidad)
      _cityController.text = widget.currentUserData['housingInfo']?['city']?.toString() ?? '';
      _generalZone = widget.currentUserData['housingInfo']?['generalZone']?.toString();
      
      // Manejar preferredZones de forma segura (legacy)
      final prefZones = widget.currentUserData['housingInfo']?['preferredZones'];
      if (prefZones != null && prefZones is List) {
        _preferredZones = prefZones.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      } else {
        _preferredZones = [];
      }
      
      _budgetMinController.text = widget.currentUserData['housingInfo']?['budgetMin']?.toString() ?? '';
      _budgetMaxController.text = widget.currentUserData['housingInfo']?['budgetMax']?.toString() ?? '';
      
      // Cargar barrios si hay provincia seleccionada
      if (_selectedOriginProvince != null && _selectedOriginProvince!.isNotEmpty) {
        _loadNeighborhoods(_selectedOriginProvince!, true);
      }
      if (_selectedDestinationProvince != null && _selectedDestinationProvince!.isNotEmpty) {
        _loadNeighborhoods(_selectedDestinationProvince!, false);
      }
    } catch (e) {
      print('Error loading housing info: $e');
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

  Future<void> _updateInterests() async {
    setState(() => _isLoading = true);
    try {
      final token = authService.loadUserData('accessToken');
      final response = await http.put(
        Uri.parse('${AuthService.api}/edit-profile/tags'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'preferences': selectedPreferences}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intereses actualizados'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Error al actualizar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLivingHabits() async {
    setState(() => _isLoading = true);
    try {
      final token = authService.loadUserData('accessToken');
      final response = await http.put(
        Uri.parse('${AuthService.api}/edit-profile/living-habits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'smoker': _smoker,
          'pets': _pets,
          'cleanliness': _cleanliness,
          'noiseLevel': _noiseLevel,
          'scheduleType': _scheduleType,
          'socialLevel': _socialLevel,
          'guestsFrequency': _guestsFrequency,
          'drinker': _drinker,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábitos actualizados'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Error al actualizar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateHousingInfo() async {
    setState(() => _isLoading = true);
    try {
      final token = authService.loadUserData('accessToken');
      final response = await http.put(
        Uri.parse('${AuthService.api}/edit-profile/housing-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'hasPlace': _hasPlace,
          'moveInDate': _moveInDateController.text,
          'stayDuration': _stayDuration,
          'originProvince': _selectedOriginProvince,
          'destinationProvince': _selectedDestinationProvince,
          'specificNeighborhoodsOrigin': _selectedNeighborhoodsOrigin,
          'specificNeighborhoodsDestination': _selectedNeighborhoodsDestination,
          'budgetMin': int.tryParse(_budgetMinController.text),
          'budgetMax': int.tryParse(_budgetMaxController.text),
          
          // Legacy fields (mantener para compatibilidad)
          'city': _selectedDestinationProvince ?? _cityController.text,
          'preferredZones': _hasPlace ? _selectedNeighborhoodsOrigin : _selectedNeighborhoodsDestination,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información de vivienda actualizada'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Error al actualizar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInterestsSection(),
                const SizedBox(height: 20),
                _buildLivingHabitsSection(),
                const SizedBox(height: 20),
                _buildHousingInfoSection(),
              ],
            ),
    );
  }

  Widget _buildInterestsSection() {
    final totalSelected = getTotalSelectedCount();
    
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          children: [
            const Text('Tus Intereses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: totalSelected > 0 ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalSelected tags',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: totalSelected > 0 ? Colors.blue.shade700 : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona hasta 5 tags por subcategoría',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ...PreferencesData.categories.entries.map((mainCatEntry) {
                  final mainCat = mainCatEntry.key;
                  final subCategories = mainCatEntry.value;
                  final isExpanded = expandedInterestCategory == mainCat;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              expandedInterestCategory = isExpanded ? null : mainCat;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    PreferencesData.categoryLabels[mainCat] ?? mainCat,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                              padding: const EdgeInsets.all(12),
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
                                          fontSize: 14,
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
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: selectedCount > 0
                                                ? Colors.blue.shade700
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: tags.map((tag) {
                                      final isSelected = selectedPreferences[mainCat]![subCat]!.contains(tag);
                                      
                                      return FilterChip(
                                        label: Text(
                                          PreferencesData.tagLabels[tag] ?? tag,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected ? Colors.white : Colors.grey[800],
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) => toggleTag(mainCat, subCat, tag),
                                        selectedColor: Colors.blue.shade600,
                                        checkmarkColor: Colors.white,
                                        backgroundColor: Colors.grey[100],
                                        elevation: isSelected ? 2 : 1,
                                        pressElevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 6,
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
                }).toList(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateInterests,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    child: const Text('Guardar Intereses'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivingHabitsSection() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: const Text('Hábitos de Convivencia', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _smoker,
                  decoration: const InputDecoration(labelText: 'Fumador', border: OutlineInputBorder()),
                  items: ['Sí', 'No', 'Ocasionalmente'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _smoker = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _pets,
                  decoration: const InputDecoration(labelText: 'Mascotas', border: OutlineInputBorder()),
                  items: ['Sí', 'No', 'Tal vez'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _pets = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _cleanliness,
                  decoration: const InputDecoration(labelText: 'Nivel de limpieza', border: OutlineInputBorder()),
                  items: ['Muy limpio', 'Promedio', 'Desordenado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _cleanliness = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _noiseLevel,
                  decoration: const InputDecoration(labelText: 'Tolerancia al ruido', border: OutlineInputBorder()),
                  items: ['Alto', 'Medio', 'Bajo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _noiseLevel = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _scheduleType,
                  decoration: const InputDecoration(labelText: 'Horario', border: OutlineInputBorder()),
                  items: ['Diurno', 'Nocturno', 'Flexible'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _scheduleType = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _socialLevel,
                  decoration: const InputDecoration(labelText: 'Nivel social', border: OutlineInputBorder()),
                  items: ['Muy social', 'Moderado', 'Introvertido'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _socialLevel = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _guestsFrequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia de invitados', border: OutlineInputBorder()),
                  items: ['Frecuente', 'Ocasional', 'Rara vez'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _guestsFrequency = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _drinker,
                  decoration: const InputDecoration(labelText: 'Bebedor', border: OutlineInputBorder()),
                  items: ['Sí', 'No', 'Ocasionalmente'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _drinker = val),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _updateLivingHabits,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: const Text('Guardar Hábitos'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingInfoSection() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: const Text('Información de Vivienda', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('¿Tienes lugar?'),
                  value: _hasPlace,
                  onChanged: (val) => setState(() => _hasPlace = val),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _moveInDateController,
                  decoration: const InputDecoration(labelText: 'Fecha de mudanza', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _budgetMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Presupuesto mínimo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _budgetMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Presupuesto máximo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _updateHousingInfo,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: const Text('Guardar Información de Vivienda'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _moveInDateController.dispose();
    _cityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }
}
