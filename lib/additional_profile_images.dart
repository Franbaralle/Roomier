import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:typed_data';

class AdditionalImagesPage extends StatefulWidget {
  final List<MemoryImage> additionalImages;

  AdditionalImagesPage({required this.additionalImages});

  @override
  _AdditionalImagesPageState createState() => _AdditionalImagesPageState();
}

class _AdditionalImagesPageState extends State<AdditionalImagesPage> {
  bool isAddingImages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imágenes Adicionales'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: widget.additionalImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _openImageGallery(index);
                  },
                  child: Image.memory(
                    widget.additionalImages[index].bytes,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          Visibility(
            visible: isAddingImages, // Usar el estado para controlar la visibilidad
            child: ElevatedButton(
              onPressed: _pickMoreImages,

              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.add, size: 40),
            ),
          ),
        ],
      ),
    );
  }

  void _pickMoreImages() {
    final html.FileUploadInputElement uploadInput =
    html.FileUploadInputElement()..click();
    uploadInput.onChange.listen((event) {
      final List<html.File> files = uploadInput.files!;
      if (files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoad.listen((e) {
          final result = reader.result as String;
          final imageData = base64.decode(result.split(',')[1]);
          setState(() {
            if (widget.additionalImages.length < 9) {
              widget.additionalImages.add(
                MemoryImage(Uint8List.fromList(imageData)),
              );
            }
            if (widget.additionalImages.length >= 9) {
              isAddingImages = false; // Desactivar la adición de imágenes
            }
          });
        });
      }
    });
  }

  void _openImageGallery(int selectedIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            body: Stack(
              children: [
                PhotoViewGallery.builder(
                  itemCount: widget.additionalImages.length,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: MemoryImage(
                        widget.additionalImages[index].bytes,
                      ),
                    );
                  },
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  pageController: PageController(initialPage: selectedIndex),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: const CircleBorder(),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
