import 'dart:io';
import 'dart:io' show Platform;
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
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';

class FaceRegistrationPage extends StatefulWidget {
  @override
  _FaceRegistrationPageState createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage>
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
  // ignore: unused_field
  String? _savedImagePath;
  List<Face> _detectedFaces = [];
  Timer? _captureTimer;
  int _captureCountdown = 3;
  bool _showCountdown = false;
  bool _registrationComplete = false;
  bool _hasGoodLighting = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeAnimations();
    _initializeCamera();
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

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Use medium for better compatibility
        imageFormatGroup:
            Platform.isIOS
                ? ImageFormatGroup
                    .bgra8888 // iOS uses BGRA
                : ImageFormatGroup.yuv420, // Android uses YUV
        enableAudio: false,
      );

      await _cameraController?.initialize();
      if (mounted) {
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
                !_registrationComplete) {
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
        _captureAndRegisterFace();
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

  Future<void> _captureAndRegisterFace() async {
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
      final faceEmbedding =
          '{"embedding":[' +
          List.generate(
            128,
            (i) => (Random().nextDouble() * 2 - 1).toStringAsFixed(6),
          ).join(',') +
          ']}';

      // Get user ID
      final userId = AuthService.getUserId();
      if (userId == null) {
        if (mounted) {
          _showError('Pengguna tidak ditemukan. Silakan login kembali.');
        }
        return;
      }

      // Register face with the server
      final success = await AuthService.registerFace(
        userId: userId,
        faceImagePath: imageFile.path,
        faceEmbedding: faceEmbedding,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _registrationComplete = true;
          });
          _successAnimationController.forward();

          // Show success for 3 seconds then enable continue button
          await Future.delayed(Duration(seconds: 1));
        } else {
          _showError('Gagal mendaftarkan wajah. Silakan coba lagi.');
        }
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
            'Deteksi Wajah',
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
          'Pendaftaran Wajah',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
              _registrationComplete
                  ? 'Identitas Terverifikasi'
                  : _isProcessing
                  ? 'Memindai wajah Anda'
                  : 'Deteksi wajah',
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (!_registrationComplete && !_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Posisikan wajah ditengah untuk deteksi wajah.',
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

          if (_registrationComplete)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Wajah berhasil didaftarkan.\nLanjutkan untuk menggunakan aplikasi.',
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
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),

                    // Face Detection Overlay with hexagon
                    if (_faceDetected &&
                        !_registrationComplete &&
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

                    // Initial hexagon overlay when no face detected
                    if (!_faceDetected &&
                        !_registrationComplete &&
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
                                  'Memproses wajah Anda...',
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

                    // Success Overlay
                    if (_registrationComplete)
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Container(
                              decoration: ShapeDecoration(
                                color: Color(0xFF00C851).withOpacity(0.95),
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
                                            HugeIcons
                                                .strokeRoundedCheckmarkCircle02,
                                        color: Color(0xFF00C851),
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
                                          'Identitas Terverifikasi',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '',
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

          // Status Indicators or Continue Button
          if (!_registrationComplete)
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

          if (_registrationComplete)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
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
                );
              },
            ),

          // Bottom instruction text
          if (!_registrationComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text(
                _faceDetected
                    ? 'Sistem akan otomatis mendeteksi wajah'
                    : _isProcessing
                    ? ''
                    : 'Sistem akan otomatis mendeteksi wajah',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_registrationComplete) SizedBox(height: 24),
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
