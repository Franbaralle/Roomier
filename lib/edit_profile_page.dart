import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Controllers para intereses
  List<TextEditingController> _interestControllers = List.generate(5, (_) => TextEditingController());

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
  final TextEditingController _cityController = TextEditingController();
  String? _generalZone;
  List<String> _preferredZones = [];
  final TextEditingController _budgetMinController = TextEditingController();
  final TextEditingController _budgetMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
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
      // Cargar intereses (preferences es un array directamente)
      final preferencesData = widget.currentUserData['preferences'];
      List<String> interests = [];
      if (preferencesData != null && preferencesData is List) {
        interests = preferencesData.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      for (int i = 0; i < interests.length && i < 5; i++) {
        _interestControllers[i].text = interests[i];
      }
    } catch (e) {
      print('Error loading personal info: $e');
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
      _cityController.text = widget.currentUserData['housingInfo']?['city']?.toString() ?? '';
      _generalZone = widget.currentUserData['housingInfo']?['generalZone']?.toString();
      
      // Manejar preferredZones de forma segura
      final prefZones = widget.currentUserData['housingInfo']?['preferredZones'];
      if (prefZones != null && prefZones is List) {
        _preferredZones = prefZones.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      } else {
        _preferredZones = [];
      }
      
      _budgetMinController.text = widget.currentUserData['housingInfo']?['budgetMin']?.toString() ?? '';
      _budgetMaxController.text = widget.currentUserData['housingInfo']?['budgetMax']?.toString() ?? '';
    } catch (e) {
      print('Error loading housing info: $e');
    }
  }



  Future<void> _updateInterests() async {
    setState(() => _isLoading = true);
    try {
      List<String> interests = _interestControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final token = authService.loadUserData('accessToken');
      final response = await http.put(
        Uri.parse('${AuthService.api}/edit-profile/interests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'interests': interests}),
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
          'city': _cityController.text,
          'generalZone': _generalZone,
          'preferredZones': _preferredZones,
          'budgetMin': int.tryParse(_budgetMinController.text),
          'budgetMax': int.tryParse(_budgetMaxController.text),
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
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: const Text('Intereses (máx. 5)', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _interestControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Interés ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _updateInterests,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: const Text('Guardar Intereses'),
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
    for (var controller in _interestControllers) {
      controller.dispose();
    }
    _moveInDateController.dispose();
    _cityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }
}
