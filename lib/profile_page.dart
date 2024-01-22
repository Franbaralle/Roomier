import 'package:flutter/material.dart';
import 'package:rommier/additional_profile_images.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:photo_view/photo_view_gallery.dart';

class ProfilePage extends StatefulWidget {
  final String profileName;
  final List<MemoryImage> additionalImages;
  final MemoryImage profileImage;
  final int currentIndex;

  const ProfilePage({
    Key? key,
    required this.profileName,
    required this.profileImage,
    required this.additionalImages,
    required this.currentIndex,
  }) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<MemoryImage> additionalImages = [];
  List<MemoryImage> homeImages = [];
  int currentIndex = 0;

  void updateProfileImage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          _buildProfileImageSection(),
          const SizedBox(height: 20),
          _buildHomeSection(),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(
              widget.additionalImages.isEmpty
                  ? widget.profileImage.bytes
                  : widget.additionalImages.last.bytes,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      widget.profileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: -8,
              child: ElevatedButton(
                onPressed: _pickAdditionalImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Mi Hogar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (homeImages.length < 10) {
                      _pickHomeImages();
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, size: 40),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: homeImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          _openImageGallery(index);
                        },
                        child: Image.memory(
                          homeImages[index].bytes,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                  itemCount: homeImages.length,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: MemoryImage(homeImages[index].bytes),
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

  Future<void> _pickHomeImages() async {
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
            homeImages.add(MemoryImage(Uint8List.fromList(imageData)));
          });
        });
      }
    });
  }

  Future<void> _pickAdditionalImage() async {
    /*  final html.FileUploadInputElement uploadInput =
    html.FileUploadInputElement()..click();
    uploadInput.onChange.listen((e) {
      final List<html.File> files = uploadInput.files!;
      if (files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((event) {
          final result = reader.result as String;
          final imageData = base64.decode(result.split(',')[1]);
          setState(() {
            if (widget.currentIndex >= 0 &&
                widget.currentIndex < widget.additionalImages.length) {
              widget.additionalImages[widget.currentIndex] =
                  MemoryImage(Uint8List.fromList(imageData));
            } else {
              return;
            }
          });
                   });
      }
    });
  }
           */
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AdditionalImagesPage(
                    additionalImages: widget.additionalImages)
        )
    );
  }
}