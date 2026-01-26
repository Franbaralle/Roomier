import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ChatService {
  static const String apiUrl = 'https://roomier-qeyu.onrender.com/api/chat';

  // Método para crear un nuevo chat entre dos usuarios
static Future<String?> createChat(String userA, String userB, {bool isFirstStep = false, String? firstMessage}) async {
  try {
    print('Creating chat between $userA and $userB (firstStep: $isFirstStep)');
    final response = await http.post(
      Uri.parse('$apiUrl/create_chat'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userA': userA,
        'userB': userB,
        'isFirstStep': isFirstStep,
        'firstMessage': firstMessage,
      }),
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['chatId'];
    } else {
      print('Error creating chat: ${response.statusCode}');
      return null;
    }
  } catch (error) {
    print('Error creating chat: $error');
    return null;
  }
}

  // Método para enviar un mensaje en un chat existente
  static Future<Map<String, dynamic>> sendMessage(String chatId, String sender, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/send_message'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatId': chatId,
          'sender': sender,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully');
        return {'success': true, 'message': 'Mensaje enviado'};
      } else if (response.statusCode == 400) {
        // Contenido moderado
        final responseData = jsonDecode(response.body);
        return {
          'success': false, 
          'message': responseData['message'] ?? 'Contenido inapropiado detectado',
          'severity': responseData['severity']
        };
      } else {
        print('Error sending message: ${response.statusCode}');
        return {'success': false, 'message': 'Error al enviar mensaje'};
      }
    } catch (error) {
      print('Error sending message: $error');
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // Método para obtener todos los chats de un usuario
  static Future<List<Map<String, dynamic>>> getUserChats(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user_chats/$username'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> chats = responseData['chats'];
        return chats.cast<Map<String, dynamic>>();
      } else {
        print('Error fetching user chats: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching user chats: $error');
      return [];
    }
  }

  // Método para obtener el estado del chat (isFirstStep, isMatch, firstStepBy)
  static Future<Map<String, dynamic>?> getChatStatus(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/status/$chatId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        print('Error fetching chat status: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching chat status: $error');
      return null;
    }
  }

  // Método para obtener los mensajes de un chat específico
  static Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/messages/$chatId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> messages = responseData['messages'];
        return messages.cast<Map<String, dynamic>>();
      } else {
        print('Error fetching messages: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching messages: $error');
      return [];
    }
  }

  // Método para marcar mensajes como leídos
  static Future<void> markMessagesAsRead(String chatId, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/mark_as_read'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatId': chatId,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        print('Messages marked as read');
      } else {
        print('Error marking messages as read: ${response.statusCode}');
      }
    } catch (error) {
      print('Error marking messages as read: $error');
    }
  }

  // Método para obtener matches sin conversación iniciada
  static Future<List<Map<String, dynamic>>> getPendingMatches(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/pending_matches/$username'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> matches = responseData['matches'];
        return matches.cast<Map<String, dynamic>>();
      } else {
        print('Error fetching pending matches: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching pending matches: $error');
      return [];
    }
  }

  // Método para enviar una imagen en un chat
  static Future<bool> sendImage(String chatId, String sender, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/send_image'),
      );

      // Agregar los campos del formulario
      request.fields['chatId'] = chatId;
      request.fields['sender'] = sender;

      // Agregar el archivo de imagen
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      // Determinar el tipo MIME basado en la extensión del archivo
      String filename = imageFile.path.split('/').last;
      String extension = filename.split('.').last.toLowerCase();
      MediaType? contentType;
      
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        contentType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        // Por defecto, usar jpeg
        contentType = MediaType('image', 'jpeg');
      }
      
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: filename,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      print('Sending image to chat $chatId');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Image sent successfully: $responseBody');
        return true;
      } else {
        print('Error sending image: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (error) {
      print('Error sending image: $error');
      return false;
    }
  }

  // Obtener firstSteps disponibles de un usuario
  static Future<Map<String, dynamic>> getFirstStepsRemaining(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/first_steps_remaining/$username'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'firstStepsRemaining': data['firstStepsRemaining'] ?? 5,
          'isPremium': data['isPremium'] ?? false,
          'resetsWeekly': data['resetsWeekly'] ?? false
        };
      } else {
        print('Error fetching first steps: ${response.statusCode}');
        return {'firstStepsRemaining': 5, 'isPremium': false, 'resetsWeekly': false};
      }
    } catch (error) {
      print('Error fetching first steps: $error');
      return {'firstStepsRemaining': 5, 'isPremium': false, 'resetsWeekly': false};
    }
  }
}
