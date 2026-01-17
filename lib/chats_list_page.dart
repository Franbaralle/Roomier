import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'routes.dart';
import 'image_utils.dart';
import 'socket_service.dart';
import 'dart:async';

class ChatsListPage extends StatefulWidget {
  @override
  _ChatsListPageState createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String _currentUsername = '';
  String? _savedProfilePhoto;
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _stopTypingSubscription;
  
  // Mapa para trackear quién está escribiendo en cada chat
  Map<String, bool> _typingStatus = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadProfilePhoto();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Escuchar mensajes nuevos para actualizar la lista
    _messageSubscription = _socketService.onMessageReceived.listen((data) {
      // Recargar la lista de chats cuando llega un mensaje nuevo
      _loadChats();
    });
    
    // Escuchar indicador de escritura
    _typingSubscription = _socketService.onUserTyping.listen((data) {
      setState(() {
        _typingStatus[data['chatId']] = true;
      });
    });
    
    // Escuchar cuando dejan de escribir
    _stopTypingSubscription = _socketService.onUserStopTyping.listen((data) {
      setState(() {
        _typingStatus[data['chatId']] = false;
      });
    });
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _stopTypingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfilePhoto() async {
    final photo = await AuthService().loadUserData('profilePhoto');
    setState(() {
      _savedProfilePhoto = photo;
    });
  }

  Future<void> _loadChats() async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username != null) {
        setState(() {
          _currentUsername = username;
        });

        final chats = await ChatService.getUserChats(username);
        
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading chats: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final horizontalPadding = isTablet ? size.width * 0.15 : 16.0;
    final titleFontSize = isTablet ? 22.0 : 18.0;
    final emptyMessageFontSize = isTablet ? 18.0 : 16.0;
    
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Text(
                        'No tienes chats aún.\n¡Haz match con alguien para empezar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: emptyMessageFontSize, color: Colors.grey),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChats,
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.5),
                      children: [
                        // Conversaciones
                        if (_chats.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.all(horizontalPadding * 0.5),
                            child: Text(
                              'Conversaciones',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._chats.map((chat) => _buildChatTile(chat, size, isTablet)).toList(),
                        ],
                        
                        // Padding adicional para evitar que el contenido quede debajo de la barra de navegación
                        SizedBox(height: isTablet ? 30 : 20),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, homeRoute);
                },
                icon: Icon(Icons.home, size: isTablet ? 32 : 24),
              ),
              IconButton(
                onPressed: () {
                  // Ya estamos en chats, no hacer nada
                },
                icon: Icon(Icons.chat_bubble, color: Colors.blue, size: isTablet ? 32 : 24),
              ),
              IconButton(
                onPressed: () async {
                  if (_currentUsername.isNotEmpty) {
                    Navigator.pushNamed(
                      context,
                      profilePageRoute,
                      arguments: {'username': _currentUsername},
                    );
                  }
                },
                icon: _savedProfilePhoto != null
                    ? CircleAvatar(
                        radius: isTablet ? 18 : 14,
                        backgroundImage: ImageUtils.getImageProvider(_savedProfilePhoto),
                      )
                    : Icon(Icons.person, size: isTablet ? 32 : 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildChatTile(Map<String, dynamic> chat, Size size, bool isTablet) {
    final otherUser = chat['otherUser'];
    final lastMessage = chat['lastMessage'];
    final unreadCount = chat['unreadCount'] ?? 0;
    final avatarRadius = isTablet ? 34.0 : 28.0;
    final titleFontSize = isTablet ? 18.0 : 16.0;
    final subtitleFontSize = isTablet ? 15.0 : 14.0;
    final timestampFontSize = isTablet ? 14.0 : 12.0;

    // Extraer foto principal de profilePhotos si existe
    String? primaryPhotoUrl;
    if (otherUser['profilePhotos'] != null && otherUser['profilePhotos'].isNotEmpty) {
      primaryPhotoUrl = otherUser['profilePhotos'][0]['url'];
    } else if (otherUser['profilePhoto'] != null) {
      // Fallback para usuarios legacy
      primaryPhotoUrl = otherUser['profilePhoto'];
    }

    return Dismissible(
      key: Key(chat['chatId']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.heart_broken,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Deshacer Match'),
              content: Text(
                '¿Estás seguro que quieres deshacer el match con ${otherUser['username']}?\n\nEsto eliminará el chat y no podrán enviarse mensajes.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Deshacer Match'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final username = otherUser['username'];
        
        // Remover de la lista inmediatamente para evitar el error de Dismissible
        setState(() {
          _chats.removeWhere((c) => c['chatId'] == chat['chatId']);
        });
        
        final success = await AuthService().unmatchProfile(
          username,
          _currentUsername,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Match con $username deshecho'),
              duration: const Duration(seconds: 2),
            ),
          );
          // Recargar para sincronizar con el servidor
          _loadChats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al deshacer el match'),
              duration: Duration(seconds: 2),
            ),
          );
          // Recargar si falla para restaurar el estado correcto
          _loadChats();
        }
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 12 : 8,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundImage: ImageUtils.getImageProvider(primaryPhotoUrl),
              child: ImageUtils.getImageProvider(primaryPhotoUrl) == null
                  ? Icon(Icons.person, size: isTablet ? 34 : 28)
                  : null,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: isTablet ? 24 : 20,
                    minHeight: isTablet ? 24 : 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherUser['username'] ?? 'Usuario',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: unreadCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: _typingStatus[chat['chatId']] == true
            ? Text(
                'escribiendo...',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              )
            : lastMessage != null
                ? Text(
                    '${(lastMessage['sender'] is String && lastMessage['sender'] == _currentUsername) || (lastMessage['sender'] is Map && lastMessage['sender']['username'] == _currentUsername) ? 'Tú: ' : ''}${lastMessage['content']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: unreadCount > 0
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                      : FontWeight.normal,
                ),
              )
            : Text(
                'No hay mensajes aún',
                style: TextStyle(fontSize: subtitleFontSize, color: Colors.grey),
              ),
        trailing: lastMessage != null
            ? Text(
                _formatTimestamp(lastMessage['timestamp']),
                style: TextStyle(
                  fontSize: timestampFontSize,
                  color: unreadCount > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              )
            : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            chatRoute,
            arguments: {
              'profile': {
                'username': otherUser['username'],
                'profilePhoto': primaryPhotoUrl,
              },
              'chatId': chat['chatId'],
            },
          ).then((_) {
            // Recargar chats cuando vuelves de un chat
            _loadChats();
          });
        },
      ),
    );
  }
}
