import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'routes.dart';

class ChatsListPage extends StatefulWidget {
  @override
  _ChatsListPageState createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String _currentUsername = '';
  String? _savedProfilePhoto;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadProfilePhoto();
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes chats aún.\n¡Haz match con alguien para empezar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
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
                          final success = await AuthService().unmatchProfile(
                            username,
                            _currentUsername,
                          );

                          if (success) {
                            setState(() {
                              _chats.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Match con $username deshecho'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al deshacer el match'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _loadChats(); // Recargar si falla
                          }
                        },
                        child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: otherUser['profilePhoto'] != null && otherUser['profilePhoto'] is String
                                  ? MemoryImage(
                                      base64Decode(otherUser['profilePhoto'] as String))
                                  : null,
                              child: otherUser['profilePhoto'] == null || otherUser['profilePhoto'] is! String
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
                        },                      ),                      );
                    },
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
                      backgroundImage: MemoryImage(
                        base64Decode(_savedProfilePhoto!),
                      ),
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
}
