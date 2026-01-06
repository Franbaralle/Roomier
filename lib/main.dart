import 'package:flutter/material.dart';
import 'package:rommier/home.dart';
import 'login_page.dart';
import 'routes.dart';
import 'date.dart';
import 'register.dart';
import 'preferences.dart';
import 'roommate_preferences_page.dart';
import 'living_habits_page.dart';
import 'housing_info_page.dart';
import 'personal_info.dart';
import 'profile_photo.dart';
import 'profile_page.dart';
import 'email_confirmation_page.dart';
import 'not_found_page.dart';
import 'auth_service.dart'; // Importa tu clase AuthService aquí
import 'chat_page.dart';
import 'chats_list_page.dart';
import 'terms_and_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'admin_panel_page.dart';
import 'edit_profile_page.dart';
import 'notification_service.dart';
import 'manage_profile_photos_page.dart';
import 'manage_home_photos_page.dart';

// NavigatorKey global para navegación desde notificaciones
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Asegúrate de inicializar los widgets de Flutter
  await AuthService()
      .initializeSharedPreferences(); // Inicializa SharedPreferences
  
  // Inicializar Firebase y notificaciones
  // No capturar errores aquí para ver el verdadero problema
  await NotificationService().initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
            return PreferencesPage(
                username: username?.toString() ?? '',
                email: email?.toString() ?? '');
          }
          return PreferencesPage(username: '', email: '');
        },
        roommatePreferencesRoute: (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments != null && arguments is Map<String, dynamic>) {
            dynamic username = arguments['username'];
            dynamic email = arguments['email'];
            return RoommatePreferencesPage(
                username: username?.toString() ?? '',
                email: email?.toString() ?? '');
          }
          return RoommatePreferencesPage(username: '', email: '');
        },
        livingHabitsRoute: (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments != null && arguments is Map<String, dynamic>) {
            dynamic username = arguments['username'];
            dynamic email = arguments['email'];
            return LivingHabitsPage(
                username: username?.toString() ?? '',
                email: email?.toString() ?? '');
          }
          return LivingHabitsPage(username: '', email: '');
        },
        housingInfoRoute: (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments != null && arguments is Map<String, dynamic>) {
            dynamic username = arguments['username'];
            dynamic email = arguments['email'];
            return HousingInfoPage(
                username: username?.toString() ?? '',
                email: email?.toString() ?? '');
          }
          return HousingInfoPage(username: '', email: '');
        },
        registerPersonalInfoRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;

          if (arguments != null) {
            final String username = arguments['username'] as String;
            final String email = arguments['email'] as String;
            return PersonalInfoPage(username: username, email: email);
          } else {
            return Container();
          }
        },
        registerProfilePhotoRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;
          if (arguments != null) {
            final String username = arguments['username'] as String;
            final String email = arguments['email'] as String? ?? '';
            return ProfilePhotoPage(username: username, email: email);
          } else {
            return Container();
          }
        },
        profilePageRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;

          if (arguments != null) {
            final String? username = arguments['username'] as String?;
            return ProfilePage(username: username ?? '');
          } else {
            return Container(); // O proporciona otro valor predeterminado
          }
        },
        emailRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>;

          if (arguments != null) {
            final String? email = arguments['email'] as String? ?? '';
            return EmailConfirmationPage(email: email ?? '');
          } else {
            return Container();
          }
        },
        homeRoute: (context) => HomePage(),
        chatsListRoute: (context) => ChatsListPage(),
        termsRoute: (context) => const TermsAndConditionsPage(),
        privacyRoute: (context) => const PrivacyPolicyPage(),
        adminPanelRoute: (context) => const AdminPanelPage(),
        editProfileRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;
          if (arguments == null) {
            return NotFoundPage();
          }
          return EditProfilePage(
            username: arguments['username'] as String,
            currentUserData: arguments['userData'] as Map<String, dynamic>,
          );
        },
        manageProfilePhotosRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;
          if (arguments == null) {
            return NotFoundPage();
          }
          return ManageProfilePhotosPage(
            username: arguments['username'] as String,
          );
        },
        manageHomePhotosRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;
          if (arguments == null) {
            return NotFoundPage();
          }
          return ManageHomePhotosPage(
            username: arguments['username'] as String,
            hasPlace: arguments['hasPlace'] as bool? ?? false,
          );
        },
        chatRoute: (context) {
          final Map<String, dynamic>? arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>?;

          if (arguments != null) {
            final Map<String, dynamic> profile =
                arguments['profile'] as Map<String, dynamic>;
            return ChatPage(profile: profile);
          } else {
            return ChatPage(
                profile: {}); // Proporciona un perfil predeterminado si no se pasa ninguno
          }
        },
      },
      onUnknownRoute: (settings) {
        // Manejo adicional de rutas no encontradas
        return MaterialPageRoute(builder: (context) => NotFoundPage());
      },
    );
  }
}
