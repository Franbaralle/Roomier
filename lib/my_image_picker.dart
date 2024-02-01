import 'package:flutter/material.dart';
//import 'profile_page.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class MyImagePickerPage extends StatefulWidget {
  @override
  MyImagePickerState createState() => MyImagePickerState();
}

class MyImagePickerState extends State<MyImagePickerPage> {
  html.FileUploadInputElement? uploadInput;
  List<MemoryImage> pickedImagesList = [];
  List<Offset> imageOffsets = [];
  List<Offset> originalImagePositions = [];

  Future<void> _pickImage() async {
    uploadInput = html.FileUploadInputElement()..click();
    uploadInput!.onChange.listen((e) {
      final files = uploadInput!.files;
      if (files!.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((event) {
          final result = reader.result as String;
          final imageData = base64.decode(result.split(',')[1]);
          setState(() {
            pickedImagesList.add(MemoryImage(Uint8List.fromList(imageData)));
            imageOffsets.add(const Offset(0, 0));
            originalImagePositions.add(const Offset(0, 0));
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Picker Example")),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: List.generate(
                  pickedImagesList.length,
                  (index) => Positioned(
                    top: imageOffsets[index].dy,
                    left: imageOffsets[index].dx,
                    child: InkWell(
                      onTap: () async {
/*                         final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              profileImage: pickedImagesList[index],
                              profileName: 'Fran Baralle',
                              additionalImages: pickedImagesList,
                              currentIndex: index,
                            ),
                          ),
                        ); 
                        if (result != null && result is bool && result) */{
                          setState(() {
                            pickedImagesList[index] = MemoryImage(Uint8List(0));
                          });
                        }
                      },
                      child: ClipOval(
                        child: Image.memory(
                          pickedImagesList[index].bytes,
                          width: 300,
                          height: 300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}
