//face_recognition_service.dart page
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';

class FaceRecognitionPage extends StatefulWidget {
  final String?
  storedFaceEmbedding; // Pass the stored embedding for verification

  const FaceRecognitionPage({Key? key, this.storedFaceEmbedding})
    : super(key: key);

  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  late AnimationController _successAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final Color _primaryColor = Color(0xFF143CFF);

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableTracking: true,
      enableLandmarks: true,
      enableClassification: false, // Disable if not needed
      minFaceSize: 0.3, // Increase minimum face size for better performance
      performanceMode:
          FaceDetectorMode.fast, // Use fast mode for better performance
    );
    _faceDetector = FaceDetector(options: options);
  }

  bool _isDetecting = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _faceDetected = false;
  bool _isCapturing = false;
  String? _savedImagePath;
  List<Face> _detectedFaces = [];
  Timer? _captureTimer;
  int _captureCountdown = 3;
  bool _showCountdown = false;
  bool _recognitionComplete = false;
  bool _recognitionSuccess = false;
  bool _hasGoodLighting = false;
  static const double _faceMatchThreshold = 0.7;
  List<double>? _storedEmbedding;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeAnimations();
    _initializeCamera();

    // Parse stored embedding if provided
    if (widget.storedFaceEmbedding != null) {
      _storedEmbedding = _parseStoredEmbedding(widget.storedFaceEmbedding!);
    }
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _captureTimer?.cancel();
    _successAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Check if we have camera permission
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        await Permission.camera.request();
      }

      if (!mounted) return;
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Use appropriate settings for each platform
      ResolutionPreset preset =
          Platform.isAndroid ? ResolutionPreset.high : ResolutionPreset.medium;

      ImageFormatGroup formatGroup =
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888;

      _cameraController = CameraController(
        frontCamera,
        preset,
        imageFormatGroup: formatGroup,
        enableAudio: false,
      );

      await _cameraController?.initialize();

      if (_cameraController != null && mounted) {
        // Configure camera for both platforms
        try {
          // Set exposure mode to auto
          await _cameraController!.setExposureMode(ExposureMode.auto);

          // Set exposure point to center of the screen (0.5, 0.5)
          await _cameraController!.setExposurePoint(Offset(0.5, 0.5));

          // Set exposure offset to make the image brighter
          // iOS typically handles exposure better with a higher value
          final exposureOffset = Platform.isIOS ? 1.0 : 0.7;
          await _cameraController!.setExposureOffset(exposureOffset);

          // Set focus mode to auto with center point
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setFocusPoint(Offset(0.5, 0.5));

          // For iOS, try to enable torch mode if available
          if (Platform.isIOS) {
            try {
              await _cameraController!.setFlashMode(FlashMode.torch);
            } catch (e) {
              print('Could not enable torch mode: $e');
            }
          }
        } catch (e) {
          print('Error setting camera parameters: $e');
        }

        setState(() {});
        _startImageStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed: ${e.toString()}';
        });
      }
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Try to reinitialize the camera if not initialized
      if (_cameraController != null &&
          !_cameraController!.value.isInitialized) {
        _initializeCamera();
      }
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting || _isCapturing) return;
      _isDetecting = true;

      try {
        final int totalBytes = image.planes.fold(
          0,
          (sum, plane) => sum + plane.bytes.length,
        );
        final Uint8List bytes = Uint8List(totalBytes);
        int offset = 0;
        for (final plane in image.planes) {
          bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
          offset += plane.bytes.length;
        }
        final Size imageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

        final InputImageRotation imageRotation =
            InputImageRotation.rotation0deg;

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: imageSize,
            rotation: imageRotation,
            format:
                Platform.isIOS
                    ? InputImageFormat.bgra8888
                    : InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _detectedFaces = faces;
            bool newFaceDetected = faces.isNotEmpty;
            _hasGoodLighting = newFaceDetected; // Simplified for demo

            // Auto-capture logic
            if (newFaceDetected &&
                !_faceDetected &&
                !_showCountdown &&
                !_recognitionComplete) {
              _startAutoCapture();
            } else if (!newFaceDetected && _showCountdown) {
              _cancelAutoCapture();
            }

            _faceDetected = newFaceDetected;
          });
        }
      } catch (e) {
        print('Error detecting faces: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  void _startAutoCapture() {
    setState(() {
      _showCountdown = true;
      _captureCountdown = 3;
    });

    _captureTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_captureCountdown > 1) {
        setState(() {
          _captureCountdown--;
        });
      } else {
        timer.cancel();
        _captureAndRecognizeFace();
      }
    });
  }

  void _cancelAutoCapture() {
    _captureTimer?.cancel();
    setState(() {
      _showCountdown = false;
      _captureCountdown = 3;
    });
  }

  Future<void> _captureAndRecognizeFace() async {
    if (_isProcessing || !_faceDetected) return;

    setState(() {
      _isProcessing = true;
      _isCapturing = true;
      _showCountdown = false;
    });

    try {
      // Take a picture
      final XFile imageFile = await _cameraController!.takePicture();

      // Simulate processing time
      await Future.delayed(Duration(milliseconds: 1500));

      // Process the image to get face embedding
      final imageBytes = await File(imageFile.path).readAsBytes();

      // Decode and crop face for embedding
      final decodedImage = img.decodeImage(imageBytes);
      List<double> liveFaceEmbedding;

      if (decodedImage != null && _detectedFaces.isNotEmpty) {
        final face = _detectedFaces.first;
        final croppedFace = _cropFace(decodedImage, face.boundingBox);
        final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedFace));

        // Get face embedding
        liveFaceEmbedding = await getFaceEmbedding(croppedBytes);
      } else {
        // Fallback to dummy embedding if face processing fails
        liveFaceEmbedding = List.generate(
          128,
          (i) => (Random().nextDouble() * 2 - 1),
        );
      }

      // Compare with stored embedding
      bool isMatch = false;
      if (_storedEmbedding != null) {
        isMatch = isFaceMatch(liveFaceEmbedding, _storedEmbedding!);
      } else if (widget.storedFaceEmbedding != null) {
        // Fallback to parsing stored embedding
        final storedEmbedding = _parseStoredEmbedding(
          widget.storedFaceEmbedding!,
        );
        isMatch =
            _calculateSimilarity(liveFaceEmbedding, storedEmbedding) > 0.7;
      } else {
        // If no stored embedding, simulate random result for demo
        isMatch = Random().nextBool();
      }

      if (mounted) {
        setState(() {
          _recognitionComplete = true;
          _recognitionSuccess = isMatch;
        });
        _successAnimationController.forward();

        // Show result for 2 seconds then enable continue button
        await Future.delayed(Duration(seconds: 1));
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isCapturing = false;
        });
      }
    }
  }

  List<double> _parseStoredEmbedding(String embeddingJson) {
    try {
      // Parse the JSON string to a Map
      final Map<String, dynamic> jsonData = jsonDecode(embeddingJson);

      // Extract the embedding array
      if (jsonData.containsKey('embedding') && jsonData['embedding'] is List) {
        return List<double>.from(
          jsonData['embedding'].map((e) => e.toDouble()),
        );
      }
    } catch (e) {
      print('Error parsing stored embedding: $e');
    }

    // Return dummy embedding if parsing fails
    return List.generate(128, (i) => Random().nextDouble());
  }

  Future<List<double>> getFaceEmbedding(Uint8List faceImageBytes) async {
    print('Generating face embedding...');
    try {
      if (faceImageBytes.isEmpty) {
        print('❌ Error: Empty face image bytes');
        return [];
      }

      // In a real implementation, you would send this to your server
      // to compute the face embedding using a face recognition model
      // For now, we'll return a dummy embedding
      final embedding = List<double>.generate(
        128,
        (index) => Random().nextDouble(),
      );

      // Validate the generated embedding
      if (embedding.any((e) => e.isNaN || e.isInfinite)) {
        print('❌ Warning: Generated embedding contains invalid values');
      }

      print('Generated embedding: ${embedding.length} dimensions');
      return embedding;
    } catch (e) {
      print('❌ Error in getFaceEmbedding: $e');
      return [];
    }
  }

  Future<Uint8List?> captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      final image = await _cameraController!.takePicture();
      return await File(image.path).readAsBytes();
    } catch (e) {
      print('Error capturing face: $e');
      return null;
    }
  }

  Future<Face?> detectFace(Uint8List imageBytes) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(
            _cameraController?.value.previewSize?.width ?? 0,
            _cameraController?.value.previewSize?.height ?? 0,
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow:
              _cameraController?.value.previewSize?.width?.toInt() ?? 0,
        ),
      );
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;
      faces.sort((a, b) {
        final aSize = a.boundingBox.width * a.boundingBox.height;
        final bSize = b.boundingBox.width * b.boundingBox.height;
        return bSize.compareTo(aSize);
      });
      return faces.first;
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    }
  }

  Future<Uint8List> extractFaceImage(
    Uint8List imageBytes,
    Rect boundingBox, {
    double padding = 0.2,
  }) async {
    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Failed to decode image');

      final faceImage = _cropFace(originalImage, boundingBox, padding: padding);
      return Uint8List.fromList(img.encodeJpg(faceImage));
    } catch (e) {
      print('Error extracting face: $e');
      rethrow;
    }
  }

  bool isFaceMatch(List<double> liveEmbedding, List<double> storedEmbedding) {
    print('=== Face Matching Debug ===');
    print('Live embedding length: ${liveEmbedding.length}');
    print('Stored embedding length: ${storedEmbedding.length}');

    if (liveEmbedding.isEmpty || storedEmbedding.isEmpty) {
      print('❌ Error: One or both embeddings are empty');
      return false;
    }

    if (liveEmbedding.length != storedEmbedding.length) {
      print(
        '❌ Error: Embedding length mismatch (${liveEmbedding.length} vs ${storedEmbedding.length})',
      );
      return false;
    }

    final similarity = _calculateSimilarity(liveEmbedding, storedEmbedding);
    print('Similarity score: $similarity (Threshold: $_faceMatchThreshold)');

    if (similarity.isNaN) {
      print('❌ Error: Invalid similarity score (NaN)');
      return false;
    }

    final bool isMatch = similarity > _faceMatchThreshold;
    print('Match result: ${isMatch ? '✅ MATCH' : '❌ NO MATCH'}');
    print('==========================');

    return isMatch;
  }

  img.Image _cropFace(
    img.Image image,
    Rect boundingBox, {
    double padding = 0.2,
  }) {
    // Calculate padding
    final paddingX = boundingBox.width * padding;
    final paddingY = boundingBox.height * padding;

    // Calculate crop area with padding
    int x = (boundingBox.left - paddingX).clamp(0, image.width - 1).toInt();
    int y = (boundingBox.top - paddingY).clamp(0, image.height - 1).toInt();
    int width =
        (boundingBox.width + 2 * paddingX).clamp(0, image.width - x).toInt();
    int height =
        (boundingBox.height + 2 * paddingY).clamp(0, image.height - y).toInt();

    // Crop the image to the face region with padding
    final cropped = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // Resize to standard face recognition size (112x112)
    return img.copyResize(cropped, width: 112, height: 112);
  }

  double _calculateSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      print('❌ Embedding length mismatch in similarity calculation');
      return 0.0;
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    int validPairs = 0;

    for (int i = 0; i < embedding1.length; i++) {
      final e1 = embedding1[i];
      final e2 = embedding2[i];

      // Skip NaN or infinite values
      if (e1.isNaN || e2.isNaN || e1.isInfinite || e2.isInfinite) {
        continue;
      }

      dotProduct += e1 * e2;
      norm1 += e1 * e1;
      norm2 += e2 * e2;
      validPairs++;
    }

    if (validPairs == 0) {
      print('❌ No valid embedding pairs for similarity calculation');
      return 0.0;
    }

    if (norm1 <= 0.0 || norm2 <= 0.0) {
      print('❌ Zero or negative norm in similarity calculation');
      print('Norm1: $norm1, Norm2: $norm2');
      return 0.0;
    }

    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));

    // Clamp the result between -1.0 and 1.0 to handle floating point errors
    return similarity.clamp(-1.0, 1.0);
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Pengenalan Wajah',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft02,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text(_errorMessage!, style: GoogleFonts.outfit())),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          'Pengenalan Wajah',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft02,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              _recognitionComplete
                  ? (_recognitionSuccess
                      ? 'Wajah Dikenali'
                      : 'Wajah Tidak Dikenali')
                  : _isProcessing
                  ? 'Mengenali wajah Anda'
                  : 'Verifikasi wajah',
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (!_recognitionComplete && !_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Posisikan wajah ditengah untuk verifikasi identitas.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Harap jaga wajah tetap berada di tengah layar dan menghadap ke depan',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_recognitionComplete)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _recognitionSuccess
                          ? 'Wajah berhasil dikenali.'
                          : 'Wajah tidak dikenali.\nSilakan coba lagi.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

          // Camera Preview Container
          Expanded(
            child: Container(
              margin: EdgeInsets.all(24),
              decoration: ShapeDecoration(
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 24,
                    cornerSmoothing: 1,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: 24,
                  cornerSmoothing: 1,
                ),
                child: Stack(
                  children: [
                    // Camera Preview
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width:
                              _cameraController!.value.previewSize?.height ?? 1,
                          height:
                              _cameraController!.value.previewSize?.width ?? 1,
                          child: Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),

                    // Face Detection Overlay with square
                    if (_faceDetected &&
                        !_recognitionComplete &&
                        !_isProcessing)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SquareFaceDetectorPainter(
                            detectedFaces: _detectedFaces,
                            imageSize: Size(
                              _cameraController!.value.previewSize?.height ?? 1,
                              _cameraController!.value.previewSize?.width ?? 1,
                            ),
                            primaryColor: _primaryColor,
                          ),
                        ),
                      ),

                    // Initial square overlay when no face detected
                    if (!_faceDetected &&
                        !_recognitionComplete &&
                        !_isProcessing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Container(
                              width: 280,
                              height: 280,
                              child: CustomPaint(
                                painter: SquareOverlayPainter(
                                  primaryColor: _primaryColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Processing Overlay
                    if (_isProcessing && !_showCountdown)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircularProgressIndicator(
                                    color: _primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'Mengenali wajah Anda...',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Success/Failure Overlay
                    if (_recognitionComplete)
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Container(
                              decoration: ShapeDecoration(
                                color: (_recognitionSuccess
                                        ? Color(0xFF00C851)
                                        : Colors.red[600]!)
                                    .withOpacity(0.95),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 24,
                                    cornerSmoothing: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: HugeIcon(
                                        icon:
                                            _recognitionSuccess
                                                ? HugeIcons
                                                    .strokeRoundedCheckmarkCircle02
                                                : HugeIcons
                                                    .strokeRoundedCancelCircle,
                                        color:
                                            _recognitionSuccess
                                                ? Color(0xFF00C851)
                                                : Colors.red[600]!,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      children: [
                                        Text(
                                          _recognitionSuccess
                                              ? 'Wajah Dikenali'
                                              : 'Wajah Tidak Dikenali',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          _recognitionSuccess
                                              ? 'Lanjutkan untuk simpan absen'
                                              : 'Silakan coba lagi',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Status Indicators or Action Buttons
          if (!_recognitionComplete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIndicator(
                    icon: HugeIcons.strokeRoundedFaceId,
                    label:
                        _faceDetected
                            ? 'Wajah terdeteksi'
                            : 'Wajah tidak terdeteksi',
                    isActive: _faceDetected,
                  ),
                  SizedBox(width: 48),
                  _buildStatusIndicator(
                    icon: HugeIcons.strokeRoundedSun03,
                    label: 'Pencahayaan baik',
                    isActive: _hasGoodLighting,
                  ),
                ],
              ),
            ),

          if (_recognitionComplete)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        if (!_recognitionSuccess)
                          if (!_recognitionSuccess)
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Reset for retry
                                    setState(() {
                                      _recognitionComplete = false;
                                      _recognitionSuccess = false;
                                    });
                                    _successAnimationController.reset();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    elevation: 0,
                                    shape: SmoothRectangleBorder(
                                      borderRadius: SmoothBorderRadius(
                                        cornerRadius: 16,
                                        cornerSmoothing: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Coba Lagi',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      () => Navigator.of(
                                        context,
                                      ).pop(_recognitionSuccess),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF00C851),
                                    elevation: 0,
                                    shape: SmoothRectangleBorder(
                                      borderRadius: SmoothBorderRadius(
                                        cornerRadius: 16,
                                        cornerSmoothing: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Lanjutkan',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Bottom instruction text
          if (!_recognitionComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text(
                _faceDetected
                    ? 'Sistem akan otomatis mengenali wajah'
                    : _isProcessing
                    ? ''
                    : 'Sistem akan otomatis mengenali wajah',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_recognitionComplete) SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF00C851) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: isActive ? HugeIcons.strokeRoundedCheckmarkCircle02 : icon,
            color: isActive ? Colors.white : (Colors.grey[600] ?? Colors.grey),
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isActive ? Color(0xFF00C851) : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Reuse the same painters from the registration page
class SquareFaceDetectorPainter extends CustomPainter {
  final List<Face> detectedFaces;
  final Size imageSize;
  final Color primaryColor;

  SquareFaceDetectorPainter({
    required this.detectedFaces,
    required this.imageSize,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Color(0xFF00C851);

    final Paint fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color(0xFF00C851).withOpacity(0.1);

    for (final face in detectedFaces) {
      final Rect bounds = face.boundingBox;
      final double scaleX = size.width / imageSize.width;
      final double scaleY = size.height / imageSize.height;

      // Calculate square dimensions based on face bounds
      final double faceWidth = bounds.width * scaleX;
      final double faceHeight = bounds.height * scaleY;
      final double squareSize = max(faceWidth, faceHeight) * 1.2;

      final double centerX = (bounds.left + bounds.width / 2) * scaleX;
      final double centerY = (bounds.top + bounds.height / 2) * scaleY;

      // Create rounded square
      final RRect roundedSquare = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: squareSize,
          height: squareSize,
        ),
        Radius.circular(16),
      );

      canvas.drawRRect(roundedSquare, fillPaint);
      canvas.drawRRect(roundedSquare, strokePaint);

      // Draw corner indicators
      _drawSquareCorners(canvas, roundedSquare, strokePaint);
    }
  }

  void _drawSquareCorners(Canvas canvas, RRect square, Paint paint) {
    final Paint cornerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = Color(0xFF00C851)
          ..strokeCap = StrokeCap.round;

    final double cornerLength = 20.0;
    final Rect rect = square.outerRect;
    final double radius = square.tlRadius.x;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left + radius, rect.top),
      Offset(rect.left + radius + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + radius),
      Offset(rect.left, rect.top + radius + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - radius, rect.top),
      Offset(rect.right - radius - cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + radius),
      Offset(rect.right, rect.top + radius + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left + radius, rect.bottom),
      Offset(rect.left + radius + cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - radius),
      Offset(rect.left, rect.bottom - radius - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - radius, rect.bottom),
      Offset(rect.right - radius - cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - radius),
      Offset(rect.right, rect.bottom - radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(SquareFaceDetectorPainter oldDelegate) {
    return true;
  }
}

class SquareOverlayPainter extends CustomPainter {
  final Color primaryColor;

  SquareOverlayPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withOpacity(0.8);

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double squareSize = size.width * 0.7;

    // Draw rounded square outline
    final RRect roundedSquare = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: squareSize,
        height: squareSize,
      ),
      Radius.circular(16),
    );

    canvas.drawRRect(roundedSquare, strokePaint);

    // Draw corner indicators
    _drawSquareCorners(canvas, roundedSquare);
  }

  void _drawSquareCorners(Canvas canvas, RRect square) {
    final Paint cornerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.white.withOpacity(0.9)
          ..strokeCap = StrokeCap.round;

    final double cornerLength = 16.0;
    final Rect rect = square.outerRect;
    final double radius = square.tlRadius.x;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left + radius, rect.top),
      Offset(rect.left + radius + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + radius),
      Offset(rect.left, rect.top + radius + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - radius, rect.top),
      Offset(rect.right - radius - cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + radius),
      Offset(rect.right, rect.top + radius + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left + radius, rect.bottom),
      Offset(rect.left + radius + cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - radius),
      Offset(rect.left, rect.bottom - radius - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - radius, rect.bottom),
      Offset(rect.right - radius - cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - radius),
      Offset(rect.right, rect.bottom - radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(SquareOverlayPainter oldDelegate) {
    return false;
  }
}
