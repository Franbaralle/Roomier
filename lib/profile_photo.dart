import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
      final response = await AuthService().updateProfilePhoto(widget.username, widget.email, _imageData);
      
      // Si el email no es el del administrador, ir directo al login
      // (el backend ya marcó como verificado automáticamente)
      if (widget.email != 'baralle2014@gmail.com') {
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
        Navigator.pushNamed(context, emailRoute, arguments: {'email': widget.email});
      }
    } catch (error) {
      print('Error al actualizar la foto de perfil: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
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
        final imageData = await File(croppedFile.path).readAsBytes();
        setState(() {
          _imageData = imageData;
        });
      }
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
