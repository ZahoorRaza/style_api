import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saver_gallery/saver_gallery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Style App',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: const ImageStyleScreen(),
    );
  }
}

class ImageStyleScreen extends StatefulWidget {
  const ImageStyleScreen({super.key});

  @override
  State<ImageStyleScreen> createState() => _ImageStyleScreenState();
}

class _ImageStyleScreenState extends State<ImageStyleScreen> {
  XFile? _image;
  Uint8List? _processedImageBytes;
  String _selectedStyle = 'original';
  double _intensity = 1.0;
  double _contrast = 1.0;
  bool _isLoading = false;
  String? _errorMessage;
  final Dio _dio = Dio();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
      _processedImageBytes = null;
      _errorMessage = null;
    });
  }

  Future<void> _applyStyle() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Please select an image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.90.11.15:5000/apply_style'));
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      request.fields['style'] = _selectedStyle;
      request.fields['intensity'] = _intensity.toString();
      request.fields['contrast'] = _contrast.toString();

      var response = await request.send();

      if (response.statusCode == 200) {
        _processedImageBytes = await response.stream.toBytes(); // Fixed Error 1
      } else {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _errorMessage =
          'Failed to apply style. Status code: ${response.statusCode}, Error: $responseBody';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error communicating with the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImageBytes == null) {
      setState(() {
        _errorMessage = 'No processed image to save.';
      });
      return;
    }

    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        Directory? directory;

        directory = await getExternalStorageDirectory();

        if (directory == null) {
          setState(() {
            _errorMessage = 'Could not get download directory.';
          });
          return;
        }
        String fileName = 'styled_image_${DateTime
            .now()
            .millisecondsSinceEpoch}.png';
        String filePath = '${directory.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(_processedImageBytes!);

          var response = await _dio.download(
            'http://10.90.11.15:5000/apply_style',filePath,
          );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved successfully!'),
              duration: Duration(seconds: 2),
            ),

          );
          print('Saving image to: $filePath');
        } else {
          setState(() {
            _errorMessage =
            'Failed to download image. Status code: ${response
                .statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error saving image: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Permission to access storage was denied.';
      });
    }
  }

  Future<void> _shareImage() async {
    if (_processedImageBytes == null) {
      setState(() {
        _errorMessage = 'No processed image to share.';
      });
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/shared_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(_processedImageBytes!.toList()); // Fixed Error 3
      await Share.shareXFiles([XFile(imagePath)]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Styler',
          style: TextStyle(
              fontSize:45,
              fontFamily: "FREESCPT.TFF",
          ),),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(60, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
              ),
              child: const Text('Pick an Image',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: "ALGER.TFF",
                  fontSize: 18,
                ),),
            ),
            const SizedBox(height: 20),
            if (_image != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Image:', style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: "ALGER.TFF",
                    fontSize: 19,
                  ),),
                  const SizedBox(height: 10),
                  Image.file(File(_image!.path)),
                  const SizedBox(height: 20),
                  Text('Apply Style:', style: TextStyle(
                    color: Colors.indigo,
                    fontFamily: "ALGER.TFF",
                    fontSize: 30,
                  )),
                  DropdownButton<String>(
                    value: _selectedStyle,
                    items: <String>[
                      'original',
                      'warm',
                      'cool',
                      'vintage',
                      'sepia',
                      'matte',
                      'teal_orange',
                      'noir',
                      'pastel',
                      'moody',
                      'infrared',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: Colors.orange,
                            fontFamily: "ALGER.TFF",
                            fontSize: 22,
                          ),
                        ),
                      );
                    }).toList(),

                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStyle = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Intensity (${_intensity.toStringAsFixed(1)}):', style: TextStyle(
                    color: Colors.indigo,
                    fontFamily: "ALGER.TFF",
                    fontSize: 18,
                  )),
                  Slider(
                    value: _intensity,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    activeColor: Colors.red,
                    label: _intensity.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _intensity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Contrast (${_contrast.toStringAsFixed(1)}):', style: TextStyle(
                    color: Colors.indigo,
                    fontFamily: "ALGER.TFF",
                    fontSize: 18,
                  )),
                  Slider(
                    value: _contrast,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    activeColor: Colors.green,
                    label: _contrast.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _contrast = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyStyle,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Apply Style',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'ALGER.TFF',
                        fontSize: 19,
                      ),),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            if (_processedImageBytes != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Processed Image:', style: TextStyle(
                    color: Colors.indigo,
                    fontFamily: "ALGER.TFF",
                    fontSize: 30,
                  )),
                  const SizedBox(height: 10),
                  Image.memory(_processedImageBytes!),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: _saveImage,
                        child:  Text('Download', style: TextStyle(
                          color: Colors.indigo,
                          fontFamily: "ALGER.TFF",
                          fontSize: 25,
                        ),),
                      ),
                      ElevatedButton(
                        onPressed: _shareImage,
                        child: const Text('Share', style: TextStyle(
                          color: Colors.indigo,
                          fontFamily: "ALGER.TFF",
                          fontSize: 30,
                        ),),
                      ),
                    ],
                  ),
                ],
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}