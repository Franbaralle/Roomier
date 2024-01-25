import 'package:flutter/material.dart';
import 'login_page.dart';
import 'routes.dart';
import 'date.dart';
import 'register.dart';
import 'preferences.dart';
import 'personal_info.dart';
import 'profile_photo.dart';

void main() {
  runApp(MaterialApp(
    title: 'Roomier',
    initialRoute: loginRoute,
    routes: {
      loginRoute: (context) => LoginPage(),
      registerDateRoute: (context) => DatePage(),
      registerRoute: (context) => RegisterPage(),
      registerPreferencesRoute: (context) => PreferencesPage(),
      registerPersonalInfoRoute: (context) => PersonalInfoPage(),
      registerProfilePhotoRoute: (context) => ProfilePhotoPage(),
    },
  ));
}
