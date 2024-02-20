import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_service.dart'; // Importamos el servicio de chat

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha iniciado sesión.'),
          duration: Duration(seconds: 3),
        ),
      );
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
            onPressed: () async {
              final String? currentUserUsername =
                  await AuthService().loadUserData('username');
              if (currentUserUsername != null) {
                final chatId = await ChatService.createChat(
                  currentUserUsername,
                  profile['username'],
                );
                print('A VER QUE CHOTA TRAE ESTO $currentUserUsername');
                print('Y ESTO QUE MIERDA TRAE ${profile['username']}');
                if (chatId != null) {
                  Navigator.of(context).pop(); // Cerrar el diálogo actual
                  Navigator.of(context).pushNamed( // Usar un nuevo contexto
                    chatRoute,
                    arguments: {
                      'profile': profile,
                      'chatId': chatId,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo crear el chat. Inténtalo de nuevo más tarde.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
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

  // Método para enviar el mensaje al chat
  void _sendMessage(String chatId, String message) async {
    final String? accessToken = await AuthService().loadUserData('accessToken');
    final String? currentUsername =
        await AuthService().loadUserData('username');

    if (accessToken != null && currentUsername != null) {
      try {
        await ChatService.sendMessage(chatId, currentUsername, message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensaje enviado correctamente'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (error) {
        print('Error sending message: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar el mensaje'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Error: no se pudo obtener el token de acceso o el nombre de usuario'),
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
