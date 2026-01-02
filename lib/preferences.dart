import 'package:flutter/material.dart';
import 'routes.dart';
import 'auth_service.dart';

class PreferencesPage extends StatefulWidget {
  final String username;
  final String email;

  PreferencesPage({required this.username, required this.email});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  List<String> selectedTags = [];

  final List<String> availableTags = [
    "Trekking",
    "Cocina",
    "Cine",
    "Astrología",
    "Psicología",
    "Comics",
    "Computadora",
    // Agrega más tags según tus necesidades
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tus Intereses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 64,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona tus intereses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige hasta 5 intereses que te representen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedTags.length}/5 seleccionados',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableTags.length,
                      itemBuilder: (context, index) {
                        final tag = availableTags[index];
                        final isSelected = selectedTags.contains(tag);
                        final canSelect = selectedTags.length < 5 || isSelected;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.blue.shade50 
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.blue.shade700 
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              tag,
                              style: TextStyle(
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: canSelect 
                                    ? Colors.black87 
                                    : Colors.grey,
                              ),
                            ),
                            value: isSelected,
                            activeColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onChanged: canSelect
                                ? (value) {
                                    setState(() {
                                      if (value!) {
                                        selectedTags.add(tag);
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selectedTags.isNotEmpty
                          ? () async {
                              if (selectedTags.isEmpty || selectedTags.length > 5) {
                                return;
                              }
                              await AuthService()
                                  .updatePreferences(widget.username, selectedTags);
                              Navigator.pushNamed(context, livingHabitsRoute,
                                  arguments: {
                                    'username': widget.username,
                                    'email': widget.email
                                  });
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
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
