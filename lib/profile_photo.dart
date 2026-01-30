import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Uint8List> _imageDataList = []; // Lista de imágenes (1-9)
  final int minPhotos = 1;
  final int maxPhotos = 9;

  @override
  void initState() {
    super.initState();
    _imageDataList = [];
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
      
      // Living habits tags (v3.0 - array de tag IDs)
      final livingHabitsTagsJson = prefs.getString('temp_register_living_habits_tags');
      final List<String> livingHabitsTags = livingHabitsTagsJson != null 
          ? List<String>.from(json.decode(livingHabitsTagsJson))
          : [];
      
      // Interests tags (v3.0 - array de tag IDs)
      final interestsTagsJson = prefs.getString('temp_register_interests_tags');
      final List<String> interestsTags = interestsTagsJson != null 
          ? List<String>.from(json.decode(interestsTagsJson))
          : [];
      
      // Combinar living habits e interests en my_tags (v3.0)
      final List<String> myTags = [...livingHabitsTags, ...interestsTags];
      
      print('🏷️ Tags de hábitos: $livingHabitsTags');
      print('🏷️ Tags de intereses: $interestsTags');
      print('🏷️ my_tags combinado: $myTags');
      
      // LEGACY: Leer preferencias viejas para compatibilidad
      final preferencesJson = prefs.getString('temp_register_preferences');
      final preferences = preferencesJson != null ? json.decode(preferencesJson) : {};
      
      // Preferencias de roommate
      final roommateGender = prefs.getString('temp_register_roommate_gender') ?? 'both';
      final roommateMinAge = prefs.getInt('temp_register_roommate_min_age') ?? 18;
      final roommateMaxAge = prefs.getInt('temp_register_roommate_max_age') ?? 65;
      
      // Living habits (legacy)
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
      final firstName = prefs.getString('temp_register_firstName') ?? '';
      final lastName = prefs.getString('temp_register_lastName') ?? '';
      
      // Preparar fotos de perfil (base64)
      List<String> profilePhotosBase64 = [];
      if (_imageDataList.isNotEmpty) {
        profilePhotosBase64 = _imageDataList.map((imageData) => base64Encode(imageData)).toList();
      }
      
      // Construir el objeto de registro completo (Arquitectura v3.0)
      final registrationData = {
        'username': username,
        'password': password,
        'email': email,
        'birthdate': birthdate,
        'gender': gender,
        'my_tags': myTags, // Nuevo: array plano de tag IDs
        'roommatePreferences': {
          'gender': roommateGender,
          'minAge': roommateMinAge,
          'maxAge': roommateMaxAge,
        },
        'dealBreakers': dealBreakers, // Ya debería ser array de IDs
        'housingInfo': housingInfo,
        'personalInfo': {
          'job': job,
          'religion': religion,
          'politicPreferences': politicPreferences,
          'aboutMe': aboutMe,
          'firstName': firstName,
          'lastName': lastName,
        },
        if (profilePhotosBase64.isNotEmpty) 'profilePhotos': profilePhotosBase64,
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

  // Mostrar diálogo para elegir entre cámara o galería
  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage([ImageSource source = ImageSource.gallery]) async {
    // Validar que no se exceda el límite
    if (_imageDataList.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxPhotos fotos permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pickedFile = await ImagePicker().pickImage(source: source);

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
              statusBarColor: Colors.blue.shade700,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Mantener proporción cuadrada
              activeControlsWidgetColor: Colors.blue.shade700,
              backgroundColor: Colors.black,
              dimmedLayerColor: Colors.black.withOpacity(0.8),
              hideBottomControls: false,
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
            _imageDataList.add(imageData);
          });
          print('[PROFILE_PHOTO] Imagen ${_imageDataList.length}/$maxPhotos agregada exitosamente');
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

  void _removeImage(int index) {
    setState(() {
      _imageDataList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMinPhotos = _imageDataList.length >= minPhotos;
    final bool canAddMore = _imageDataList.length < maxPhotos;
    
    // Obtener dimensiones de pantalla para diseño responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05; // 5% de padding lateral
    final spacing = screenWidth * 0.025; // 2.5% de espaciado

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos de Perfil'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sube entre $minPhotos y $maxPhotos fotos de perfil',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La primera foto será tu foto principal',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Contador de fotos
            Center(
              child: Text(
                'Fotos agregadas: ${_imageDataList.length}/$maxPhotos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasMinPhotos ? Colors.green : Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid de fotos
            if (_imageDataList.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calcular número de columnas según ancho disponible
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: _imageDataList.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: index == 0 ? Colors.blue.shade700 : Colors.grey.shade300,
                                width: index == 0 ? 3 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageDataList[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

            if (_imageDataList.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no has agregado fotos',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            
            // Botón agregar foto
            ElevatedButton.icon(
              onPressed: canAddMore ? _showImageSourceDialog : null,
              icon: const Icon(Icons.add_a_photo),
              label: Text(canAddMore ? 'Agregar Foto' : 'Máximo $maxPhotos fotos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botón registrar
            ElevatedButton.icon(
              onPressed: hasMinPhotos ? _updateProfilePhoto : null,
              icon: const Icon(Icons.check_circle),
              label: Text(hasMinPhotos ? 'Completar Registro' : 'Agrega al menos $minPhotos foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
