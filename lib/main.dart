import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Kit Image Labeling',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageLabelingPage(),
    );
  }
}

class ImageLabelingPage extends StatefulWidget {
  @override
  _ImageLabelingPageState createState() => _ImageLabelingPageState();
}

class _ImageLabelingPageState extends State<ImageLabelingPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  List<ImageLabel>? _labels;

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage == null) return;

    setState(() {
      _imageFile = pickedImage;
      _labels = null;
    });

    _labelImage(pickedImage);
  }

  Future<void> _labelImage(XFile imageFile) async {
    final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
    final ImageLabeler labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    try {
      final labels = await labeler.processImage(inputImage);

      setState(() {
        _labels = labels;
      });
    } catch (e) {
      print('Error labeling image: $e');
    } finally {
      labeler.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Labeling with ML Kit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_imageFile != null)
              Image.file(
                File(_imageFile!.path),
                height: 200,
                fit: BoxFit.cover,
              ),
            if (_labels != null) ...[
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _labels!.length,
                  itemBuilder: (context, index) {
                    final label = _labels![index];
                    return ListTile(
                      title: Text(label.label),
                      subtitle: Text(
                          'Confidence: ${(label.confidence * 100).toStringAsFixed(2)}%'),
                    );
                  },
                ),
              ),
            ],
            Spacer(),
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
          ],
        ),
      ),
    );
  }
}
