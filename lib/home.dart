import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_service.dart'; // Importamos el servicio de chat
import 'image_utils.dart';
import 'received_likes_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> homeProfiles = [];
  late SharedPreferences _prefs;
  String? savedData;
  int _unreadMessagesCount = 0;
  int _receivedLikesCount = 0;
  bool _isInitialLoad = true;

  Offset _imageOffset = Offset.zero;
  Offset _startPosition = Offset.zero;
  int _draggingIndex = -1;
  double _rotationAngle = 0.0;
  late AnimationController _animationController;
  
  // Sistema de navegación de fotos
  Map<int, int> _currentPhotoIndexMap = {}; // índice de foto actual por perfil
  
  // Sistema de FirstSteps
  int _firstStepsRemaining = 5;
  bool _isPremium = false;
  bool _resetsWeekly = false;

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
    _loadReceivedLikesCount();
    _loadFirstStepsRemaining();
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

  Future<void> _loadReceivedLikesCount() async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username != null) {
        final likes = await AuthService().fetchReceivedLikes(username);
        setState(() {
          _receivedLikesCount = likes.length;
        });
      }
    } catch (error) {
      // Error loading received likes count
      print('Error al cargar contador de likes recibidos: $error');
    }
  }

  Future<void> _loadFirstStepsRemaining() async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username != null) {
        final data = await ChatService.getFirstStepsRemaining(username);
        setState(() {
          _firstStepsRemaining = data['firstStepsRemaining'] ?? 5;
          _isPremium = data['isPremium'] ?? false;
          _resetsWeekly = data['resetsWeekly'] ?? false;
        });
      }
    } catch (error) {
      print('Error al cargar firstSteps: $error');
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
  
  // Extraer foto principal de profilePhotos (nuevo sistema) o profilePhoto (legacy)
  final primaryPhotoUrl = (profile['profilePhotos'] != null && 
                          (profile['profilePhotos'] as List).isNotEmpty)
      ? profile['profilePhotos'][0]['url']
      : profile['profilePhoto'];
  
  final imageProvider = ImageUtils.getImageProvider(primaryPhotoUrl);
  
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

  // Método para mostrar el diálogo de "Da el primer paso"
  Future<void> _showFirstStepDialog(Map<String, dynamic> profile) async {
    final TextEditingController _messageController = TextEditingController();
    final String? currentUsername = await AuthService().loadUserData('username');
    
    if (currentUsername == null) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.purple),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Da el primer paso',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envia un mensaje a ${profile['username']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Podrás enviar solo un mensaje. Si les interesas, te responderán.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              onPressed: () async {
                final message = _messageController.text.trim();
                
                if (message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Escribe un mensaje primero')),
                  );
                  return;
                }

                if (message.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('El mensaje debe tener al menos 10 caracteres')),
                  );
                  return;
                }

                Navigator.of(context).pop(); // Cerrar el diálogo
                
                // Crear el chat con firstStep
                final chatId = await ChatService.createChat(
                  currentUsername,
                  profile['username'],
                  isFirstStep: true,
                  firstMessage: message,
                );
                
                if (chatId != null) {
                  // Remover el perfil de la lista
                  setState(() {
                    homeProfiles.removeWhere((p) => p['username'] == profile['username']);
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡Mensaje enviado! Espera su respuesta'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al enviar el mensaje'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar popup cuando se acaban los firstSteps
  Future<void> _showPremiumDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 30),
              SizedBox(width: 10),
              Text(
                _resetsWeekly ? 'Esperá una semana' : 'Sin primeros pasos',
                style: TextStyle(color: Colors.amber.shade800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _resetsWeekly 
                    ? '¡Ya usaste tus 5 First Steps de esta semana!'
                    : '¡Te quedaste sin primeros pasos!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              if (_resetsWeekly) ...[
                Text(
                  'Como usuario Premium, tus First Steps se renuevan automáticamente cada 7 días.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.purple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Volvé la próxima semana para más',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Suscribite a Premium y conseguí:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('5 primeros pasos RENOVABLES cada semana'),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Ver quién te dio like'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Ver reviews completas'),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '💡 FREE: Solo 5 First Steps TOTALES',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '💎 PREMIUM: 5 por semana (renovables)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(_resetsWeekly ? 'Entendido' : 'Ahora no'),
            ),
            if (!_resetsWeekly)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Ir a página de suscripción premium
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Próximamente: Suscripción Premium'),
                      backgroundColor: Colors.amber.shade700,
                    ),
                  );
                },
                child: Text('Suscribirme', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Variables responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;
    final iconSize = screenWidth * 0.2;
    final titleFontSize = screenWidth * 0.06;
    final bodyFontSize = screenWidth * 0.04;
    
    return Scaffold(
      body: SafeArea(
        child: _isInitialLoad
        ? Center(child: CircularProgressIndicator())
        : homeProfiles.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: iconSize,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      '¡Ya viste todo por ahora!',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Cambia tus parámetros de búsqueda o espera que haya alguien que pueda coincidir con tu perfil',
                      style: TextStyle(
                        fontSize: bodyFontSize,
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
                      : 0.0;
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
                              
                              // Solo rotar si es swipe horizontal
                              if (_imageOffset.dx.abs() > _imageOffset.dy.abs()) {
                                _rotationAngle = (_imageOffset.dx / 1000).clamp(-0.3, 0.3);
                              } else {
                                _rotationAngle = 0;
                              }
                            });
                          }
                        },
                        onPanEnd: (details) {
                          if (_draggingIndex == index && index == 0) {
                            final swipeThreshold = screenWidth * 0.3;
                            final verticalThreshold = screenHeight * 0.15;
                            
                            // Detectar swipe hacia arriba ("Da el primer paso")
                            if (_imageOffset.dy < -verticalThreshold && 
                                _imageOffset.dx.abs() < swipeThreshold) {
                              // Validar si tiene firstSteps disponibles
                              if (_firstStepsRemaining > 0) {
                                _showFirstStepDialog(profile).then((_) {
                                  // Recargar contador después del modal
                                  _loadFirstStepsRemaining();
                                });
                              } else {
                                _showPremiumDialog();
                              }
                              setState(() {
                                _draggingIndex = -1;
                                _imageOffset = Offset.zero;
                                _rotationAngle = 0.0;
                              });
                            }
                            // Swipe horizontal (like/nope)
                            else if (_imageOffset.dx.abs() > swipeThreshold) {
                              final isLike = _imageOffset.dx < 0;
                              _swipeCard(index, isLike);
                            } 
                            // Resetear si no cumple ningún threshold
                            else {
                              setState(() {
                                _draggingIndex = -1;
                                _imageOffset = Offset.zero;
                                _rotationAngle = 0.0;
                              });
                            }
                          }
                        },
                        onTap: () {
                          // Remover el tap general - lo manejaremos con GestureDetectors específicos
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
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
                                  // Imagen con sistema de navegación
                                  () {
                                    // Obtener todas las fotos disponibles
                                    final List<String> photoUrls = [];
                                    if (profile['profilePhotos'] != null && 
                                        (profile['profilePhotos'] as List).isNotEmpty) {
                                      for (var photo in profile['profilePhotos']) {
                                        if (photo['url'] != null) {
                                          photoUrls.add(photo['url']);
                                        }
                                      }
                                    } else if (profile['profilePhoto'] != null) {
                                      photoUrls.add(profile['profilePhoto']);
                                    }

                                    // Obtener índice actual de foto para este perfil
                                    final currentPhotoIndex = _currentPhotoIndexMap[index] ?? 0;
                                    final photoUrl = photoUrls.isNotEmpty 
                                        ? photoUrls[currentPhotoIndex.clamp(0, photoUrls.length - 1)]
                                        : null;

                                    final imageProvider = photoUrl != null 
                                        ? ImageUtils.getImageProvider(photoUrl) 
                                        : null;
                                    
                                    return Stack(
                                      children: [
                                        // La imagen
                                        Positioned.fill(
                                          child: imageProvider != null
                                            ? Image(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.person, size: 100),
                                              ),
                                        ),
                                        
                                        // Áreas de tap para navegar fotos
                                        Row(
                                          children: [
                                            // Tap izquierdo - foto anterior
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (photoUrls.length > 1) {
                                                    setState(() {
                                                      final current = _currentPhotoIndexMap[index] ?? 0;
                                                      if (current > 0) {
                                                        _currentPhotoIndexMap[index] = current - 1;
                                                      }
                                                    });
                                                  }
                                                },
                                                child: Container(color: Colors.transparent),
                                              ),
                                            ),
                                            // Tap derecho - foto siguiente
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (photoUrls.length > 1) {
                                                    setState(() {
                                                      final current = _currentPhotoIndexMap[index] ?? 0;
                                                      if (current < photoUrls.length - 1) {
                                                        _currentPhotoIndexMap[index] = current + 1;
                                                      }
                                                    });
                                                  }
                                                },
                                                child: Container(color: Colors.transparent),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Indicadores de fotos (barrita dividida)
                                        if (photoUrls.length > 1)
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            right: 12,
                                            child: Row(
                                              children: List.generate(
                                                photoUrls.length,
                                                (photoIndex) => Expanded(
                                                  child: Container(
                                                    height: 3,
                                                    margin: EdgeInsets.symmetric(horizontal: 2),
                                                    decoration: BoxDecoration(
                                                      color: photoIndex == currentPhotoIndex
                                                          ? Colors.white
                                                          : Colors.white.withOpacity(0.4),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }(),
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
                                // Indicador de PRIMER PASO (swipe arriba)
                                if (index == _draggingIndex && _imageOffset.dy < -50)
                                  Positioned(
                                    top: 50,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.purple,
                                            width: 4,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.purple.withOpacity(0.1),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.arrow_upward,
                                              color: Colors.purple,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'DA EL PRIMER PASO',
                                              style: TextStyle(
                                                color: Colors.purple,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
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
                                                    profile['housingInfo']['hasPlace'] == true
                                                        ? '${profile['housingInfo']['originProvince'] ?? profile['housingInfo']['city'] ?? 'No especificado'}'
                                                        : '${profile['housingInfo']['destinationProvince'] ?? profile['housingInfo']['city'] ?? 'No especificado'}',
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
                                          const SizedBox(width: 20),
                                          // Botón de VER PERFIL
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue.withOpacity(0.3),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              iconSize: 30,
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  profilePageRoute,
                                                  arguments: {'username': profile['username']},
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.info_outline,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
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
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    // Mostrar info de firstSteps
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _resetsWeekly
                              ? 'Deslizá hacia arriba para dar el primer paso\n$_firstStepsRemaining de 5 esta semana'
                              : 'Deslizá hacia arriba para dar el primer paso\n$_firstStepsRemaining de 5 totales (FREE)',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.purple,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_upward,
                    color: _firstStepsRemaining > 0 ? Colors.purple : Colors.grey,
                  ),
                ),
                // Mostrar contador de firstSteps
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _firstStepsRemaining > 0 ? Colors.purple : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_firstStepsRemaining',
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
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReceivedLikesPage(),
                      ),
                    ).then((_) {
                      // Recargar contador cuando vuelves
                      _loadReceivedLikesCount();
                    });
                  },
                  icon: const Icon(Icons.favorite),
                ),
                if (_receivedLikesCount > 0)
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
                        _receivedLikesCount > 99
                            ? '99+'
                            : '$_receivedLikesCount',
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
