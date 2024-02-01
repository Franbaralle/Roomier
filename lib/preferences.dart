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
      appBar: AppBar(
        title: const Text('Preferencias'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selecciona tus preferencias (hasta 5)',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: availableTags.length,
                itemBuilder: (context, index) {
                  final tag = availableTags[index];
                  return CheckboxListTile(
                    title: Text(tag),
                    value: selectedTags.contains(tag),
                    onChanged: (value) {
                      setState(() {
                        if (value!) {
                          if (selectedTags.length < 5) {
                            selectedTags.add(tag);
                          }
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                List<String> selectedPreferences = selectedTags;
                if (selectedPreferences.isEmpty ||
                    selectedPreferences.length > 5) {
                  return;
                }
                await AuthService()
                    .updatePreferences(widget.username, selectedPreferences);
                Navigator.pushNamed(context, registerPersonalInfoRoute, arguments: {'username': widget.username, 'email': widget.email});
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
