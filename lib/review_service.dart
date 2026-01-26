import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  static const String apiUrl = 'https://roomier-qeyu.onrender.com/api/reviews';

  // Crear una nueva review
  static Future<Map<String, dynamic>> createReview({
    required String reviewer,
    required String reviewed,
    required double rating,
    required Map<String, double> categories,
    required String comment,
  }) async {
    try {
      final token = await AuthService().loadUserData('token');
      
      final response = await http.post(
        Uri.parse('$apiUrl/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reviewer': reviewer,
          'reviewed': reviewed,
          'rating': rating,
          'categories': {
            'cleanliness': categories['cleanliness'],
            'communication': categories['communication'],
            'accuracy': categories['accuracy'],
            'location': categories['location'],
          },
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Review enviada exitosamente. Será visible una vez aprobada.',
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error al crear la review',
        };
      }
    } catch (error) {
      print('Error creating review: $error');
      return {
        'success': false,
        'message': 'Error de conexión al crear la review',
      };
    }
  }

  // Obtener reviews de un usuario
  static Future<Map<String, dynamic>> getReviewsForUser({
    required String username,
    required String requesterUsername,
  }) async {
    try {
      final token = await AuthService().loadUserData('token');
      
      final response = await http.get(
        Uri.parse('$apiUrl/user/$username?requesterUsername=$requesterUsername'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data['reviews'] ?? [],
          'canViewReviews': data['canViewReviews'] ?? false,
          'reviewCount': data['reviewCount'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'reviews': [],
          'canViewReviews': false,
          'reviewCount': 0,
        };
      }
    } catch (error) {
      print('Error fetching reviews: $error');
      return {
        'success': false,
        'reviews': [],
        'canViewReviews': false,
        'reviewCount': 0,
      };
    }
  }

  // Obtener estadísticas de reviews
  static Future<Map<String, dynamic>> getReviewStats(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/stats/$username'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviewCount': data['reviewCount'] ?? 0,
          'averageRating': (data['averageRating'] ?? 0.0).toDouble(),
          'categoryAverages': {
            'cleanliness': (data['categoryAverages']['cleanliness'] ?? 0.0).toDouble(),
            'communication': (data['categoryAverages']['communication'] ?? 0.0).toDouble(),
            'accuracy': (data['categoryAverages']['accuracy'] ?? 0.0).toDouble(),
            'location': (data['categoryAverages']['location'] ?? 0.0).toDouble(),
          },
        };
      } else {
        return {
          'success': false,
          'reviewCount': 0,
          'averageRating': 0.0,
          'categoryAverages': {
            'cleanliness': 0.0,
            'communication': 0.0,
            'accuracy': 0.0,
            'location': 0.0,
          },
        };
      }
    } catch (error) {
      print('Error fetching review stats: $error');
      return {
        'success': false,
        'reviewCount': 0,
        'averageRating': 0.0,
        'categoryAverages': {
          'cleanliness': 0.0,
          'communication': 0.0,
          'accuracy': 0.0,
          'location': 0.0,
        },
      };
    }
  }

  // Verificar si un usuario puede dejar review a otro
  static Future<Map<String, dynamic>> canLeaveReview({
    required String reviewer,
    required String reviewed,
  }) async {
    try {
      final token = await AuthService().loadUserData('token');
      
      final response = await http.get(
        Uri.parse('$apiUrl/can-leave?reviewer=$reviewer&reviewed=$reviewed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'canLeave': data['canLeave'] ?? false,
          'reason': data['reason'] ?? '',
          'existingReview': data['existingReview'],
        };
      } else {
        return {
          'success': false,
          'canLeave': false,
          'reason': 'Error al verificar permisos',
        };
      }
    } catch (error) {
      print('Error checking review permissions: $error');
      return {
        'success': false,
        'canLeave': false,
        'reason': 'Error de conexión',
      };
    }
  }
}
