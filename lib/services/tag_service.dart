import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tag_models.dart';

class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  MasterTags? _data;

  // Cargar el JSON desde assets
  Future<void> loadTags() async {
    if (_data != null) return; // Ya está cargado

    try {
      final String response = await rootBundle.loadString('assets/data/master_tags.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      _data = MasterTags.fromJson(jsonData);
      print("✅ Tags cargados correctamente: ${_data!.sections.length} secciones.");
    } catch (e) {
      print("❌ Error cargando tags: $e");
      rethrow;
    }
  }

  // Obtener la configuración global
  TagConfig get config => _data!.config;

  // Obtener una sección específica (ej: 'living_habits' o 'interests')
  TagSection? getSection(String sectionId) {
    try {
      return _data!.sections.firstWhere((s) => s.id == sectionId);
    } catch (e) {
      return null;
    }
  }

  // Helper para buscar un tag específico por ID (útil para migración o visualización)
  TagItem? findTagById(String tagId) {
    // Esta búsqueda es ineficiente si se abusa, pero útil para casos puntuales
    for (var section in _data!.sections) {
      for (var cat in section.categories) {
        if (cat.directTags != null) {
          for (var tag in cat.directTags!) {
            if (tag.id == tagId) return tag;
          }
        }
        if (cat.subcategories != null) {
          for (var sub in cat.subcategories!) {
            for (var tag in sub.tags) {
              if (tag.id == tagId) return tag;
            }
          }
        }
      }
    }
    return null;
  }
}
