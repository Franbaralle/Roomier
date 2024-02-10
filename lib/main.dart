import 'package:flutter/material.dart';
import 'package:rommier/home.dart';
import 'login_page.dart';
import 'routes.dart';
import 'date.dart';
import 'register.dart';
import 'preferences.dart';
import 'personal_info.dart';
import 'profile_photo.dart';
import 'profile_page.dart';
import 'email_confirmation_page.dart';
import 'not_found_page.dart';

void main() {
  runApp(MaterialApp(
    title: 'Roomier',
    initialRoute: loginRoute,
    routes: {
      loginRoute: (context) => LoginPage(),
      registerDateRoute: (context) => DatePage(),
      registerRoute: (context) => RegisterPage(),
      registerPreferencesRoute: (context) {
        final arguments = ModalRoute.of(context)!.settings.arguments;
        if (arguments != null && arguments is Map<String, dynamic>) {
          dynamic username = arguments['username'];
          dynamic email = arguments['email'];
          return PreferencesPage(username: username?.toString() ?? '', email: email?.toString() ?? '');
        }
        return PreferencesPage(username: '', email: '');
      },
      registerPersonalInfoRoute: (context) {
        final Map<String, dynamic>? arguments =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

        if (arguments != null) {
          final String username = arguments['username'] as String;
          final String email = arguments['email'] as String;
          return PersonalInfoPage(username: username, email: email);
        } else {
          return Container();
        }
      },
      registerProfilePhotoRoute: (context) {
        final Map<String, dynamic>? arguments =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (arguments != null) {
          final String username = arguments['username'] as String;
          final String email = arguments['email'] as String? ?? '';
          return ProfilePhotoPage(username: username, email: email);
        } else {
          return Container();
        }
      },
      profilePageRoute: (context) {
        final Map<String, dynamic>? arguments =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

        if (arguments != null) {
          final String? username = arguments['username'] as String?;
          return ProfilePage(username: username ?? '');
        } else {
          return Container(); // O proporciona otro valor predeterminado
        }
      },
      emailRoute: (context) {
        final Map<String, dynamic>? arguments =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          
        if(arguments != null) {
          final String? email = arguments['email'] as String? ?? '';
          return EmailConfirmationPage(email: email ?? '');
        } else {
          return Container();
        }
      },
      homeRoute: (context) => HomePage(),
    },
        onUnknownRoute: (settings) {
      // Manejo adicional de rutas no encontradas
      return MaterialPageRoute(builder: (context) => NotFoundPage());
        }
  ));
}
