import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'routes.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> homeProfiles = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeProfiles();
  }

  Future<void> _fetchHomeProfiles() async {
    try {
      final authService = AuthService();
      final profiles = await authService.fetchHomeProfiles();
      setState(() {
        homeProfiles = profiles.cast<Map<String, dynamic>>(); // Cast a Map<String, dynamic>
      });
    } catch (error) {
      print('Error fetching random profiles: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles al Azar'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: homeProfiles.length,
              itemBuilder: (context, index) {
                final profile = homeProfiles[index];
                return ListTile(
                  title: Text(profile['username']),
                  leading: CircleAvatar(
                    backgroundImage: profile['profilePhoto'] != null
                        ? MemoryImage(
                            base64Decode(profile['profilePhoto']),
                          )
                        : const AssetImage('assets/default_profile_image.jpg') as ImageProvider<Object>, // Cast a ImageProvider<Object>
                  ),
                );
              },
            ),
          ),
          BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    // Lógica para el botón del rayo
                  },
                  icon: const Icon(Icons.flash_on),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, profilePageRoute );
                  },
                  icon: const Icon(Icons.person),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
