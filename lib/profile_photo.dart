import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rommier/routes.dart';
import 'auth_service.dart';

class ProfilePhotoPage extends StatefulWidget {
  final String username;
  final String email;

  ProfilePhotoPage({required this.username, required this.email});

  @override
  _ProfilePhotoPageState createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  late Uint8List _imageData;

  @override
  void initState() {
    super.initState();
    _imageData = Uint8List(0);
  }

  Future<void> _updateProfilePhoto() async {
    try {
      // Recopilar TODOS los datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Datos básicos
      final username = prefs.getString('temp_register_username') ?? widget.username;
      final password = prefs.getString('temp_register_password') ?? '';
      final email = prefs.getString('temp_register_email') ?? widget.email;
      final birthdate = prefs.getString('temp_register_birthdate') ?? '';
      final gender = prefs.getString('temp_register_gender') ?? 'other'; // Género del usuario
      
      // Preferencias
      final preferencesJson = prefs.getString('temp_register_preferences');
      final preferences = preferencesJson != null ? json.decode(preferencesJson) : {};
      
      // Preferencias de roommate
      final roommateGender = prefs.getString('temp_register_roommate_gender') ?? 'both';
      final roommateMinAge = prefs.getInt('temp_register_roommate_min_age') ?? 18;
      final roommateMaxAge = prefs.getInt('temp_register_roommate_max_age') ?? 65;
      
      // Living habits
      final livingHabitsJson = prefs.getString('temp_register_living_habits');
      final livingHabits = livingHabitsJson != null ? json.decode(livingHabitsJson) : {};
      
      final dealBreakersJson = prefs.getString('temp_register_deal_breakers');
      final dealBreakers = dealBreakersJson != null ? json.decode(dealBreakersJson) : {};
      
      // Housing info
      final housingInfoJson = prefs.getString('temp_register_housing_info');
      final housingInfo = housingInfoJson != null ? json.decode(housingInfoJson) : {};
      
      // Personal info
      final job = prefs.getString('temp_register_job') ?? '';
      final religion = prefs.getString('temp_register_religion') ?? '';
      final politicPreferences = prefs.getString('temp_register_politic_preferences') ?? '';
      final aboutMe = prefs.getString('temp_register_about_me') ?? '';
      
      // Preparar foto de perfil (base64)
      String? profilePhotoBase64;
      if (_imageData.isNotEmpty) {
        profilePhotoBase64 = base64Encode(_imageData);
      }
      
      // Construir el objeto de registro completo
      final registrationData = {
        'username': username,
        'password': password,
        'email': email,
        'birthdate': birthdate,
        'gender': gender, // Agregar género del usuario
        'preferences': preferences,
        'roommatePreferences': {
          'gender': roommateGender,
          'minAge': roommateMinAge,
          'maxAge': roommateMaxAge,
        },
        'livingHabits': livingHabits,
        'dealBreakers': dealBreakers,
        'housingInfo': housingInfo,
        'personalInfo': {
          'job': job,
          'religion': religion,
          'politicPreferences': politicPreferences,
          'aboutMe': aboutMe,
        },
        if (profilePhotoBase64 != null) 'profilePhoto': profilePhotoBase64,
      };
      
      // Enviar todo al backend
      await AuthService().completeRegistration(registrationData);
      
      // Limpiar SharedPreferences
      await prefs.remove('temp_register_username');
      await prefs.remove('temp_register_password');
      await prefs.remove('temp_register_email');
      await prefs.remove('temp_register_gender');
      await prefs.remove('temp_register_birthdate');
      await prefs.remove('temp_register_preferences');
      await prefs.remove('temp_register_roommate_gender');
      await prefs.remove('temp_register_roommate_min_age');
      await prefs.remove('temp_register_roommate_max_age');
      await prefs.remove('temp_register_living_habits');
      await prefs.remove('temp_register_deal_breakers');
      await prefs.remove('temp_register_housing_info');
      await prefs.remove('temp_register_job');
      await prefs.remove('temp_register_religion');
      await prefs.remove('temp_register_politic_preferences');
      await prefs.remove('temp_register_about_me');
      
      // Si el email no es el del administrador, ir directo al login
      // (el backend ya marcó como verificado automáticamente)
      if (email != 'baralle2014@gmail.com') {
        // Mostrar mensaje y redirigir al login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Esperar un momento y ir al login
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
      } else {
        // Si es el email del admin, ir a verificación de código
        Navigator.pushNamed(context, emailRoute, arguments: {'email': email});
      }
    } catch (error) {
      print('Error al completar el registro: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        print('[PROFILE_PHOTO] Imagen seleccionada: ${pickedFile.path}');
        
        // Recortar la imagen
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Cuadrado 1:1
          compressQuality: 90,
          maxWidth: 800,
          maxHeight: 800,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recortar Foto',
              toolbarColor: Colors.blue.shade700,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Mantener proporción cuadrada
              activeControlsWidgetColor: Colors.blue.shade700,
              backgroundColor: Colors.black,
              dimmedLayerColor: Colors.black.withOpacity(0.8),
            ),
            IOSUiSettings(
              title: 'Recortar Foto',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );

        if (croppedFile != null) {
          print('[PROFILE_PHOTO] Imagen recortada: ${croppedFile.path}');
          final imageData = await File(croppedFile.path).readAsBytes();
          setState(() {
            _imageData = imageData;
          });
          print('[PROFILE_PHOTO] Imagen cargada exitosamente, tamaño: ${imageData.length} bytes');
        } else {
          print('[PROFILE_PHOTO] Usuario canceló el recorte');
        }
      } else {
        print('[PROFILE_PHOTO] No se seleccionó ninguna imagen');
      }
    } catch (error) {
      print('[PROFILE_PHOTO] ERROR al seleccionar/recortar imagen: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la imagen: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Foto de Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage:
                  _imageData.isNotEmpty ? MemoryImage(_imageData) : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _getImage();
              },
              child: const Text('Seleccionar desde Galería'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _updateProfilePhoto();
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
