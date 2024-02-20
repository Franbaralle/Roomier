import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'auth_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ChatPage({Key? key, required this.profile}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> _messages = [];
  TextEditingController _messageController = TextEditingController();
  String _currentUser = '';
  String? _chatId;

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

  void _initializeChatId() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _chatId = args['chatId'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.profile['username']}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_chatId != null) {
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
                  icon: Icon(Icons.send),
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
      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensaje enviado correctamente'),
          duration: Duration(seconds: 3),
        ),
      );
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
}
