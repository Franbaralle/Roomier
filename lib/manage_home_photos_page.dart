import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'photo_service.dart';

class ManageHomePhotosPage extends StatefulWidget {
  final String username;
  final bool hasPlace;

  const ManageHomePhotosPage({
    Key? key,
    required this.username,
    required this.hasPlace,
  }) : super(key: key);

  @override
  _ManageHomePhotosPageState createState() => _ManageHomePhotosPageState();
}

class _ManageHomePhotosPageState extends State<ManageHomePhotosPage> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.hasPlace) {
      _loadPhotos();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await PhotoService.getHomePhotos(widget.username);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar fotos del hogar: $e');
      setState(() => _isLoading = false);
      _showError('Error al cargar fotos: $e');
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      // Permitir seleccionar múltiples fotos
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      // Mostrar diálogo para agregar descripciones (opcional)
      final descriptions = await _showDescriptionDialog(pickedFiles.length);

      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Subiendo ${pickedFiles.length} foto(s)...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Convertir a Uint8List
      List<Uint8List> photoDataList = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        photoDataList.add(bytes);
      }

      // Subir fotos
      await PhotoService.uploadHomePhotos(
        widget.username,
        photoDataList,
        descriptions,
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Recargar fotos
      await _loadPhotos();

      _showSuccess('${pickedFiles.length} foto(s) del hogar agregada(s)');
    } catch (e) {
      // Cerrar diálogo si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Error al subir fotos: $e');
      _showError('Error al subir fotos: $e');
    }
  }

  Future<List<String>?> _showDescriptionDialog(int photoCount) async {
    final controllers = List.generate(
      photoCount,
      (index) => TextEditingController(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descripciones (opcional)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: photoCount,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controllers[index],
                decoration: InputDecoration(
                  labelText: 'Foto ${index + 1}',
                  hintText: 'Ej: Sala, Cocina, Habitación...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Omitir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (result != true) return null;

    return controllers.map((c) => c.text.trim()).toList();
  }

  Future<void> _deletePhoto(String publicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar esta foto del hogar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await PhotoService.deleteHomePhoto(publicId);
      
      Navigator.of(context).pop();
      await _loadPhotos();
      _showSuccess('Foto eliminada');
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Error al eliminar foto: $e');
    }
  }

  Future<void> _editDescription(Map<String, dynamic> photo) async {
    final controller = TextEditingController(text: photo['description'] ?? '');

    final newDescription = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar descripción'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Ej: Sala con vista al jardín',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newDescription == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await PhotoService.updateHomePhotoDescription(
        photo['publicId'],
        newDescription,
      );
      
      Navigator.of(context).pop();
      await _loadPhotos();
      _showSuccess('Descripción actualizada');
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Error al actualizar: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasPlace) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fotos del Hogar'),
          backgroundColor: const Color(0xFF6750A4),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No disponible',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Esta función solo está disponible para usuarios que buscan roommate y tienen lugar para compartir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos de Mi Hogar'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_photos.length} foto(s)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickAndUploadPhotos,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Grid de fotos
                Expanded(
                  child: _photos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes fotos de tu hogar',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega fotos para mostrar tu lugar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Imagen
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        photo['url'],
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: progress.expectedTotalBytes != null
                                                  ? progress.cumulativeBytesLoaded /
                                                      progress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // Descripción
                                  if (photo['description'] != null &&
                                      photo['description'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        photo['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                  // Botones de acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () => _editDescription(photo),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Editar'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _deletePhoto(photo['publicId']),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('Eliminar'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
