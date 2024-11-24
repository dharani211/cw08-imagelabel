import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(ImageLabelingApp());
}

class ImageLabelingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageLabelingScreen(),
    );
  }
}

class ImageLabelingScreen extends StatefulWidget {
  @override
  _ImageLabelingScreenState createState() => _ImageLabelingScreenState();
}

class _ImageLabelingScreenState extends State<ImageLabelingScreen> {
  File? _selectedImage;
  List<String> _labels = [];
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from the camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _labelImage();
    }
  }

  // Function to label objects in the selected image using Firebase ML Kit
  Future<void> _labelImage() async {
    if (_selectedImage == null) return;

    final inputImage = InputImage.fromFile(_selectedImage!);
    final imageLabeler = ImageLabeler(
      options:
          ImageLabelerOptions(confidenceThreshold: 0.5), // Confidence threshold
    );

    try {
      final List<ImageLabel> labels =
          await imageLabeler.processImage(inputImage);

      print('Detected labels:');
      for (var label in labels) {
        print(
            '${label.label} - ${(label.confidence * 100).toStringAsFixed(2)}%');
      }

      setState(() {
        _labels = labels
            .map((label) =>
                '${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)')
            .toList();
      });
    } catch (e) {
      print('Error during image labeling: $e');
    } finally {
      imageLabeler.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Labeling App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the selected image
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Text('No image selected'),
                ),
              ),
            const SizedBox(height: 16),
            // Buttons to pick an image from the camera or gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Display the detected labels
            Expanded(
              child: _labels.isNotEmpty
                  ? ListView.builder(
                      itemCount: _labels.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.label),
                          title: Text(_labels[index]),
                        );
                      },
                    )
                  : Center(
                      child: Text('No labels detected'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
