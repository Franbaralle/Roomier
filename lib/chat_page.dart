import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'reveal_info_widget.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ChatPage({Key? key, required this.profile}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _messageController = TextEditingController();
  String _currentUser = '';
  String? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeChatId();
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = await AuthService().loadUserData('username');
    setState(() {
      _currentUser = currentUser ?? '';
    });
  }

  void _initializeChatId() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _chatId = args['chatId'] as String?;
      });
      
      // Cargar mensajes existentes
      if (_chatId != null) {
        await _loadMessages(_chatId!);
      }
    }
  }

  Future<void> _loadMessages(String chatId) async {
    try {
      final messages = await ChatService.getChatMessages(chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Marcar mensajes como leídos
      if (_currentUser.isNotEmpty) {
        await ChatService.markMessagesAsRead(chatId, _currentUser);
      }
    } catch (error) {
      print('Error loading messages: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.profile['username']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ver perfil',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'username': widget.profile['username']},
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reportar usuario'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Bloquear usuario'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Widget de revelación de información
                if (_currentUser.isNotEmpty && widget.profile['username'] != null)
                  RevealInfoWidget(
                    currentUsername: _currentUser,
                    matchedUsername: widget.profile['username'],
                  ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      // Invertir el índice para mostrar mensajes más recientes abajo
                      final reversedIndex = _messages.length - 1 - index;
                      final message = _messages[reversedIndex];
                      
                      // Manejar el campo sender que puede ser un objeto o null
                      final sender = message['sender'];
                      String senderUsername = '';
                      
                      if (sender is Map<String, dynamic>) {
                        senderUsername = sender['username'] ?? '';
                      } else if (sender is String) {
                        senderUsername = sender;
                      }
                      
                      final isMine = senderUsername == _currentUser;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.blue[100]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['content'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_chatId != null &&
                              _messageController.text.isNotEmpty) {
                            _sendMessage(_chatId!, _messageController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No se pudo enviar el mensaje. El chat no está disponible.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _sendMessage(String chatId, String message) async {
    try {
      await ChatService.sendMessage(chatId, _currentUser, message);
      
      // Agregar el mensaje localmente a la lista
      setState(() {
        _messages.add({
          'sender': {'username': _currentUser},
          'content': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _messageController.clear();
      });
    } catch (error) {
      print('Error sending message: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el mensaje'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showReportDialog() {
    String? selectedReason;
    final TextEditingController descriptionController = TextEditingController();
    
    final List<Map<String, String>> reasons = [
      {'value': 'harassment', 'label': '🚨 Acoso o amenazas'},
      {'value': 'fake', 'label': '🎭 Información falsa'},
      {'value': 'spam', 'label': '📧 Spam o publicidad'},
      {'value': 'inappropriate', 'label': '⚠️ Comportamiento inapropiado'},
      {'value': 'other', 'label': '❓ Otro'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reportar usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Por qué reportas a ${widget.profile['username']}?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map((reason) => RadioListTile<String>(
                          title: Text(reason['label']!),
                          value: reason['value']!,
                          groupValue: selectedReason,
                          onChanged: (String? value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                        )),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Describe lo sucedido...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _submitReport(
                            selectedReason!,
                            descriptionController.text,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Enviar reporte'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(String reason, String description) async {
    try {
      final result = await AuthService().reportUser(
        reportedUsername: widget.profile['username'],
        reason: reason,
        description: description.isEmpty ? 'Sin descripción' : description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar el reporte'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bloquear usuario'),
          content: Text(
            '¿Estás seguro que deseas bloquear a ${widget.profile['username']}?\n\n'
            'Esta acción:\n'
            '• Eliminará tu match mutuo\n'
            '• No podrán contactarte\n'
            '• No verán tu perfil\n'
            '• Puedes desbloquearlo después desde tu perfil',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _blockUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Bloquear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser() async {
    try {
      final result = await AuthService().blockUser(widget.profile['username']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        if (result['success']) {
          // Volver a la lista de chats después de bloquear
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al bloquear el usuario'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
