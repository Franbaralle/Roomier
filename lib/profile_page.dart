import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:typed_data';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userInfo;
  Image? profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = await authService.getUserInfo(widget.username);

      if (user != null) {
        setState(() {
          userInfo = user;
        });
      }

      if (userInfo?['profilePhoto'] != null) {
        // Convierte la cadena Base64 a datos binarios y actualiza el estado
        final String base64String = userInfo?['profilePhoto'];
        final Uint8List imageData = base64Decode(base64String);
        setState(() {
          profilePhoto = Image.memory(imageData);
        });
      }
    } catch (error) {
      print('Error loading user information: $error');
      // Puedes manejar el error de alguna manera (por ejemplo, mostrar un mensaje al usuario)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
  if (userInfo == null) {
    return Center(child: CircularProgressIndicator());
  } else {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ..._buildProfileContentList(),
      ],
    );
  }
}

List<Widget> _buildProfileContentList() {
  return [
    _buildProfileImage(),
    SizedBox(height: 20),
    _buildAdditionalImages(),
    SizedBox(height: 20),
    _buildHomeImages(),
  ];
}

Widget _buildProfileImage() {
  final dynamic profilePhoto = userInfo?['profilePhoto'];

  if (profilePhoto != null && profilePhoto is String) {
    try {
      final Uint8List bytes = base64Decode(profilePhoto);

      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 400,
            height: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ClipRRect(
              child: Image.memory(bytes, width: 400, height: 500, fit: BoxFit.cover),
            ),
          ),
          Container(
            width: 400,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15.0,
                  //spreadRadius: 10.0,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8.0,
            bottom: 8.0,
            child: Text(
              userInfo?['username'] ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error decoding profile image: $e');
    }
  } else {
    print('Profile photo is null or not a String (base64): $profilePhoto');
  }

  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey,
    ),
    child: const Icon(Icons.account_circle, size: 100, color: Colors.white),
  );
}

  Widget _buildAdditionalImages() {
    // Implementa según tus necesidades
    return Container();
  }

  Widget _buildHomeImages() {
    // Implementa según tus necesidades
    return Container();
  }
}
