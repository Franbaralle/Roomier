import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'routes.dart';
import 'auth_service.dart';

class DatePage extends StatefulWidget {
  @override
  _DatePageState createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  DateTime? selectedDate = DateTime.now();
  final DateTime currentDate = DateTime.now();
  String? warningMessage;

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(currentDate.year - 100),
      lastDate: currentDate,
    );

    if (picked != null && picked != AuthService.getSelectedDate()) {
      setState(() {
        AuthService.setSelectedDate(picked);
        selectedDate = picked;
        // Limpiar cualquier advertencia previa al seleccionar una nueva fecha.
        _clearWarning();
      });
    }
  }

  bool isUnder18(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    DateTime minimumDate =
        DateTime(currentDate.year - 18, currentDate.month, currentDate.day);
    return birthDate.isAfter(minimumDate);
  }

  void _showWarning(String message) {
    setState(() {
      warningMessage = message;
    });
  }

  void _clearWarning() {
    setState(() {
      warningMessage = null;
    });
  }

  void _registerWithAuthService() async {
    if (selectedDate != null) {
      if (isUnder18(selectedDate!)) {
        _showWarning('Para continuar, debes ser de 18 años.');
      } else {
        try {
          AuthService.setSelectedDate(selectedDate!);
          Navigator.pushNamed(context, registerRoute);
        } catch (error) {
          print('Error durante la configuración de la fecha: $error');
        }
      }
    } else {
      _showWarning('Por favor, selecciona tu fecha de nacimiento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fecha de Nacimiento'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selecciona tu fecha de nacimiento',
              style: TextStyle(fontSize: 18.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _selectDate(context);
              },
              child: Text(selectedDate != null
                  ? 'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                  : 'Seleccionar Fecha'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _registerWithAuthService();
              },
              child: Text('Continuar'),
            ),
            Container(
              margin: EdgeInsets.only(
                  top: 8), // Ajusta el margen según sea necesario
              child: Text(
                warningMessage ?? '', // El mensaje de advertencia
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

