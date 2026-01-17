import 'dart:convert';

class TagConfig {
  final int maxGlobalInterests;
  final bool dealBreakerEnabled;

  TagConfig({required this.maxGlobalInterests, required this.dealBreakerEnabled});

  factory TagConfig.fromJson(Map<String, dynamic> json) {
    return TagConfig(
      maxGlobalInterests: json['max_global_interests'] ?? 25,
      dealBreakerEnabled: json['deal_breaker_enabled'] ?? true,
    );
  }
}

class TagItem {
  final String id;
  final String label;
  final String icon;
  bool isSelected; // Para manejar estado en la UI

  TagItem({
    required this.id,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  factory TagItem.fromJson(Map<String, dynamic> json) {
    return TagItem(
      id: json['id'],
      label: json['label'],
      icon: json['icon'] ?? '',
    );
  }
}

class TagSubCategory {
  final String id;
  final String label;
  final List<TagItem> tags;

  TagSubCategory({required this.id, required this.label, required this.tags});

  factory TagSubCategory.fromJson(Map<String, dynamic> json) {
    return TagSubCategory(
      id: json['id'],
      label: json['label'],
      tags: (json['tags'] as List).map((e) => TagItem.fromJson(e)).toList(),
    );
  }
}

class TagCategory {
  final String id;
  final String label;
  final String selectionMode; // 'single' o 'multiple'
  final bool required;
  final String? question; // Para hábitos
  // Puede tener tags directos (Hábito) O subcategorías (Interés)
  final List<TagItem>? directTags; 
  final List<TagSubCategory>? subcategories;

  TagCategory({
    required this.id,
    required this.label,
    required this.selectionMode,
    this.required = false,
    this.question,
    this.directTags,
    this.subcategories,
  });

  factory TagCategory.fromJson(Map<String, dynamic> json) {
    return TagCategory(
      id: json['id'],
      label: json['label'],
      selectionMode: json['selection_mode'] ?? 'multiple',
      required: json['required'] ?? false,
      question: json['question'],
      directTags: json['tags'] != null 
          ? (json['tags'] as List).map((e) => TagItem.fromJson(e)).toList() 
          : null,
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List).map((e) => TagSubCategory.fromJson(e)).toList()
          : null,
    );
  }
  
  // Helper para saber si tiene subcategorías
  bool get hasSubcategories => subcategories != null && subcategories!.isNotEmpty;
}

class TagSection {
  final String id;
  final String title;
  final String description;
  final List<TagCategory> categories;

  TagSection({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
  });

  factory TagSection.fromJson(Map<String, dynamic> json) {
    return TagSection(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      categories: (json['categories'] as List)
          .map((e) => TagCategory.fromJson(e))
          .toList(),
    );
  }
}

class MasterTags {
  final TagConfig config;
  final List<TagSection> sections;

  MasterTags({required this.config, required this.sections});

  factory MasterTags.fromJson(Map<String, dynamic> json) {
    return MasterTags(
      config: TagConfig.fromJson(json['config']),
      sections: (json['sections'] as List)
          .map((e) => TagSection.fromJson(e))
          .toList(),
    );
  }
}
