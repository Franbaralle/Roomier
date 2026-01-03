import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'reveal_info_widget.dart';
import 'socket_service.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ChatPage({Key? key, required this.profile}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _messageController = TextEditingController();
  String _currentUser = '';
  String? _chatId;
  bool _isLoading = true;
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _stopTypingSubscription;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _setupSocketListeners();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _stopTypingSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && _chatId != null) {
      // La app volvió del background, recargar mensajes
      print('🔄 App volvió del background, recargando mensajes...');
      _refreshMessages();
    }
  }
  
  /// Recargar mensajes cuando la app vuelve del background
  Future<void> _refreshMessages() async {
    if (_chatId == null) return;
    
    try {
      final messages = await ChatService.getChatMessages(_chatId!);
      setState(() {
        _messages = messages;
        _isOtherUserTyping = false; // Limpiar indicador de escritura
      });
      
      // Marcar como leído
      if (_currentUser.isNotEmpty) {
        _socketService.markAsRead(_chatId!, _currentUser);
      }
      
      print('✅ Mensajes actualizados correctamente');
    } catch (e) {
      print('❌ Error recargando mensajes: $e');
    }
  }

  void _setupSocketListeners() {
    // Escuchar mensajes recibidos
    _messageSubscription = _socketService.onMessageReceived.listen((data) {
      if (data['chatId'] == _chatId) {
        final newMessage = {
          'sender': data['message']['sender'],
          'content': data['message']['content'],
          'timestamp': data['message']['timestamp'],
          'read': data['message']['read'] ?? false,
        };
        
        // Verificar si el mensaje ya existe para evitar duplicados
        final messageExists = _messages.any((msg) => 
          msg['content'] == newMessage['content'] && 
          msg['timestamp'] == newMessage['timestamp']
        );
        
        if (!messageExists) {
          setState(() {
            _messages.add(newMessage);
            _isOtherUserTyping = false; // Limpiar indicador al recibir mensaje
          });
        }
        
        // Marcar como leído si estamos en el chat
        if (_currentUser.isNotEmpty && _chatId != null) {
          _socketService.markAsRead(_chatId!, _currentUser);
        }
      }
    });

    // Escuchar indicador de escritura
    _typingSubscription = _socketService.onUserTyping.listen((data) {
      if (data['chatId'] == _chatId && data['username'] != _currentUser) {
        setState(() {
          _isOtherUserTyping = true;
        });
      }
    });

    // Escuchar cuando dejan de escribir
    _stopTypingSubscription = _socketService.onUserStopTyping.listen((data) {
      if (data['chatId'] == _chatId) {
        setState(() {
          _isOtherUserTyping = false;
        });
      }
    });
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
    
    // Conectar socket si el usuario está cargado
    if (_currentUser.isNotEmpty) {
      _socketService.connect(_currentUser);
    }
  }

  void _initializeChatId() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final chatId = args['chatId'] as String?;
      
      if (chatId != null) {
        setState(() {
          _chatId = chatId;
        });
        
        // Cargar mensajes INMEDIATAMENTE por HTTP (no esperar socket)
        await _loadMessages(chatId);
        
        // Socket se conecta en segundo plano (no bloqueante)
        _connectSocketInBackground(chatId);
      }
    }
  }

  void _connectSocketInBackground(String chatId) async {
    // Esperar al usuario de forma asíncrona
    int attempts = 0;
    while (_currentUser.isEmpty && attempts < 100) {
      await Future.delayed(Duration(milliseconds: 50));
      attempts++;
    }
    
    if (_currentUser.isNotEmpty) {
      // Marcar mensajes como leídos ahora que tenemos el usuario
      try {
        await ChatService.markMessagesAsRead(chatId, _currentUser);
      } catch (e) {
        print('⚠️ Error marcando como leído por HTTP: $e');
      }
      
      // Conectar socket para tiempo real
      try {
        _socketService.joinChat(chatId);
        _socketService.emit('enter_chat', {'chatId': chatId, 'username': _currentUser});
        _socketService.markAsRead(chatId, _currentUser);
        print('✅ Socket conectado al chat en segundo plano');
      } catch (e) {
        print('⚠️ Socket no disponible, funcionando solo con HTTP: $e');
      }
    }
  }

  Future<void> _loadMessages(String chatId) async {
    try {
      final messages = await ChatService.getChatMessages(chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
        _isOtherUserTyping = false; // Limpiar indicador de escritura al cargar
      });
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
                // Indicador de escritura
                if (_isOtherUserTyping)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Text(
                          '${widget.profile['username']} está escribiendo...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Campo de texto y botón enviar
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
                          onChanged: (text) {
                            // Indicador de escritura
                            if (_chatId != null && text.isNotEmpty) {
                              _socketService.typing(_chatId!, _currentUser);
                              
                              // Cancelar el timer anterior
                              _typingTimer?.cancel();
                              
                              // Crear nuevo timer para detener el indicador después de 2 segundos
                              _typingTimer = Timer(const Duration(seconds: 2), () {
                                _socketService.stopTyping(_chatId!, _currentUser);
                              });
                            }
                          },
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
    if (message.trim().isEmpty) return;

    try {
      // Enviar mensaje solo via Socket.IO (tiempo real)
      // El backend se encarga de guardarlo en la BD
      _socketService.sendMessage(
        chatId: chatId,
        sender: _currentUser,
        message: message,
      );
      
      // Limpiar el controlador
      setState(() {
        _messageController.clear();
      });

      // Detener indicador de escritura
      if (_chatId != null) {
        _socketService.stopTyping(_chatId!, _currentUser);
      }
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
