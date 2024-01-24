import 'package:flutter/material.dart';
import 'routes.dart';

class PreferencesPage extends StatefulWidget {
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
                          // Agrega el tag si fue seleccionado
                          if (selectedTags.length < 5) {
                            selectedTags.add(tag);
                          }
                        } else {
                          // Remueve el tag si fue deseleccionado
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
              onPressed: () {
                // Navegar a la página de Datos Personales
                    Navigator.pushNamed(
                      context,
                      registerPersonalInfoRoute
                    );
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
