import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController cityController = TextEditingController();
  final TextEditingController moveInDateController = TextEditingController();
  
  bool hasPlace = false;
  String stayDuration = '6months';
  String generalZone = '';
  List<String> selectedZones = [];

  // Zonas disponibles (ejemplo para Buenos Aires - personalizar según ciudad)
  final List<String> availableZones = [
    'Palermo',
    'Recoleta',
    'Belgrano',
    'Caballito',
    'Villa Crespo',
    'Almagro',
    'Núñez',
    'Colegiales',
    'San Telmo',
    'Puerto Madero',
    'Villa Urquiza',
    'Flores',
    'Barracas',
    'La Boca',
    'Boedo',
  ];

  final List<String> generalZones = [
    'Zona Norte',
    'Zona Centro',
    'Zona Sur',
    'Zona Oeste',
  ];

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

              // Ciudad
              _buildSectionTitle('📍 Ubicación'),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Buenos Aires, Madrid, CDMX',
                ),
              ),

              const SizedBox(height: 16),

              // Zona general (pública)
              DropdownButtonFormField<String>(
                value: generalZone.isEmpty ? null : generalZone,
                decoration: const InputDecoration(
                  labelText: 'Zona general (visible en tu perfil)',
                  border: OutlineInputBorder(),
                ),
                items: generalZones.map((zone) {
                  return DropdownMenuItem(value: zone, child: Text(zone));
                }).toList(),
                onChanged: (value) => setState(() => generalZone = value ?? ''),
              ),

              const SizedBox(height: 16),

              // Zonas preferidas (privado)
              const Text(
                'Barrios específicos (privado - solo para matching)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona hasta 5 barrios (opcional)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableZones.map((zone) {
                        final isSelected = selectedZones.contains(zone);
                        return FilterChip(
                          label: Text(zone),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected && selectedZones.length < 5) {
                                selectedZones.add(zone);
                              } else {
                                selectedZones.remove(zone);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Fecha de mudanza
              _buildSectionTitle('📅 ¿Cuándo te mudas?'),
              TextField(
                controller: moveInDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha estimada',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Enero 2026, Q1 2026, Mediados de 2026',
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

    if (cityController.text.isEmpty) {
      _showError('Por favor ingresa la ciudad');
      return;
    }

    if (generalZone.isEmpty) {
      _showError('Por favor selecciona una zona general');
      return;
    }

    try {
      final housingInfoData = {
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'preferredZones': selectedZones,
        'hasPlace': hasPlace,
        'moveInDate': moveInDateController.text,
        'stayDuration': stayDuration,
        'city': cityController.text,
        'generalZone': generalZone,
      };

      await AuthService().updateHousingInfo(
        widget.username,
        housingInfoData,
      );

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
