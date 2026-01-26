import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'firebase_options.dart';
import 'main.dart' show navigatorKey;
import 'chat_service.dart';

/// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('📩 Notificación recibida en background: ${message.messageId}');
  print('   Título: ${message.notification?.title}');
  print('   Cuerpo: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Las notificaciones en background se muestran automáticamente por Firebase
  // Este handler solo se usa para procesamiento adicional si es necesario
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Inicializar Firebase y solicitar permisos
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ NotificationService ya inicializado');
      return;
    }

    try {
      // Inicializar Firebase solo si no está inicializado
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase Core inicializado');
      } catch (e) {
        // Si Firebase ya está inicializado, continuar
        if (e.toString().contains('core/duplicate-app')) {
          print('ℹ️ Firebase ya estaba inicializado');
        } else {
          rethrow;
        }
      }

      // Inicializar FirebaseMessaging después de que Firebase esté listo
      _firebaseMessaging = FirebaseMessaging.instance;

      // Registrar el handler de background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Solicitar permisos de notificación
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación otorgados');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permisos de notificación provisionales');
      } else {
        print('❌ Permisos de notificación denegados');
        return;
      }

      // Obtener el token FCM
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        print('📱 Token FCM obtenido: ${_fcmToken!.substring(0, 20)}...');
        await _sendTokenToServer(_fcmToken!);
      }

      // Configurar handlers de notificaciones
      _setupNotificationHandlers();

      _initialized = true;
      print('✅ NotificationService inicializado completamente');
    } catch (e) {
      print('❌ Error inicializando NotificationService: $e');
    }
  }

  /// Configurar manejadores de notificaciones
  void _setupNotificationHandlers() {
    // Notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notificación recibida (foreground): ${message.messageId}');
      
      if (message.notification != null) {
        print('   Título: ${message.notification!.title}');
        print('   Cuerpo: ${message.notification!.body}');
      }

      if (message.data.isNotEmpty) {
        print('   Data: ${message.data}');
        _handleNotificationData(message.data);
      }
    });

    // Cuando el usuario toca la notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 App abierta desde notificación: ${message.messageId}');
      
      if (message.data.isNotEmpty) {
        _handleNotificationData(message.data);
      }
    });

    // Verificar si la app se abrió desde una notificación (app estaba cerrada)
    _firebaseMessaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📩 App iniciada desde notificación: ${message.messageId}');
        _handleNotificationData(message.data);
      }
    });

    // Listener para cuando el token se actualiza
    _firebaseMessaging!.onTokenRefresh.listen((String newToken) {
      print('🔄 Token FCM actualizado');
      _fcmToken = newToken;
      _sendTokenToServer(newToken);
    });
  }

  /// Enviar el token FCM al servidor
  Future<void> _sendTokenToServer(String token) async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username == null) {
        print('⚠️ No hay usuario autenticado, no se puede enviar token');
        return;
      }

      const String baseUrl = String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://roomier-qeyu.onrender.com',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM enviado al servidor correctamente');
      } else {
        print('❌ Error enviando token al servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error enviando token al servidor: $e');
    }
  }

  /// Manejar datos de la notificación
  void _handleNotificationData(Map<String, dynamic> data) async {
    print('🔔 Procesando datos de notificación: $data');

    final type = data['type'];
    
    switch (type) {
      case 'chat_message':
        // Navegar al chat específico
        final chatId = data['chatId'];
        final sender = data['sender'];
        print('💬 Mensaje de chat de $sender (ID: $chatId)');
        
        if (chatId != null && sender != null) {
          await _navigateToChat(chatId, sender);
        }
        break;
        
      case 'new_match':
        // Mostrar popup de match
        print('❤️ Nuevo match!');
        break;
        
      default:
        print('ℹ️ Tipo de notificación desconocido: $type');
    }
  }
  
  /// Navegar al chat desde una notificación
  Future<void> _navigateToChat(String chatId, String otherUsername) async {
    try {
      // Obtener el contexto del navegador
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('❌ No hay contexto de navegación disponible');
        return;
      }
      
      // Obtener información del perfil del otro usuario
      final currentUser = await AuthService().loadUserData('username');
      if (currentUser == null) {
        print('❌ No hay usuario actual');
        return;
      }
      
      // Crear perfil básico con la información disponible
      Map<String, dynamic> otherUserProfile = {
        'username': otherUsername,
      };
      
      // Intentar obtener información adicional del chat
      try {
        final chats = await ChatService.getUserChats(currentUser);
        final chat = chats.firstWhere(
          (c) => c['chatId'] == chatId,
          orElse: () => <String, dynamic>{},
        );
        
        if (chat.isNotEmpty && chat['users'] != null) {
          final users = chat['users'] as List<dynamic>;
          final foundProfile = users.firstWhere(
            (u) => u['username'] != currentUser,
            orElse: () => <String, dynamic>{},
          );
          
          if (foundProfile.isNotEmpty) {
            otherUserProfile = foundProfile;
          }
        }
      } catch (e) {
        print('⚠️ No se pudo obtener info adicional del chat: $e');
        // Continuar con el perfil básico
      }
      
      // Navegar al chat - esto siempre redirige correctamente
      print('🚀 Navegando al chat con $otherUsername (ID: $chatId)');
      
      // Remover todas las rutas hasta llegar al home y luego navegar al chat
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/chat',
        (route) => route.settings.name == '/home',
        arguments: {
          'profile': otherUserProfile,
          'chatId': chatId,
        },
      );
    } catch (e) {
      print('❌ Error navegando al chat: $e');
    }
  }

  /// Eliminar token del servidor (logout)
  Future<void> removeToken() async {
    try {
      final username = await AuthService().loadUserData('username');
      if (username == null) return;

      const String baseUrl = String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://roomier-qeyu.onrender.com',
      );

      await http.delete(
        Uri.parse('$baseUrl/api/notifications/token/$username'),
      );

      print('🗑️ Token FCM eliminado del servidor');
      _fcmToken = null;
    } catch (e) {
      print('❌ Error eliminando token del servidor: $e');
    }
  }

  /// Obtener el token FCM actual
  Future<String?> getToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }

    try {
      _fcmToken = await _firebaseMessaging!.getToken();
      return _fcmToken;
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }
}
