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

  Future<void> _showMatchPopup(
      BuildContext context, Map<String, dynamic> profile) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¡Tienes un nuevo Roomie!'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                            Image.memory(
                              base64Decode(profile['profilePhoto'] ?? ''),
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                                                Text(
                                    profile['username'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
              SizedBox(height: 10),
              Text('¿Qué esperas para hablarle?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Volver'),
            ),
            TextButton(
              onPressed: () {
/*                 Navigator.pushNamed(
                  context,
                  chatPageRoute,
                  arguments: {'username': profile['username']},
                ); */
              },
              child: Text('Enviar Mensaje'),
            ),
          ],
        );
      },
    );
  }

  Future<void> matchProfile(String username, bool addToIsMatch) async {
    final String? accessToken = await AuthService().loadUserData('accessToken');
    final String? currentUserUsername =
        await AuthService().loadUserData('username');
    if (accessToken != null && currentUserUsername != null) {
      final authService = AuthService();
      await authService.matchProfile(
          currentUserUsername, addToIsMatch, accessToken, username);
      setState(() {
        homeProfiles.removeWhere((profile) => profile['username'] == username);
      });
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
                      Navigator.pushNamed(
                        context,
                        profilePageRoute,
                        arguments: {'username': profile['username']},
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
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
                            Image.memory(
                              base64Decode(profile['profilePhoto'] ?? ''),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
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
                            Positioned(
                              bottom: 70.0,
                              left: 128.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    profile['username'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final String? accessToken =
                                              await AuthService()
                                                  .loadUserData('accessToken');
                                          final String? currentUserUsername =
                                              await AuthService()
                                                  .loadUserData('username');
                                          if (accessToken != null &&
                                              currentUserUsername != null) {
                                            matchProfile(
                                                profile['username'], true);
                                            AuthService()
                                                .checkMatch(
                                              accessToken,
                                              profile['username'],
                                              currentUserUsername,
                                            )
                                                .then((isMatch) {
                                              if (isMatch) {
                                                _showMatchPopup(
                                                    context, profile);
                                              }
                                            });
                                          } else {
                                            // Manejar el caso cuando accessToken o currentUserUsername es nulo
                                          }
                                        },
                                        icon: const Icon(Icons.check,
                                            color: Colors.green),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          matchProfile(
                                              profile['username'], false);
                                        },
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
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
                    // Lógica para el botón del perfil
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
