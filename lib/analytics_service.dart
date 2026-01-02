import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AnalyticsService {
  final AuthService _authService = AuthService();

  // Trackear un evento genérico
  Future<void> trackEvent(String eventType, {Map<String, dynamic>? metadata}) async {
    try {
      final token = await _authService.loadUserData('accessToken');
      if (token == null) return; // No trackear si no hay sesión

      final response = await http.post(
        Uri.parse('${AuthService.api}/analytics/track'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventType': eventType,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 201) {
        print('✓ Analytics: $eventType tracked');
      } else {
        print('✗ Analytics: Failed to track $eventType - ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Analytics error: $e');
      // No lanzar error para no interrumpir la experiencia del usuario
    }
  }

  // Eventos específicos con métodos dedicados

  Future<void> trackLogin() async {
    await trackEvent('login');
  }

  Future<void> trackProfileView(String viewedUsername) async {
    await trackEvent('profile_view', metadata: {'viewedUser': viewedUsername});
  }

  Future<void> trackMatchAction(String targetUsername, String action) async {
    // action: 'like' o 'dislike'
    await trackEvent('match_action', metadata: {
      'targetUser': targetUsername,
      'action': action,
    });
  }

  Future<void> trackMessageSent(String recipientUsername, String? chatId) async {
    await trackEvent('message_sent', metadata: {
      'recipientUser': recipientUsername,
      'chatId': chatId,
    });
  }

  Future<void> trackRevealInfo(String matchedUsername, String infoType) async {
    // infoType: 'zones', 'budget', 'contact'
    await trackEvent('reveal_info', metadata: {
      'matchedUser': matchedUsername,
      'infoType': infoType,
    });
  }

  Future<void> trackSearch(Map<String, dynamic> filters) async {
    await trackEvent('search', metadata: {'filters': filters});
  }

  Future<void> trackSignup() async {
    await trackEvent('signup');
  }

  // Obtener estadísticas del usuario actual
  Future<Map<String, dynamic>?> getMyStats({String? startDate, String? endDate}) async {
    try {
      final token = await _authService.loadUserData('accessToken');
      if (token == null) return null;

      String url = '${AuthService.api}/analytics/my-stats';
      if (startDate != null || endDate != null) {
        url += '?';
        if (startDate != null) url += 'startDate=$startDate&';
        if (endDate != null) url += 'endDate=$endDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting analytics stats: $e');
      return null;
    }
  }

  // Obtener estadísticas globales (solo admin)
  Future<Map<String, dynamic>?> getGlobalStats({String? startDate, String? endDate}) async {
    try {
      final token = await _authService.loadUserData('accessToken');
      if (token == null) return null;

      String url = '${AuthService.api}/analytics/global-stats';
      if (startDate != null || endDate != null) {
        url += '?';
        if (startDate != null) url += 'startDate=$startDate&';
        if (endDate != null) url += 'endDate=$endDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting global stats: $e');
      return null;
    }
  }
}
