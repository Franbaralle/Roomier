import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_service.dart';

class ManageProfilePhotosPage extends StatefulWidget {
  final String username;

  const ManageProfilePhotosPage({Key? key, required this.username}) : super(key: key);

  @override
  _ManageProfilePhotosPageState createState() => _ManageProfilePhotosPageState();
}

class _ManageProfilePhotosPageState extends State<ManageProfilePhotosPage> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await PhotoService.getProfilePhotos(widget.username);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar fotos: $e');
      setState(() => _isLoading = false);
      _showError('Error al cargar fotos: $e');
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      // Calcular cuántas fotos más se pueden agregar
      final remainingSlots = 10 - _photos.length;
      
      if (remainingSlots <= 0) {
        _showError('Ya tienes 10 fotos (máximo permitido)');
        return;
      }

      // Permitir seleccionar múltiples fotos
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      // Verificar que no exceda el límite
      if (pickedFiles.length > remainingSlots) {
        _showError('Solo puedes agregar $remainingSlots fotos más');
        return;
      }

      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Convertir a Uint8List
      List<Uint8List> photoDataList = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        photoDataList.add(bytes);
      }

      // Subir fotos
      await PhotoService.uploadProfilePhotos(widget.username, photoDataList);

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Recargar fotos
      await _loadPhotos();

      _showSuccess('${pickedFiles.length} foto(s) agregada(s) exitosamente');
    } catch (e) {
      // Cerrar diálogo si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Error al subir fotos: $e');
      _showError('Error al subir fotos: $e');
    }
  }

  Future<void> _deletePhoto(String publicId) async {
    // Confirmar eliminación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de que quieres eliminar esta foto?'),
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

      await PhotoService.deleteProfilePhoto(publicId);
      
      Navigator.of(context).pop();
      await _loadPhotos();
      _showSuccess('Foto eliminada exitosamente');
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Error al eliminar foto: $e');
    }
  }

  Future<void> _setPrimaryPhoto(String publicId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await PhotoService.setPrimaryPhoto(publicId);
      
      Navigator.of(context).pop();
      
      // Forzar recarga con setState
      setState(() {
        _isLoading = true;
      });
      await _loadPhotos();
      
      // Actualizar foto en SharedPreferences para que se actualice en toda la app
      final primaryPhoto = _photos.firstWhere((p) => p['isPrimary'] == true, orElse: () => {});
      if (primaryPhoto.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhoto', primaryPhoto['url']);
      }
      
      _showSuccess('Foto principal actualizada');
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Error al cambiar foto principal: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fotos de Perfil'),
        backgroundColor: const Color(0xFF6750A4),
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con contador
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_photos.length} de 10 fotos',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _photos.length < 10 ? _pickAndUploadPhotos : null,
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
                                Icons.photo_library_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes fotos de perfil',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega hasta 10 fotos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Diseño responsive según ancho
                            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                            final spacing = constraints.maxWidth * 0.04;
                            final padding = constraints.maxWidth * 0.04;
                            
                            return GridView.builder(
                              padding: EdgeInsets.all(padding),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            final isPrimary = photo['isPrimary'] == true;

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isPrimary
                                    ? const BorderSide(color: Color(0xFF6750A4), width: 3)
                                    : BorderSide.none,
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

                                  // Badge de foto principal
                                  if (isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      color: const Color(0xFF6750A4),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PRINCIPAL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Botones de acción
                                  Row(
                                    children: [
                                      if (!isPrimary)
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _setPrimaryPhoto(photo['publicId']),
                                            icon: const Icon(Icons.star_border, size: 16),
                                            label: const Text('Principal'),
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
                        );
                      },
                    ),
                ),
              ],
            ),
      ),
    );
  }
}
