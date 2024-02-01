import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
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
      await AuthService().updateProfilePhoto(widget.username, widget.email, _imageData);
      Navigator.pushNamed(context, emailRoute, arguments: {'email': widget.email});

  } catch (error) {
    print('Error al actualizar la foto de perfil: $error');
  }
}

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _imageData = imageData;
      });
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
