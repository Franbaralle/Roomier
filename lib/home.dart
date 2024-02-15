import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> homeProfiles = [];
  late SharedPreferences _prefs;
  String? savedData;

  Offset _imageOffset = Offset.zero;
  Offset _startPosition = Offset.zero;
  int _draggingIndex = -1;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    loadData();
    _fetchHomeProfiles();
  }

  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadData() async {
    await initializeSharedPreferences();
    savedData = _prefs.getString('profilePhoto');
    setState(() {});
  }

  Future<void> _fetchHomeProfiles() async {
    try {
      final authService = AuthService();
      final profiles = await authService.fetchHomeProfiles();

      final String? currentUsername =
          await AuthService().loadUserData('username');

      if (currentUsername != null) {
        final filteredProfiles =
            profiles.where((profile) => profile['username'] != currentUsername);
        setState(() {
          homeProfiles = filteredProfiles.toList().cast<Map<String, dynamic>>();
        });
      }
    } catch (error) {
      print('Error fetching random profiles: $error');
    }
  }

  Future<void> handleProfileButton(BuildContext context) async {
    final String? accessToken = await AuthService().loadUserData('accessToken');
    final String? username = await AuthService().loadUserData('username');

    if (accessToken != null && username != null) {
      final Map<String, dynamic>? profileData =
          await AuthService().getUserInfoFromToken(accessToken, username);

      if (profileData != null) {
        Navigator.pushNamed(
          context,
          profilePageRoute,
          arguments: {'username': profileData['username']},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener los datos del perfil del usuario.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Manejo del caso en el que el token de acceso o el nombre de usuario sean nulos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha iniciado sesión.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles al Azar'),
      ),
      body: Column(
        children: [
Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: homeProfiles.asMap().entries.map((entry) {
                final index = entry.key;
                final profile = entry.value;
                return Positioned(
                  top: index == _draggingIndex ? _imageOffset.dy : 0,
                  left: index == _draggingIndex ? _imageOffset.dx : 0,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _draggingIndex = index;
                        _startPosition = details.globalPosition;
                      });
                    },
                    onPanUpdate: (details) {
                      if (_draggingIndex == index) {
                        setState(() {
                          _imageOffset +=
                              details.globalPosition - _startPosition;
                          _startPosition = details.globalPosition;
                        });
                      }
                    },
                    onPanEnd: (details) {
                      if (_draggingIndex == index) {
                        setState(() {
                          _draggingIndex = -1;
                          _imageOffset = Offset.zero;
                        });
                      }
                    },
                    onTap: () {
                      // Navegar al perfil del usuario
                      Navigator.pushNamed(
                        context,
                        profilePageRoute,
                        arguments: {'username': profile['username']},
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 550,
                        vertical: 20,
                      ),
                      width: 400,
                      height: 500,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            // Imagen de perfil
                            Image.memory(
                              base64Decode(profile['profilePhoto'] ?? ''),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            // Sombreado debajo de la imagen
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Nombre de usuario
                            Positioned(
                              bottom: 70.0,
                              left: 128.0,
                              child: Text(
                                profile['username'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    // Lógica para el botón del rayo
                  },
                  icon: const Icon(Icons.flash_on),
                ),
                IconButton(
                  onPressed: () {
                    handleProfileButton(context);
                  },
                  icon: savedData != null
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(
                            base64Decode(savedData!),
                          ),
                        )
                      : const Icon(Icons.person),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
