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
  List<Map<String, dynamic>> _pendingMatches = [];
  bool _isLoading = true;
  String _currentUsername = '';
  String? _savedProfilePhoto;
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;

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
        final matches = await ChatService.getPendingMatches(username);
        
        setState(() {
          _chats = chats;
          _pendingMatches = matches;
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty && _pendingMatches.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes chats aún.\n¡Haz match con alguien para empezar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView(
                    children: [
                      // Sección de matches pendientes
                      if (_pendingMatches.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[100],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nuevos Matches',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Inicia una conversación con tus nuevos matches',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pendingMatches.length,
                                  itemBuilder: (context, index) {
                                    final match = _pendingMatches[index];
                                    return _buildMatchCard(match);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 2),
                      ],
                      
                      // Sección de conversaciones activas
                      if (_chats.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Conversaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._chats.map((chat) => _buildChatTile(chat)).toList(),
                      ],
                      
                      // Padding adicional para evitar que el contenido quede debajo de la barra de navegación
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, homeRoute);
              },
              icon: const Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {
                // Ya estamos en chats, no hacer nada
              },
              icon: const Icon(Icons.chat_bubble, color: Colors.blue),
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
                      backgroundImage: ImageUtils.getImageProvider(_savedProfilePhoto),
                    )
                  : const Icon(Icons.person),
            ),
          ],
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

  Widget _buildMatchCard(Map<String, dynamic> match) {
    return GestureDetector(
      onTap: () async {
        // Crear chat y navegar a la página de chat
        final chatId = await ChatService.createChat(_currentUsername, match['username']);
        
        if (chatId != null) {
          Navigator.pushNamed(
            context,
            chatRoute,
            arguments: {
              'profile': {
                'username': match['username'],
                'profilePhoto': match['profilePhoto'],
              },
              'chatId': chatId,
            },
          ).then((_) {
            // Recargar chats cuando vuelves
            _loadChats();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al iniciar conversación'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: ImageUtils.getImageProvider(match['profilePhoto']),
                  child: ImageUtils.getImageProvider(match['profilePhoto']) == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              match['username'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final otherUser = chat['otherUser'];
    final lastMessage = chat['lastMessage'];
    final unreadCount = chat['unreadCount'] ?? 0;

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
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: ImageUtils.getImageProvider(otherUser['profilePhoto']),
              child: ImageUtils.getImageProvider(otherUser['profilePhoto']) == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
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
        title: Text(
          otherUser['username'] ?? 'Usuario',
          style: TextStyle(
            fontWeight: unreadCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: lastMessage != null
            ? Text(
                '${(lastMessage['sender'] is String && lastMessage['sender'] == _currentUsername) || (lastMessage['sender'] is Map && lastMessage['sender']['username'] == _currentUsername) ? 'Tú: ' : ''}${lastMessage['content']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0
                      ? Colors.black87
                      : Colors.grey,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              )
            : const Text(
                'No hay mensajes aún',
                style: TextStyle(color: Colors.grey),
              ),
        trailing: lastMessage != null
            ? Text(
                _formatTimestamp(lastMessage['timestamp']),
                style: TextStyle(
                  fontSize: 12,
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
                'profilePhoto': otherUser['profilePhoto'],
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

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
