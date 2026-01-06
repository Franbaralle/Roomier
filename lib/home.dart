import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_service.dart'; // Importamos el servicio de chat
import 'image_utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> homeProfiles = [];
  late SharedPreferences _prefs;
  String? savedData;
  int _unreadMessagesCount = 0;
  bool _isInitialLoad = true;

  Offset _imageOffset = Offset.zero;
  Offset _startPosition = Offset.zero;
  int _draggingIndex = -1;
  double _rotationAngle = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    initializeSharedPreferences();
    loadData();
    _fetchHomeProfiles();
    _loadUnreadMessagesCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getCompatibilityColor(int compatibility) {
    if (compatibility >= 80) {
      return Colors.green.shade600;
    } else if (compatibility >= 60) {
      return Colors.lightGreen.shade700;
    } else if (compatibility >= 40) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
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

      setState(() {
        homeProfiles = profiles.cast<Map<String, dynamic>>();
        _isInitialLoad = false;
      });
    } catch (error) {
      // Error fetching profiles
      print('Error al obtener perfiles: $error');
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username != null) {
        final chats = await ChatService.getUserChats(username);
        int totalUnread = 0;
        for (var chat in chats) {
          totalUnread += (chat['unreadCount'] ?? 0) as int;
        }
        setState(() {
          _unreadMessagesCount = totalUnread;
        });
      }
    } catch (error) {
      // Error loading unread messages count
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
    BuildContext context, Map<String, dynamic> profile, String chatId) async {
  // Recargar el contador de mensajes no leídos
  await _loadUnreadMessagesCount();
  
  final imageProvider = ImageUtils.getImageProvider(profile['profilePhoto']);
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('¡Tienes un nuevo Roomie!'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            imageProvider != null
              ? Image(
                  image: imageProvider,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[300],
                  child: Icon(Icons.person, size: 100),
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
              Navigator.of(context).pop(); // Cerrar el diálogo actual
              Navigator.of(context).pushNamed(
                chatRoute,
                arguments: {
                  'profile': profile,
                  'chatId': chatId,
                },
              ).then((_) {
                // Recargar contador cuando vuelves del chat
                _loadUnreadMessagesCount();
              });
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

  Future<void> _swipeCard(int index, bool isLike) async {
    if (index < 0 || index >= homeProfiles.length) return;
    
    final profile = homeProfiles[index];
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Animar el swipe (izquierda = like, derecha = nope)
    final targetOffset = isLike ? -screenWidth : screenWidth;
    
    setState(() {
      _draggingIndex = index;
    });

    // Animación suave
    for (double i = 0; i <= 1.0; i += 0.05) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (mounted) {
        setState(() {
          _imageOffset = Offset(targetOffset * i, 0);
          _rotationAngle = (isLike ? -0.2 : 0.2) * i;
        });
      }
    }

    // Realizar el match
    if (isLike) {
      final String? accessToken = await AuthService().loadUserData('accessToken');
      final String? currentUserUsername = await AuthService().loadUserData('username');
      
      if (accessToken != null && currentUserUsername != null) {
        await matchProfile(profile['username'], true);
        
        // Verificar si hay match
        final isMatch = await AuthService().checkMatch(
          accessToken,
          profile['username'],
          currentUserUsername,
        );
        
        if (isMatch && mounted) {
          // Crear el chat automáticamente cuando hay match
          final chatId = await ChatService.createChat(
            currentUserUsername,
            profile['username'],
          );
          
          if (chatId != null) {
            // Mostrar popup con el chatId ya creado
            _showMatchPopup(context, profile, chatId);
          }
        }
      }
    } else {
      await matchProfile(profile['username'], false);
    }

    // Resetear estado
    if (mounted) {
      setState(() {
        _draggingIndex = -1;
        _imageOffset = Offset.zero;
        _rotationAngle = 0.0;
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
      body: _isInitialLoad
        ? Center(child: CircularProgressIndicator())
        : homeProfiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 24),
                    Text(
                      '¡Ya viste todo por ahora!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cambia tus parámetros de búsqueda o espera que haya alguien que pueda coincidir con tu perfil',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Center(
            child: Stack(
              alignment: Alignment.center,
              children: homeProfiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final profile = entry.value;
                  
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final cardWidth = screenWidth * 0.9;
                  final cardHeight = screenHeight * 0.65;
                  
                  // Calcular offset para apilar las tarjetas
                  final double topOffset = index == _draggingIndex 
                      ? _imageOffset.dy 
                      : index * 10.0;
                  final double leftOffset = index == _draggingIndex 
                      ? _imageOffset.dx 
                      : 0;
                  
                  return Transform.translate(
                    offset: Offset(leftOffset, topOffset),
                    child: Transform.rotate(
                      angle: index == _draggingIndex ? _rotationAngle : 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          if (index == 0) {
                            setState(() {
                              _draggingIndex = index;
                              _startPosition = details.globalPosition;
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (_draggingIndex == index && index == 0) {
                            setState(() {
                              _imageOffset += details.globalPosition - _startPosition;
                              _startPosition = details.globalPosition;
                              
                              _rotationAngle = (_imageOffset.dx / 1000).clamp(-0.3, 0.3);
                            });
                          }
                        },
                        onPanEnd: (details) {
                          if (_draggingIndex == index && index == 0) {
                            final swipeThreshold = screenWidth * 0.3;
                            
                            if (_imageOffset.dx.abs() > swipeThreshold) {
                              final isLike = _imageOffset.dx < 0;
                              _swipeCard(index, isLike);
                            } else {
                              setState(() {
                                _draggingIndex = -1;
                                _imageOffset = Offset.zero;
                                _rotationAngle = 0.0;
                              });
                            }
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
                            horizontal: 20,
                            vertical: 20,
                          ),
                          width: cardWidth,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  ImageUtils.getImageProvider(profile['profilePhoto']) != null
                                    ? Image(
                                        image: ImageUtils.getImageProvider(profile['profilePhoto'])!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.person, size: 100),
                                      ),
                                  // Indicador de LIKE
                                  if (index == _draggingIndex && _imageOffset.dx > 50)
                                    Positioned(
                                    top: 50,
                                    left: 50,
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 4,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'NOPE',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Indicador de NOPE
                                if (index == _draggingIndex && _imageOffset.dx < -50)
                                  Positioned(
                                top: 50,
                                right: 50,
                                child: Transform.rotate(
                                  angle: 0.3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 4,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'LIKE',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
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
                                  bottom: 20.0,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Porcentaje de compatibilidad
                                      if (profile['compatibility'] != null)
                                        Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCompatibilityColor(profile['compatibility']),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${profile['compatibility']}% Compatible',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              profile['username'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black45,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (profile['housingInfo']?['city'] != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white70,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${profile['housingInfo']['city']} - ${profile['housingInfo']['generalZone'] ?? ''}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Botón de LIKE
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.3),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              iconSize: 35,
                                              onPressed: () {
                                                if (index == 0) {
                                                  _swipeCard(index, true);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 30),
                                          // Botón de NOPE
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withOpacity(0.3),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              iconSize: 35,
                                              onPressed: () {
                                                if (index == 0) {
                                                  _swipeCard(index, false);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                            ),
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
                      ),
                    );
                  }).toList().reversed.toList(),
            ),
          ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                // Lógica para el botón del rayo
              },
              icon: const Icon(Icons.flash_on),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, chatsListRoute).then((_) {
                      // Recargar contador cuando vuelves de la lista de chats
                      _loadUnreadMessagesCount();
                    });
                  },
                  icon: const Icon(Icons.chat_bubble),
                ),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadMessagesCount > 99
                            ? '99+'
                            : '$_unreadMessagesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: () {
                handleProfileButton(context);
              },
              icon: savedData != null
                  ? CircleAvatar(
                      backgroundImage: ImageUtils.getImageProvider(savedData),
                    )
                  : const Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }
}
