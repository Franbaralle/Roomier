import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'routes.dart';

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
          'https://apis.datos.gob.ar/georef/api/localidades?provincia=$provinceName&campos=id,nombre&max=200'
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
        Duration(seconds: 3),
        onTimeout: () {
          print('⏱️  Timeout alcanzado');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Vivienda'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏠 Detalles de tu búsqueda',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu presupuesto es privado y nunca se mostrará a otros usuarios',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ¿Tienes lugar o buscas?
              _buildSectionTitle('¿Cuál es tu situación?'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('Busco departamento/casa'),
                      subtitle: const Text('Necesito encontrar un lugar'),
                      value: false,
                      groupValue: hasPlace,
                      onChanged: (value) => setState(() => hasPlace = value!),
                    ),
                    RadioListTile<bool>(
                      title: const Text('Tengo lugar y busco roommate'),
                      subtitle: const Text('Tengo espacio disponible'),
                      value: true,
                      groupValue: hasPlace,
                      onChanged: (value) => setState(() => hasPlace = value!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Presupuesto
              _buildSectionTitle('💰 Presupuesto mensual'),
              const Text(
                'Rango de lo que puedes/quieres pagar por mes (incluyendo expensas)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: budgetMinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Mínimo',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: budgetMaxController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Máximo',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Provincia de origen
              _buildSectionTitle('📍 ¿De dónde sos?'),
              if (isLoadingProvinces)
                const Center(child: CircularProgressIndicator())
              else
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return provinces.map((p) => p['nombre'] as String);
                    }
                    return provinces
                        .map((p) => p['nombre'] as String)
                        .where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase()
                      );
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
                      decoration: const InputDecoration(
                        labelText: 'Provincia/Ciudad de origen',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Buenos Aires, Córdoba, Santa Fe',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Provincia de destino
              _buildSectionTitle('📍 ¿A dónde vas?'),
              if (isLoadingProvinces)
                const Center(child: CircularProgressIndicator())
              else
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return provinces.map((p) => p['nombre'] as String);
                    }
                    return provinces
                        .map((p) => p['nombre'] as String)
                        .where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase()
                      );
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
                      decoration: const InputDecoration(
                        labelText: 'Provincia/Ciudad destino',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Buenos Aires, Córdoba, Santa Fe',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Barrios específicos (condicional según hasPlace)
              if (hasPlace && selectedOriginProvince != null) ...[
                const SizedBox(height: 8),
                _buildSectionTitle('🏙️ Ciudad de origen'),
                if (isLoadingCities)
                  const Center(child: CircularProgressIndicator())
                else if (citiesOrigin.isNotEmpty)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return citiesOrigin.map((c) => c['nombre'] as String);
                      }
                      return citiesOrigin
                          .map((c) => c['nombre'] as String)
                          .where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase()
                        );
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
                        decoration: const InputDecoration(
                          labelText: 'Ciudad (ej: Córdoba, Villa Carlos Paz)',
                          border: OutlineInputBorder(),
                          hintText: 'Escribe para buscar tu ciudad',
                          suffixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                if (selectedOriginCity != null)
                  Text(
                    'Ciudad seleccionada: $selectedOriginCity',
                    style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 12),
                if (selectedOriginCity != null) ...[
                  const Text(
                    'Barrios específicos donde tenés lugar (opcional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildNeighborhoodSelector(true),
                ],
              ],

              if (!hasPlace && selectedDestinationProvince != null) ...[
                const SizedBox(height: 8),
                _buildSectionTitle('🏙️ Ciudad de destino'),
                if (isLoadingCities)
                  const Center(child: CircularProgressIndicator())
                else if (citiesDestination.isNotEmpty)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return citiesDestination.map((c) => c['nombre'] as String);
                      }
                      return citiesDestination
                          .map((c) => c['nombre'] as String)
                          .where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase()
                        );
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
                        decoration: const InputDecoration(
                          labelText: 'Ciudad (ej: Córdoba, Villa Carlos Paz)',
                          border: OutlineInputBorder(),
                          hintText: 'Escribe para buscar tu ciudad',
                          suffixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                if (selectedDestinationCity != null)
                  Text(
                    'Ciudad seleccionada: $selectedDestinationCity',
                    style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 12),
                if (selectedDestinationCity != null) ...[
                  const Text(
                    'Barrios donde buscás (opcional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildNeighborhoodSelector(false),
                ],
              ],

              const SizedBox(height: 24),

              // Fecha de mudanza (solo mes)
              _buildSectionTitle('📅 ¿Cuándo te mudas?'),
              InkWell(
                onTap: () => _selectMoveInMonth(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          color: selectedMoveInMonth != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Duración de estadía
              _buildSectionTitle('⏱️ ¿Por cuánto tiempo?'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('3 meses'),
                      value: '3months',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('6 meses'),
                      value: '6months',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('1 año'),
                      value: '1year',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Largo plazo (1+ año)'),
                      value: 'longterm',
                      groupValue: stayDuration,
                      onChanged: (value) => setState(() => stayDuration = value!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón Continuar
              Center(
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodSelector(bool isOrigin) {
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
      padding: const EdgeInsets.all(12),
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
                size: 16,
                color: hasRealNeighborhoods ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasRealNeighborhoods 
                    ? 'Barrios disponibles - Selecciona hasta 5'
                    : 'Ingresa barrios manualmente (separados por Enter)',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasRealNeighborhoods ? Colors.grey[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Lógica híbrida: Dropdown si hay barrios, TextField libre si no
          if (hasRealNeighborhoods) ...[
            // Campo de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar barrio... (ej: Nueva Córdoba)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  neighborhoodSearchController.text = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // Lista filtrada de barrios
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                          label: Text('$neighborhoodName${neighborhoodName != cityName ? ' ($cityName)' : ''}'),
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
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Centro, Barrio Norte, Cerro de las Rosas\n(Presiona Enter para agregar)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Máximo 5 barrios',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty && selectedNeighborhoods.length < 5) {
                  setState(() {
                    final trimmed = value.trim();
                    if (!selectedNeighborhoods.contains(trimmed)) {
                      if (isOrigin) {
                        selectedNeighborhoodsOrigin.add(trimmed);
                      } else {
                        selectedNeighborhoodsDestination.add(trimmed);
                      }
                    }
                  });
                }
              },
            ),
          ],
          
          if (selectedNeighborhoods.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const Text(
              'Seleccionados:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedNeighborhoods.map((neighborhood) {
                return Chip(
                  label: Text(neighborhood),
                  deleteIcon: const Icon(Icons.close, size: 18),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
