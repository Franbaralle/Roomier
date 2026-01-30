import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'routes.dart';

// Función para normalizar texto (quitar acentos)
String _normalizeText(String text) {
  const withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
  const withoutAccents = 'aeiouAEIOUnNuU';
  
  String result = text;
  for (int i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return result.toLowerCase();
}

class HousingInfoPage extends StatefulWidget {
  final String username;
  final String email;

  HousingInfoPage({required this.username, required this.email});

  @override
  _HousingInfoPageState createState() => _HousingInfoPageState();
}

class _HousingInfoPageState extends State<HousingInfoPage> {
  final TextEditingController budgetMinController = TextEditingController();
  final TextEditingController budgetMaxController = TextEditingController();
  final TextEditingController originProvinceController = TextEditingController();
  final TextEditingController destinationProvinceController = TextEditingController();
  final TextEditingController originCityController = TextEditingController();
  final TextEditingController destinationCityController = TextEditingController();
  final TextEditingController neighborhoodSearchController = TextEditingController();
  final TextEditingController freeNeighborhoodOriginController = TextEditingController();
  final TextEditingController freeNeighborhoodDestinationController = TextEditingController();
  
  bool hasPlace = false;
  String stayDuration = '6months';
  String? selectedMoveInMonth; // Formato: "01/2026"
  
  // API Georef data
  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> citiesOrigin = [];
  List<Map<String, dynamic>> citiesDestination = [];
  List<Map<String, dynamic>> neighborhoodsOrigin = []; // Cambiado a Map para incluir _id
  List<Map<String, dynamic>> neighborhoodsDestination = [];
  List<String> selectedNeighborhoodsOrigin = [];
  List<String> selectedNeighborhoodsDestination = [];
  
  String? selectedOriginProvince;
  String? selectedDestinationProvince;
  String? selectedOriginCity;
  String? selectedDestinationCity;
  String? selectedOriginCityId; // ID de Georef para la ciudad de origen
  String? selectedDestinationCityId;
  
  bool isLoadingProvinces = false;
  bool isLoadingCities = false;
  bool isLoadingNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  // Cargar provincias desde API Georef
  Future<void> _loadProvinces() async {
    setState(() => isLoadingProvinces = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://apis.datos.gob.ar/georef/api/provincias?campos=id,nombre'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          provinces = List<Map<String, dynamic>>.from(data['provincias']);
          isLoadingProvinces = false;
        });
      }
    } catch (e) {
      print('Error loading provinces: $e');
      setState(() => isLoadingProvinces = false);
      _showError('Error al cargar provincias. Verifica tu conexión.');
    }
  }

  // Cargar ciudades de una provincia
  Future<void> _loadCities(String provinceName, bool isOrigin) async {
    setState(() => isLoadingCities = true);
    
    try {
      final response = await http.get(
        Uri.parse(
          'https://apis.datos.gob.ar/georef/api/localidades?provincia=$provinceName&campos=id,nombre&max=1000'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final localities = List<Map<String, dynamic>>.from(data['localidades']);
        
        setState(() {
          if (isOrigin) {
            citiesOrigin = localities;
          } else {
            citiesDestination = localities;
          }
          isLoadingCities = false;
        });
        
        print('✓ ${localities.length} ciudades cargadas para $provinceName');
      }
    } catch (e) {
      print('Error loading cities: $e');
      setState(() => isLoadingCities = false);
    }
  }

  // Cargar barrios de una ciudad específica
  Future<void> _loadNeighborhoodsForCity(String cityId, String cityName, bool isOrigin) async {
    setState(() => isLoadingNeighborhoods = true);
    
    try {
      final baseUrl = AuthService.apiUrl.replaceAll('/auth', '');
      final url = '$baseUrl/neighborhoods?cityId=$cityId';
      
      print('🔍 Consultando barrios de $cityName (ID: $cityId)...');
      print('   URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('⏱️  Timeout alcanzado (15s)');
          throw TimeoutException('Timeout al consultar barrios');
        },
      );
      
      print('   Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('  → ${data['count']} barrios encontrados');
        
        List<Map<String, dynamic>> neighborhoods = [];
        
        if (data['count'] > 0) {
          // Hay barrios cargados
          for (var neighborhood in data['data']) {
            neighborhoods.add({
              'id': neighborhood['_id'],
              'name': neighborhood['name'],
              'cityName': neighborhood['cityName'],
              'cityId': cityId,
              'hasData': true
            });
          }
        }
        
        setState(() {
          if (isOrigin) {
            neighborhoodsOrigin = neighborhoods;
          } else {
            neighborhoodsDestination = neighborhoods;
          }
          isLoadingNeighborhoods = false;
        });
        
        print('✅ Barrios cargados: ${neighborhoods.length}');
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading neighborhoods: $e');
      setState(() {
        isLoadingNeighborhoods = false;
        // Si hay error, dejar lista vacía para que se use texto libre
        if (isOrigin) {
          neighborhoodsOrigin = [];
        } else {
          neighborhoodsDestination = [];
        }
      });
      
      // Mostrar mensaje al usuario
      _showError('No se pudieron cargar los barrios. Puedes escribirlos manualmente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isSmallScreen = width < 360;
    final isMediumScreen = width >= 360 && width < 600;
    final padding = width < 600 ? 16.0 : 24.0;
    final titleSize = isSmallScreen ? 20.0 : 24.0;
    final sectionSpacing = isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información de Vivienda',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏠 Detalles de tu búsqueda',
                  style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.01),
                Container(
                  padding: EdgeInsets.all(padding * 0.75),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: isSmallScreen ? 14 : 16, color: Colors.blue),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          'Tu presupuesto es privado y nunca se mostrará a otros usuarios',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sectionSpacing),

                // ¿Tienes lugar o buscas?
                _buildSectionTitle('¿Cuál es tu situación?', context),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: Text('Busco departamento/casa', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                        subtitle: Text('Necesito encontrar un lugar', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                        value: false,
                        groupValue: hasPlace,
                        onChanged: (value) => setState(() => hasPlace = value!),
                      ),
                      RadioListTile<bool>(
                        title: Text('Tengo lugar y busco roommate', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                        subtitle: Text('Tengo espacio disponible', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                        value: true,
                        groupValue: hasPlace,
                        onChanged: (value) => setState(() => hasPlace = value!),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sectionSpacing),

                // Presupuesto
                _buildSectionTitle('💰 Presupuesto mensual', context),
                Text(
                  'Rango de lo que puedes/quieres pagar por mes (incluyendo expensas)',
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey),
                ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: budgetMinController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: 'Mínimo',
                          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          prefixText: '\$',
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.625,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: TextField(
                        controller: budgetMaxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: 'Máximo',
                          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          prefixText: '\$',
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.625,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: sectionSpacing),

              // Provincia de origen
              _buildSectionTitle('📍 ¿De dónde sos?', context),
              if (isLoadingProvinces)
                const Center(child: CircularProgressIndicator())
              else
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return provinces.map((p) => p['nombre'] as String);
                    }
                    final normalizedSearch = _normalizeText(textEditingValue.text);
                    return provinces
                        .map((p) => p['nombre'] as String)
                        .where((String option) {
                      return _normalizeText(option).contains(normalizedSearch);
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      selectedOriginProvince = selection;
                      originProvinceController.text = selection;
                      selectedNeighborhoodsOrigin.clear();
                      selectedOriginCity = null;
                      neighborhoodsOrigin = [];
                    });
                    if (hasPlace) {
                      _loadCities(selection, true);
                    }
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    originProvinceController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'Provincia/Ciudad de origen',
                        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        border: const OutlineInputBorder(),
                        hintText: 'Ej: Buenos Aires, Córdoba, Santa Fe',
                        hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding * 0.75,
                          vertical: padding * 0.625,
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: height * 0.02),

              // Provincia de destino
              _buildSectionTitle('📍 ¿A dónde vas?', context),
              if (isLoadingProvinces)
                const Center(child: CircularProgressIndicator())
              else
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return provinces.map((p) => p['nombre'] as String);
                    }
                    final normalizedSearch = _normalizeText(textEditingValue.text);
                    return provinces
                        .map((p) => p['nombre'] as String)
                        .where((String option) {
                      return _normalizeText(option).contains(normalizedSearch);
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      selectedDestinationProvince = selection;
                      destinationProvinceController.text = selection;
                      selectedNeighborhoodsDestination.clear();
                      selectedDestinationCity = null;
                      neighborhoodsDestination = [];
                    });
                    if (!hasPlace) {
                      _loadCities(selection, false);
                    }
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    destinationProvinceController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'Provincia/Ciudad destino',
                        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        border: const OutlineInputBorder(),
                        hintText: 'Ej: Buenos Aires, Córdoba, Santa Fe',
                        hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding * 0.75,
                          vertical: padding * 0.625,
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: height * 0.02),

              // Barrios específicos (condicional según hasPlace)
              if (hasPlace && selectedOriginProvince != null) ...[
                SizedBox(height: height * 0.01),
                _buildSectionTitle('🏙️ Ciudad de origen', context),
                if (isLoadingCities)
                  const Center(child: CircularProgressIndicator())
                else if (citiesOrigin.isNotEmpty)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return citiesOrigin.map((c) => c['nombre'] as String);
                      }
                      final normalizedSearch = _normalizeText(textEditingValue.text);
                      return citiesOrigin
                          .map((c) => c['nombre'] as String)
                          .where((String option) {
                        return _normalizeText(option).contains(normalizedSearch);
                      });
                    },
                    onSelected: (String selection) {
                      final selectedCity = citiesOrigin.firstWhere((c) => c['nombre'] == selection);
                      setState(() {
                        selectedOriginCity = selection;
                        selectedOriginCityId = selectedCity['id'];
                        originCityController.text = selection;
                        selectedNeighborhoodsOrigin.clear();
                      });
                      // Cargar barrios de esta ciudad
                      _loadNeighborhoodsForCity(selectedCity['id'], selection, true);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      originCityController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: 'Ciudad (ej: Córdoba, Villa Carlos Paz)',
                          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          border: const OutlineInputBorder(),
                          hintText: 'Escribe para buscar tu ciudad',
                          hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          suffixIcon: const Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.625,
                          ),
                        ),
                      );
                    },
                  ),
                SizedBox(height: height * 0.015),
                if (selectedOriginCity != null)
                  Text(
                    'Ciudad seleccionada: $selectedOriginCity',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: height * 0.015),
                if (selectedOriginCity != null) ...[
                  Text(
                    'Barrios específicos donde tenés lugar (opcional)',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: height * 0.01),
                  _buildNeighborhoodSelector(true, context),
                ],
              ],

              if (!hasPlace && selectedDestinationProvince != null) ...[
                SizedBox(height: height * 0.01),
                _buildSectionTitle('🏙️ Ciudad de destino', context),
                if (isLoadingCities)
                  const Center(child: CircularProgressIndicator())
                else if (citiesDestination.isNotEmpty)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return citiesDestination.map((c) => c['nombre'] as String);
                      }
                      final normalizedSearch = _normalizeText(textEditingValue.text);
                      return citiesDestination
                          .map((c) => c['nombre'] as String)
                          .where((String option) {
                        return _normalizeText(option).contains(normalizedSearch);
                      });
                    },
                    onSelected: (String selection) {
                      final selectedCity = citiesDestination.firstWhere((c) => c['nombre'] == selection);
                      setState(() {
                        selectedDestinationCity = selection;
                        selectedDestinationCityId = selectedCity['id'];
                        destinationCityController.text = selection;
                        selectedNeighborhoodsDestination.clear();
                      });
                      // Cargar barrios de esta ciudad
                      _loadNeighborhoodsForCity(selectedCity['id'], selection, false);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      destinationCityController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: 'Ciudad (ej: Córdoba, Villa Carlos Paz)',
                          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          border: const OutlineInputBorder(),
                          hintText: 'Escribe para buscar tu ciudad',
                          hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          suffixIcon: const Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.625,
                          ),
                        ),
                      );
                    },
                  ),
                SizedBox(height: height * 0.015),
                if (selectedDestinationCity != null)
                  Text(
                    'Ciudad seleccionada: $selectedDestinationCity',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: height * 0.015),
                if (selectedDestinationCity != null) ...[
                  Text(
                    'Barrios donde buscás (opcional)',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: height * 0.01),
                  _buildNeighborhoodSelector(false, context),
                ],
              ],

              SizedBox(height: sectionSpacing),

              // Fecha de mudanza (solo mes)
              _buildSectionTitle('📅 ¿Cuándo te mudas?', context),
              InkWell(
                onTap: () => _selectMoveInMonth(context),
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedMoveInMonth != null 
                            ? _formatMonthYear(selectedMoveInMonth!)
                            : 'Seleccionar mes',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: selectedMoveInMonth != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey, size: isSmallScreen ? 18 : 20),
                    ],
                  ),
                ),
              ),

              SizedBox(height: sectionSpacing),

              // Duración de estadía
              _buildSectionTitle('⏱️ ¿Por cuánto tiempo?', context),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('3 meses', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                      value: '3months',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: Text('6 meses', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                      value: '6months',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: Text('1 año', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                      value: '1year',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: Text('Largo plazo (1+ año)', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                      value: 'longterm',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.33),

              // Botón Continuar
              Center(
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(width * 0.5, height * 0.06),
                    padding: EdgeInsets.symmetric(horizontal: padding * 2, vertical: padding),
                  ),
                  child: Text('Continuar', style: TextStyle(fontSize: isSmallScreen ? 16 : 18)),
                ),
              ),
              SizedBox(height: height * 0.025),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNeighborhoodSelector(bool isOrigin, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isSmallScreen = width < 360;
    final padding = width < 600 ? 12.0 : 16.0;
    
    final neighborhoods = isOrigin ? neighborhoodsOrigin : neighborhoodsDestination;
    final selectedNeighborhoods = isOrigin ? selectedNeighborhoodsOrigin : selectedNeighborhoodsDestination;
    
    if (isLoadingNeighborhoods) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Verificar si hay barrios reales o no hay datos
    final hasRealNeighborhoods = neighborhoods.isNotEmpty && neighborhoods.any((n) => n['hasData'] == true);
    
    print('🔍 _buildNeighborhoodSelector:');
    print('   Total neighborhoods: ${neighborhoods.length}');
    print('   Has real neighborhoods: $hasRealNeighborhoods');
    if (neighborhoods.isNotEmpty) {
      print('   First item: ${neighborhoods.first}');
    }
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRealNeighborhoods ? Icons.check_circle : Icons.edit_location_alt,
                size: isSmallScreen ? 14 : 16,
                color: hasRealNeighborhoods ? Colors.green : Colors.orange,
              ),
              SizedBox(width: width * 0.02),
              Expanded(
                child: Text(
                  hasRealNeighborhoods 
                    ? 'Barrios disponibles - Selecciona hasta 5'
                    : 'Ingresa barrios manualmente (separados por Enter)',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: hasRealNeighborhoods ? Colors.grey[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: padding),
          
          // Lógica híbrida: Dropdown si hay barrios, TextField libre si no
          if (hasRealNeighborhoods) ...[
            // Campo de búsqueda
            TextField(
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              decoration: InputDecoration(
                hintText: 'Buscar barrio... (ej: Nueva Córdoba)',
                hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.67),
              ),
              onChanged: (value) {
                setState(() {
                  neighborhoodSearchController.text = value;
                });
              },
            ),
            SizedBox(height: padding),
            // Lista filtrada de barrios
            Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.25),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: width * 0.02,
                  runSpacing: width * 0.02,
                  children: neighborhoods
                      .where((neighborhood) {
                        if (neighborhoodSearchController.text.isEmpty) {
                          return true;
                        }
                        return (neighborhood['name'] as String).toLowerCase().contains(
                          neighborhoodSearchController.text.toLowerCase()
                        );
                      })
                      .take(20) // Mostrar máximo 20 resultados
                      .map((neighborhood) {
                        final neighborhoodName = neighborhood['name'] as String;
                        final cityName = neighborhood['cityName'] as String;
                        final isSelected = selectedNeighborhoods.contains(neighborhoodName);
                        return FilterChip(
                          label: Text(
                            '$neighborhoodName${neighborhoodName != cityName ? ' ($cityName)' : ''}',
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected && selectedNeighborhoods.length < 5) {
                                if (isOrigin) {
                                  selectedNeighborhoodsOrigin.add(neighborhoodName);
                                } else {
                                  selectedNeighborhoodsDestination.add(neighborhoodName);
                                }
                              } else {
                                if (isOrigin) {
                                  selectedNeighborhoodsOrigin.remove(neighborhoodName);
                                } else {
                                  selectedNeighborhoodsDestination.remove(neighborhoodName);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
          ] else ...[
            // Campo de texto libre para ciudades sin barrios cargados
            Container(
              padding: EdgeInsets.all(padding * 0.75),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                  SizedBox(width: padding * 0.5),
                  Expanded(
                    child: Text(
                      'No tenemos barrios cargados para esta ciudad. Ayúdanos escribiendo los que conozcas (máx. 5)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: padding),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: isOrigin ? freeNeighborhoodOriginController : freeNeighborhoodDestinationController,
                    enabled: selectedNeighborhoods.length < 5,
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    decoration: InputDecoration(
                      hintText: selectedNeighborhoods.length >= 5 
                          ? 'Límite alcanzado (5 barrios)'
                          : 'Ej: Centro, Barrio Norte...',
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding * 0.67,
                      ),
                      suffixIcon: selectedNeighborhoods.length >= 5
                          ? Icon(Icons.block, color: Colors.grey)
                          : null,
                    ),
                    onSubmitted: selectedNeighborhoods.length < 5 ? (value) {
                      if (value.isNotEmpty) {
                        final trimmed = value.trim();
                        if (!selectedNeighborhoods.contains(trimmed)) {
                          setState(() {
                            if (isOrigin) {
                              selectedNeighborhoodsOrigin.add(trimmed);
                              freeNeighborhoodOriginController.clear();
                            } else {
                              selectedNeighborhoodsDestination.add(trimmed);
                              freeNeighborhoodDestinationController.clear();
                            }
                          });
                        }
                      }
                    } : null,
                  ),
                ),
                SizedBox(width: padding * 0.5),
                ElevatedButton(
                  onPressed: selectedNeighborhoods.length < 5 ? () {
                    final controller = isOrigin ? freeNeighborhoodOriginController : freeNeighborhoodDestinationController;
                    final value = controller.text.trim();
                    if (value.isNotEmpty && !selectedNeighborhoods.contains(value)) {
                      setState(() {
                        if (isOrigin) {
                          selectedNeighborhoodsOrigin.add(value);
                          freeNeighborhoodOriginController.clear();
                        } else {
                          selectedNeighborhoodsDestination.add(value);
                          freeNeighborhoodDestinationController.clear();
                        }
                      });
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: padding * 0.75,
                    ),
                  ),
                  child: Icon(Icons.add, size: isSmallScreen ? 20 : 24),
                ),
              ],
            ),
            if (selectedNeighborhoods.length >= 5)
              Padding(
                padding: EdgeInsets.only(top: padding * 0.5),
                child: Text(
                  '✓ Has alcanzado el límite de 5 barrios',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
          
          if (selectedNeighborhoods.isNotEmpty) ...[
            SizedBox(height: padding * 0.67),
            const Divider(),
            Text(
              'Seleccionados:',
              style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: padding * 0.33),
            Wrap(
              spacing: width * 0.02,
              runSpacing: width * 0.02,
              children: selectedNeighborhoods.map((neighborhood) {
                return Chip(
                  label: Text(neighborhood, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  deleteIcon: Icon(Icons.close, size: isSmallScreen ? 16 : 18),
                  onDeleted: () {
                    setState(() {
                      if (isOrigin) {
                        selectedNeighborhoodsOrigin.remove(neighborhood);
                      } else {
                        selectedNeighborhoodsDestination.remove(neighborhood);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectMoveInMonth(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedMoveInMonth != null
        ? DateTime(
            int.parse(selectedMoveInMonth!.split('/')[1]),
            int.parse(selectedMoveInMonth!.split('/')[0]),
          )
        : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecciona el mes de mudanza',
      fieldLabelText: 'Mes/Año',
    );

    if (picked != null) {
      setState(() {
        // Formato: MM/YYYY
        selectedMoveInMonth = '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String _formatMonthYear(String monthYear) {
    final parts = monthYear.split('/');
    if (parts.length != 2) return monthYear;
    
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    final month = int.parse(parts[0]);
    final year = parts[1];
    
    return '${monthNames[month - 1]} $year';
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.015),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    // Validaciones
    if (budgetMinController.text.isEmpty || budgetMaxController.text.isEmpty) {
      _showError('Por favor ingresa tu rango de presupuesto');
      return;
    }

    final budgetMin = int.tryParse(budgetMinController.text);
    final budgetMax = int.tryParse(budgetMaxController.text);

    if (budgetMin == null || budgetMax == null) {
      _showError('Por favor ingresa valores numéricos válidos');
      return;
    }

    if (budgetMin > budgetMax) {
      _showError('El presupuesto mínimo no puede ser mayor al máximo');
      return;
    }

    if (selectedOriginProvince == null || selectedOriginProvince!.isEmpty) {
      _showError('Por favor selecciona tu provincia de origen');
      return;
    }

    if (selectedDestinationProvince == null || selectedDestinationProvince!.isEmpty) {
      _showError('Por favor selecciona tu provincia destino');
      return;
    }

    try {
      // Enviar barrios sugeridos al backend si los hay
      await _sendSuggestedNeighborhoods();

      final housingInfoData = {
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'hasPlace': hasPlace,
        'moveInDate': selectedMoveInMonth ?? '',
        'stayDuration': stayDuration,
        'originProvince': selectedOriginProvince,
        'destinationProvince': selectedDestinationProvince,
        'specificNeighborhoodsOrigin': selectedNeighborhoodsOrigin,
        'specificNeighborhoodsDestination': selectedNeighborhoodsDestination,
        
        // Campos legacy para compatibilidad
        'city': selectedDestinationProvince, // Usar destino como ciudad principal
        'preferredZones': hasPlace ? selectedNeighborhoodsOrigin : selectedNeighborhoodsDestination,
      };

      // Guardar temporalmente en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_register_housing_info', json.encode(housingInfoData));

      // Continuar con el flujo normal (personal info o profile photo)
      Navigator.pushNamed(
        context,
        registerPersonalInfoRoute,
        arguments: {
          'username': widget.username,
          'email': widget.email,
        },
      );
    } catch (error) {
      _showError('Error: $error');
    }
  }

  /// Envía los barrios sugeridos al backend para análisis
  Future<void> _sendSuggestedNeighborhoods() async {
    try {
      // Verificar si hay barrios sugeridos de origen (sin data en BD)
      if (hasPlace && 
          selectedNeighborhoodsOrigin.isNotEmpty && 
          selectedOriginCityId != null &&
          neighborhoodsOrigin.isEmpty) { // Solo si no había barrios en BD
        
        await _submitSuggestions(
          selectedNeighborhoodsOrigin,
          selectedOriginCityId!,
          selectedOriginCity ?? '',
          selectedOriginProvince ?? ''
        );
      }

      // Verificar si hay barrios sugeridos de destino (sin data en BD)
      if (!hasPlace && 
          selectedNeighborhoodsDestination.isNotEmpty && 
          selectedDestinationCityId != null &&
          neighborhoodsDestination.isEmpty) { // Solo si no había barrios en BD
        
        await _submitSuggestions(
          selectedNeighborhoodsDestination,
          selectedDestinationCityId!,
          selectedDestinationCity ?? '',
          selectedDestinationProvince ?? ''
        );
      }
    } catch (e) {
      // No fallar el registro si falla el envío de sugerencias
      print('⚠️ Error al enviar sugerencias de barrios: $e');
    }
  }

  /// Envía las sugerencias al endpoint del backend
  Future<void> _submitSuggestions(
    List<String> neighborhoods,
    String cityId,
    String cityName,
    String provinceName
  ) async {
    try {
      final baseUrl = AuthService.apiUrl.replaceAll('/auth', '');
      final url = '$baseUrl/neighborhoods/suggest';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'neighborhoods': neighborhoods,
          'cityId': cityId,
          'cityName': cityName,
          'provinceName': provinceName,
          'userEmail': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Sugerencias de barrios enviadas: ${neighborhoods.length} para $cityName');
      } else {
        print('⚠️ Error al enviar sugerencias: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error de red al enviar sugerencias: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
