import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userInfo;
  Image? profilePhoto;
  late SharedPreferences _prefs;
  String? savedData;
  late String username;
  late String currentUser; // Usuario actualmente autenticado

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      username = args['username'];
    }
    initializeSharedPreferences();
    loadData();
    _loadUserInfo();
    getCurrentUser(); // Obtener el usuario actualmente autenticado
  }

  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadData() async {
    await initializeSharedPreferences();
    savedData = _prefs.getString('key');
    setState(() {}); // Actualiza el estado para reflejar los cambios
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = await authService.getUserInfo(widget.username);

      if (user != null) {
        setState(() {
          userInfo = {
            'username': user['username'],
            'preferences': user['preferences'],
            'personalInfo': user['personalInfo'],
            'profilePhoto': user['profilePhoto'],
            'aboutMe': user['aboutMe'],
          };
        });
      }

      if (userInfo?['profilePhoto'] != null) {
        // Convierte la cadena Base64 a datos binarios y actualiza el estado
        final String base64String = userInfo?['profilePhoto'];
        final Uint8List imageData = base64Decode(base64String);
        setState(() {
          profilePhoto = Image.memory(imageData);
        });
      }
    } catch (error) {
      print('Error loading user information: $error');
      // Puedes manejar el error de alguna manera (por ejemplo, mostrar un mensaje al usuario)
    }
  }

  Future<void> getCurrentUser() async {
    final authService = AuthService();
    currentUser = await authService.loadUserData('username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar Sesión'),
                ),
              ];
            },
            icon:
                const Icon(Icons.more_vert), // Icono de tres puntos verticales
          ),
        ],
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._buildProfileContentList(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Lógica para el botón del rayo
              },
              child: Container(
                height: 60.0,
                child: const Center(
                  child: Icon(Icons.flash_on, color: Colors.grey),
                ),
              ),
            ),
          ),
          Container(
            height: 60.0,
            width: 1.0,
            color: Colors.grey,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, homeRoute);
              },
              child: Container(
                height: 60.0,
                child: const Center(
                  child: Icon(Icons.home, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileContentList() {
    return [
      _buildProfileImage(),
      const SizedBox(height: 20),
      _buildAdditionalImages(),
      const SizedBox(height: 20),
      _buildHomeImages(),
      const SizedBox(height: 20),
      _buildAdditionalInfoSection(),
    ];
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Algo más de mí',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAboutMeSubSection(
            'Acerca de mí', userInfo?['personalInfo']['aboutMe']),
        const SizedBox(height: 16),
        _buildAboutMeSubSection('Trabajo', userInfo?['personalInfo']['job']),
        _buildAboutMeSubSection(
            'Lo que me gusta', _formatList(userInfo?['preferences'])),
        _buildAboutMeSubSection(
            'Religión', userInfo?['personalInfo']['religion']),
        _buildAboutMeSubSection(
            'Política', userInfo?['personalInfo']['politicPreference']),
      ],
    );
  }

  Widget _buildAboutMeSubSection(String title, String? content) {
    final isCurrentUserProfile = currentUser == widget.username; // Comparar con el usuario autenticado
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (isCurrentUserProfile) // Mostrar el botón de edición solo si es el perfil del usuario autenticado
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _editAboutMe(title, content);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(content ??
            'No especificado'), // Puedes personalizar el mensaje si el contenido está vacío
        const SizedBox(height: 16),
      ],
    );
  }

  void _editAboutMe(String title, String? content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedContent =
            content ?? ''; // Inicializa con el contenido actual
        return AlertDialog(
          title: Text('Editar $title'),
          content: TextFormField(
            initialValue: content ?? '',
            onChanged: (value) {
              updatedContent = value; // Actualiza el contenido al escribir
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final authService = AuthService();
                final username = userInfo?['username'];
                final accessToken = _prefs.getString('accessToken');
                await authService.updateProfile(
                  username,
                  job: title == 'Trabajo' ? updatedContent : null,
                  religion: title == 'Religión' ? updatedContent : null,
                  politicPreference:
                      title == 'Política' ? updatedContent : null,
                  aboutMe: title == 'Acerca de mí' ? updatedContent : null,
                  accessToken:
                      accessToken, // Asegúrate de pasar el token de acceso
                );
                Navigator.of(context).pop(); // Cierra el diálogo
                // Actualiza la información del usuario después de la edición
                await _loadUserInfo();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  String _formatList(List<dynamic>? items) {
    if (items != null && items.isNotEmpty) {
      return items.join(', ');
    }
    return 'No especificado';
  }

  Widget _buildProfileImage() {
    final dynamic profilePhoto = userInfo?['profilePhoto'];

    if (profilePhoto != null && profilePhoto is String) {
      try {
        final Uint8List bytes = base64Decode(profilePhoto);

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ClipRRect(
                child: Image.memory(bytes,
                    width: 400, height: 500, fit: BoxFit.cover),
              ),
            ),
            Container(
              width: 400,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15.0,
                    //spreadRadius: 10.0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8.0,
              bottom: 8.0,
              child: Text(
                userInfo?['username'] ?? '',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        );
      } catch (e) {
        print('Error decoding profile image: $e');
      }
    } else {
      print('Profile photo is null or not a String (base64): $profilePhoto');
    }

    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
      child: const Icon(Icons.account_circle, size: 100, color: Colors.white),
    );
  }

  Widget _buildAdditionalImages() {
    // Implementa según tus necesidades
    return Container();
  }

  Widget _buildHomeImages() {
    // Implementa según tus necesidades
    return Container();
  }

  void _logout() async {
    try {
      setState(() {
        userInfo = null;
        profilePhoto = null;
      });

      // Muestra un mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cierre de sesión exitoso.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navega a la página de inicio de sesión
      Navigator.pushReplacementNamed(context, loginRoute);
    } catch (error) {
      print('Error durante el cierre de sesión: $error');
      // Puedes manejar el error de alguna manera (mostrar un mensaje al usuario, por ejemplo)
    }
  }
}
