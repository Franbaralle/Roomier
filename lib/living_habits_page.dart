import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';

class LivingHabitsPage extends StatefulWidget {
  final String username;
  final String email;

  LivingHabitsPage({required this.username, required this.email});

  @override
  _LivingHabitsPageState createState() => _LivingHabitsPageState();
}

class _LivingHabitsPageState extends State<LivingHabitsPage> {
  // Valores por defecto
  bool smoker = false;
  bool hasPets = false;
  bool acceptsPets = false;
  String cleanliness = 'normal';
  String noiseLevel = 'normal';
  String schedule = 'normal';
  String socialLevel = 'friendly';
  bool hasGuests = false;
  String drinker = 'social';

  // Deal Breakers
  bool noSmokers = false;
  bool noPets = false;
  bool noParties = false;
  bool noChildren = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos de Convivencia'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuéntanos sobre tus hábitos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta información nos ayuda a encontrar el roommate perfecto para ti',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Sección: Hábitos básicos
              _buildSectionTitle('🚬 Hábitos'),
              _buildSwitch('¿Fumas?', smoker, (value) {
                setState(() => smoker = value);
              }),
              _buildSwitch('¿Tienes mascotas?', hasPets, (value) {
                setState(() => hasPets = value);
              }),
              _buildSwitch('¿Aceptarías mascotas?', acceptsPets, (value) {
                setState(() => acceptsPets = value);
              }),
              _buildSwitch('¿Recibes visitas frecuentes?', hasGuests, (value) {
                setState(() => hasGuests = value);
              }),
              
              const Divider(height: 32),

              // Sección: Limpieza
              _buildSectionTitle('🧹 Limpieza y Orden'),
              _buildRadioGroup(
                'Nivel de limpieza',
                cleanliness,
                [
                  {'value': 'low', 'label': 'Relajado'},
                  {'value': 'normal', 'label': 'Normal'},
                  {'value': 'high', 'label': 'Muy ordenado'},
                ],
                (value) => setState(() => cleanliness = value),
              ),

              const Divider(height: 32),

              // Sección: Ruido
              _buildSectionTitle('🔊 Nivel de Ruido'),
              _buildRadioGroup(
                '¿Qué tan ruidoso eres?',
                noiseLevel,
                [
                  {'value': 'quiet', 'label': 'Tranquilo'},
                  {'value': 'normal', 'label': 'Normal'},
                  {'value': 'social', 'label': 'Social/Fiestas'},
                ],
                (value) => setState(() => noiseLevel = value),
              ),

              const Divider(height: 32),

              // Sección: Horarios
              _buildSectionTitle('⏰ Horarios'),
              _buildRadioGroup(
                'Tu rutina diaria',
                schedule,
                [
                  {'value': 'early', 'label': 'Madrugador (duermo temprano)'},
                  {'value': 'normal', 'label': 'Normal'},
                  {'value': 'night', 'label': 'Nocturno (activo de noche)'},
                ],
                (value) => setState(() => schedule = value),
              ),

              const Divider(height: 32),

              // Sección: Socialización
              _buildSectionTitle('👥 Nivel Social'),
              _buildRadioGroup(
                '¿Cómo te gusta convivir?',
                socialLevel,
                [
                  {'value': 'independent', 'label': 'Independiente (cada uno a lo suyo)'},
                  {'value': 'friendly', 'label': 'Amigable (charlar de vez en cuando)'},
                  {'value': 'very_social', 'label': 'Muy social (compartir tiempo juntos)'},
                ],
                (value) => setState(() => socialLevel = value),
              ),

              const Divider(height: 32),

              // Sección: Alcohol
              _buildSectionTitle('🍺 Consumo de Alcohol'),
              _buildRadioGroup(
                'Frecuencia',
                drinker,
                [
                  {'value': 'never', 'label': 'Nunca'},
                  {'value': 'social', 'label': 'Social (ocasionalmente)'},
                  {'value': 'regular', 'label': 'Regularmente'},
                ],
                (value) => setState(() => drinker = value),
              ),

              const Divider(height: 32),

              // Sección: Deal Breakers
              _buildSectionTitle('🚫 Deal Breakers (No puedo convivir con...)'),
              const Text(
                'Marca lo que definitivamente NO aceptarías',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _buildSwitch('Fumadores', noSmokers, (value) {
                setState(() => noSmokers = value);
              }),
              _buildSwitch('Mascotas', noPets, (value) {
                setState(() => noPets = value);
              }),
              _buildSwitch('Fiestas en casa', noParties, (value) {
                setState(() => noParties = value);
              }),
              _buildSwitch('Niños', noChildren, (value) {
                setState(() => noChildren = value);
              }),

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

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRadioGroup(
    String title,
    String currentValue,
    List<Map<String, String>> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option['label']!),
            value: option['value']!,
            groupValue: currentValue,
            onChanged: (value) => onChanged(value!),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Future<void> _handleContinue() async {
    try {
      final livingHabitsData = {
        'smoker': smoker,
        'hasPets': hasPets,
        'acceptsPets': acceptsPets,
        'cleanliness': cleanliness,
        'noiseLevel': noiseLevel,
        'schedule': schedule,
        'socialLevel': socialLevel,
        'hasGuests': hasGuests,
        'drinker': drinker,
      };

      final dealBreakersData = {
        'noSmokers': noSmokers,
        'noPets': noPets,
        'noParties': noParties,
        'noChildren': noChildren,
      };

      await AuthService().updateLivingHabits(
        widget.username,
        livingHabitsData,
        dealBreakersData,
      );

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
