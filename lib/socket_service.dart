import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _currentUsername;
  String? _currentChatId;

  // Controladores de stream para eventos
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _stopTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, StreamController<Map<String, dynamic>>> _customEventControllers = {};

  // Getters para los streams
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onUserStopTyping => _stopTypingController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;

  // Método para escuchar eventos personalizados
  Stream<Map<String, dynamic>> onCustomEvent(String eventName) {
    if (!_customEventControllers.containsKey(eventName)) {
      _customEventControllers[eventName] = StreamController<Map<String, dynamic>>.broadcast();
      
      // Registrar el listener en el socket
      _socket?.on(eventName, (data) {
        print('🔔 Evento personalizado recibido: $eventName - $data');
        _customEventControllers[eventName]?.add(data as Map<String, dynamic>);
      });
    }
    return _customEventControllers[eventName]!.stream;
  }

  bool get isConnected => _socket?.connected ?? false;

  // Conectar al servidor Socket.IO
  void connect(String username) {
    if (_socket?.connected == true) {
      print('Socket ya conectado');
      return;
    }

    _currentUsername = username;

    // URL del backend - ajustar según entorno
    const String serverUrl = String.fromEnvironment(
      'SOCKET_URL',
      defaultValue: 'https://roomier-production.up.railway.app',
    );

    print('Conectando a Socket.IO: $serverUrl');

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      print('✅ Conectado a Socket.IO');
      if (_currentUsername != null) {
        _socket?.emit('register', _currentUsername);
      }
    });

    _socket?.onDisconnect((_) {
      print('❌ Desconectado de Socket.IO');
    });

    _socket?.onConnectError((error) {
      print('⚠️ Error de conexión Socket.IO: $error');
    });

    _socket?.onError((error) {
      print('❌ Error Socket.IO: $error');
    });

    // Recibir mensajes
    _socket?.on('receive_message', (data) {
      print('📩 Mensaje recibido: $data');
      _messageController.add(data as Map<String, dynamic>);
    });

    // Usuario escribiendo
    _socket?.on('user_typing', (data) {
      print('✍️ Usuario escribiendo: $data');
      _typingController.add(data as Map<String, dynamic>);
    });

    // Usuario dejó de escribir
    _socket?.on('user_stop_typing', (data) {
      print('✋ Usuario dejó de escribir: $data');
      _stopTypingController.add(data as Map<String, dynamic>);
    });

    // Mensajes leídos
    _socket?.on('messages_read', (data) {
      print('👀 Mensajes leídos: $data');
      _messagesReadController.add(data as Map<String, dynamic>);
    });

    // Errores
    _socket?.on('error', (data) {
      print('❌ Error del servidor: $data');
    });
  }

  // Unirse a un chat
  void joinChat(String chatId) {
    _currentChatId = chatId;
    _socket?.emit('join_chat', chatId);
    print('🔗 Uniéndose al chat: $chatId');
  }

  // Enviar mensaje
  void sendMessage({
    required String chatId,
    required String sender,
    required String message,
  }) {
    if (_socket?.connected != true) {
      print('⚠️ Socket no conectado. No se puede enviar mensaje.');
      return;
    }

    final data = {
      'chatId': chatId,
      'sender': sender,
      'message': message,
    };

    _socket?.emit('send_message', data);
    print('📤 Mensaje enviado: $message');
  }

  // Indicar que el usuario está escribiendo
  void typing(String chatId, String username) {
    _socket?.emit('typing', {
      'chatId': chatId,
      'username': username,
    });
  }

  // Indicar que el usuario dejó de escribir
  void stopTyping(String chatId, String username) {
    _socket?.emit('stop_typing', {
      'chatId': chatId,
      'username': username,
    });
  }

  // Marcar mensajes como leídos
  void markAsRead(String chatId, String username) {
    _socket?.emit('mark_as_read', {
      'chatId': chatId,
      'username': username,
    });
  }

  // Emitir evento genérico al servidor
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // Desconectar
  void disconnect() {
    print('👋 Desconectando Socket.IO');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUsername = null;
    _currentChatId = null;
  }

  // Limpiar recursos
  void dispose() {
    _messageController.close();
    _typingController.close();
    _stopTypingController.close();
    _messagesReadController.close();
    
    // Cerrar todos los controladores de eventos personalizados
    _customEventControllers.forEach((key, controller) {
      controller.close();
    });
    _customEventControllers.clear();
    
    disconnect();
  }
}
