import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String apiUrl = 'http://localhost:3000/api/chat';

  // Método para crear un nuevo chat entre dos usuarios
static Future<String?> createChat(String userA, String userB) async {
  try {
    print('Creating chat between $userA and $userB');
    final response = await http.post(
      Uri.parse('$apiUrl/create_chat'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userA': userA,
        'userB': userB,
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
  static Future<void> sendMessage(String chatId, String sender, String message) async {
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
      } else {
        print('Error sending message: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending message: $error');
    }
  }
}
