// // ignore_for_file: avoid_print

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:flutter/services.dart';
// import 'package:uuid/uuid.dart';
// import 'dart:io';
// // ignore: unused_import
// import 'dart:typed_data';

// class FaceCameraPage extends StatefulWidget {
//   const FaceCameraPage({Key? key}) : super(key: key);

//   @override
//   State<FaceCameraPage> createState() => _FaceCameraPageState();
// }

// class _FaceCameraPageState extends State<FaceCameraPage> with SingleTickerProviderStateMixin {
//   CameraController? controller;
//   FaceDetector? faceDetector;
//   Database? database;
//   String? _errorMessage;
//   bool _isLoading = true;
//   bool _permissionDenied = false;
//   bool _faceDetected = false;
//   bool _cameraInitialized = false;
//   bool _isProcessing = false;
//   CameraLensDirection _selectedLens = CameraLensDirection.front;
//   List<CameraDescription> _availableCameras = [];
//   List<Face> _detectedFaces = [];
//   final Uuid _uuid = const Uuid();
//   late BuildContext builderContext;
//   late AnimationController _scanAnimationController;
//   late Animation<double> _scanAnimation;

//   void _showSnackBar(BuildContext context, String message, {Color backgroundColor = Colors.blue}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//       ),
//     );
//   }

//   Future<void> _saveFaceRecord(BuildContext context, List<Face> faces) async {
//     if (database == null) return;
    
//     try {
//       for (Face face in faces) {
//         String faceUuid = _uuid.v4();
//         String timestamp = DateTime.now().toIso8601String();
//         String faceBounds = '${face.boundingBox.left},${face.boundingBox.top},${face.boundingBox.right},${face.boundingBox.bottom}';
        
//         await database!.insert(
//           'face_records',
//           {
//             'uuid': faceUuid,
//             'timestamp': timestamp,
//             'face_bounds': faceBounds,
//           },
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );
        
//         print('FaceCameraPage: Saved face record with UUID: $faceUuid');
        
//         if (mounted) {
//           _showSnackBar(
//             context,
//             'Face detected and saved! UUID: ${faceUuid.substring(0, 8)}...',
//             backgroundColor: Colors.green,
//           );
//           Navigator.pop(context, faceUuid);
//         }
//       }
//     } catch (e) {
//       print('FaceCameraPage: Error saving face record: $e');
//     }
//   }

//   Future<void> _switchCamera(BuildContext context) async {
//     if (_availableCameras.length < 2) {
//       _showSnackBar(context, 'Only one camera available on this device');
//       return;
//     }

//     setState(() {
//       _selectedLens = _selectedLens == CameraLensDirection.front 
//           ? CameraLensDirection.back 
//           : CameraLensDirection.front;
//       _isLoading = true;
//       _cameraInitialized = false;
//       _faceDetected = false;
//       _detectedFaces.clear();
//     });
    
//     await _setupCamera();
//   }

//   Future<void> _captureImage(BuildContext context) async {
//     if (controller != null && controller!.value.isInitialized) {
//       try {
//         final image = await controller!.takePicture();
//         if (mounted) {
//           final inputImage = InputImage.fromFilePath(image.path);
//           final faces = await faceDetector!.processImage(inputImage);
          
//           if (faces.isNotEmpty) {
//             String faceUuid = _uuid.v4();
//             String timestamp = DateTime.now().toIso8601String();
//             String faceBounds = '${faces.first.boundingBox.left},${faces.first.boundingBox.top},${faces.first.boundingBox.right},${faces.first.boundingBox.bottom}';
            
//             await database!.insert(
//               'face_records',
//               {
//                 'uuid': faceUuid,
//                 'timestamp': timestamp,
//                 'face_bounds': faceBounds,
//               },
//               conflictAlgorithm: ConflictAlgorithm.replace,
//             );
            
//             print('FaceCameraPage: Saved face record with UUID: $faceUuid');
//             Navigator.pop(context, faceUuid);
//           } else {
//             _showSnackBar(
//               context,
//               'No face detected in captured image. Please try again.',
//               backgroundColor: Colors.orange,
//             );
//           }
//         }
//       } catch (e) {
//         _showSnackBar(
//           context,
//           'Failed to capture image: ${e.toString()}',
//           backgroundColor: Colors.red,
//         );
//       }
//     } else {
//       _showSnackBar(
//         context,
//         'Camera not ready. Please wait...',
//         backgroundColor: Colors.orange,
//       );
//     }
//   }

//   Future<void> _showFaceRecords(BuildContext context) async {
//     final records = await _getFaceRecords();
    
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (BuildContext dialogContext) => AlertDialog(
//           title: const Text('Recent Face Records'),
//           content: SizedBox(
//             width: double.maxFinite,
//             height: 300,
//             child: records.isEmpty
//                 ? const Center(child: Text('No face records found'))
//                 : ListView.builder(
//                     itemCount: records.length,
//                     itemBuilder: (context, index) {
//                       final record = records[index];
//                       return ListTile(
//                         title: Text('UUID: ${record['uuid'].substring(0, 8)}...'),
//                         subtitle: Text('Time: ${DateTime.parse(record['timestamp']).toLocal()}'),
//                         trailing: const Icon(Icons.face),
//                       );
//                     },
//                   ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     print('FaceCameraPage: initState called');
//     _initializeServices();
//     _scanAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//     _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _scanAnimationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   Future<void> _initializeServices() async {
//     try {
//       print('FaceCameraPage: Starting initialization');
//       await _initializeDatabase();
//       await _initializeFaceDetector();
//       await _checkAvailableCameras();
//       await _checkPermissions();
      
//       if (!_permissionDenied && _availableCameras.isNotEmpty) {
//         print('FaceCameraPage: Permissions granted, setting up camera');
//         await _setupCamera();
//       } else {
//         print('FaceCameraPage: Camera setup skipped - Permission denied or no cameras available');
//       }
//     } catch (e) {
//       print('FaceCameraPage: Error during initialization: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to initialize services: ${e.toString()}';
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _initializeDatabase() async {
//     try {
//       print('FaceCameraPage: Initializing database');
//       final databasePath = await getDatabasesPath();
//       final path = join(databasePath, 'face_recognition.db');
      
//       database = await openDatabase(
//         path,
//         version: 1,
//         onCreate: (db, version) {
//           return db.execute(
//             'CREATE TABLE face_records(id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT NOT NULL, timestamp TEXT NOT NULL, face_bounds TEXT)',
//           );
//         },
//       );
//       print('FaceCameraPage: Database initialized successfully');
//     } catch (e) {
//       print('FaceCameraPage: Error initializing database: $e');
//       rethrow;
//     }
//   }

//   Future<void> _initializeFaceDetector() async {
//     try {
//       print('FaceCameraPage: Initializing face detector');
//       final options = FaceDetectorOptions(
//         enableContours: true,
//         enableLandmarks: true,
//         enableClassification: true,
//         enableTracking: true,
//         minFaceSize: 0.1,
//         performanceMode: FaceDetectorMode.fast,
//       );
//       faceDetector = FaceDetector(options: options);
//       print('FaceCameraPage: Face detector initialized successfully');
//     } catch (e) {
//       print('FaceCameraPage: Error initializing face detector: $e');
//       rethrow;
//     }
//   }

//   Future<void> _checkAvailableCameras() async {
//     try {
//       print('FaceCameraPage: Checking available cameras');
//       _availableCameras = await availableCameras();
//       print('FaceCameraPage: Found ${_availableCameras.length} cameras');
      
//       if (_availableCameras.isEmpty) {
//         print('FaceCameraPage: No cameras found');
//         if (mounted) {
//           setState(() {
//             _errorMessage = 'No cameras found on this device.';
//             _isLoading = false;
//           });
//         }
//         return;
//       }

//       // Check if selected lens is available, otherwise use first available
//       bool hasSelectedLens = _availableCameras.any(
//         (cam) => cam.lensDirection == _selectedLens
//       );
      
//       if (!hasSelectedLens) {
//         print('FaceCameraPage: Selected lens not available, using first available camera');
//         _selectedLens = _availableCameras.first.lensDirection;
//       }
//     } catch (e) {
//       print('FaceCameraPage: Error checking cameras: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Error checking available cameras: ${e.toString()}';
//           _isLoading = false;
//         });
//       }
//       rethrow;
//     }
//   }

//   Future<void> _checkPermissions() async {
//     print('FaceCameraPage: Checking camera permissions');
//     var status = await Permission.camera.status;
//     print('FaceCameraPage: Current permission status: $status');
    
//     if (status.isDenied) {
//       print('FaceCameraPage: Requesting camera permission');
//       status = await Permission.camera.request();
//       print('FaceCameraPage: Permission request result: $status');
//     }
    
//     if (status.isGranted) {
//       print('FaceCameraPage: Camera permission granted');
//     } else if (status.isPermanentlyDenied) {
//       print('FaceCameraPage: Camera permission permanently denied');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Camera permission is permanently denied. Please enable it in app settings.';
//           _permissionDenied = true;
//           _isLoading = false;
//         });
//       }
//     } else {
//       print('FaceCameraPage: Camera permission denied');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Camera permission is required to use this feature.';
//           _permissionDenied = true;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _setupCamera() async {
//     try {
//       print('FaceCameraPage: Setting up camera');
//       if (controller != null) {
//         print('FaceCameraPage: Disposing previous controller');
//         await controller!.dispose();
//         controller = null;
//       }

//       // Add delay to ensure proper cleanup
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       final cameraDescription = _availableCameras.firstWhere(
//         (camera) => camera.lensDirection == _selectedLens,
//         orElse: () => _availableCameras.first,
//       );
      
//       print('FaceCameraPage: Creating new CameraController with lens: ${cameraDescription.lensDirection}');
      
//       controller = CameraController(
//         cameraDescription,
//         ResolutionPreset.medium, // Also reduce resolution for better performance
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg, // Use JPEG instead
//       );

//       await controller!.initialize();
      
//       // Start image stream for face detection
//       await controller!.startImageStream((CameraImage image) async {
//         if (_isProcessing || faceDetector == null) return;
//         _isProcessing = true;
//         print('Processing frame - Format: ${image.format.raw}, Planes: ${image.planes.length}');
//         try {
//           final inputImage = _inputImageFromCameraImage(image);
//           if (inputImage == null) {
//             print('InputImage is null - conversion failed');
//             return;
//           }
          
//           final faces = await faceDetector!.processImage(inputImage);
//           print('Found ${faces.length} faces');

          
//           if (mounted) {
//             print('FaceCameraPage: Processing frame - Found ${faces.length} faces');
//             if (faces.isNotEmpty) {
//               print('FaceCameraPage: Face bounds - ${faces.first.boundingBox}');
              
//               setState(() {
//                 _detectedFaces = faces;
//                 _faceDetected = true;
//               });

//               // If we have a good quality face, save it and return
//               if (faces.isNotEmpty) {
//                 String faceUuid = _uuid.v4();
//                 String timestamp = DateTime.now().toIso8601String();
//                 String faceBounds = '${faces.first.boundingBox.left},${faces.first.boundingBox.top},${faces.first.boundingBox.right},${faces.first.boundingBox.bottom}';
                
//                 await database!.insert(
//                   'face_records',
//                   {
//                     'uuid': faceUuid,
//                     'timestamp': timestamp,
//                     'face_bounds': faceBounds,
//                   },
//                   conflictAlgorithm: ConflictAlgorithm.replace,
//                 );
                
//                 print('FaceCameraPage: Saved face record with UUID: $faceUuid');
                
//                 // Return the UUID to the previous screen
//                 if (mounted) {
//                   Navigator.pop(builderContext, faceUuid);
//                 }
//               }
//             } else {
//               setState(() {
//                 _detectedFaces = [];
//                 _faceDetected = false;
//               });
//             }
//           }
//         } catch (e) {
//           print('FaceCameraPage: Error processing image: $e');
//         } finally {
//           _isProcessing = false;
//         }
//       });
      
//       if (mounted) {
//         print('FaceCameraPage: Camera setup completed successfully');
//         setState(() {
//           _cameraInitialized = true;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('FaceCameraPage: Error setting up camera: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Failed to setup camera: ${e.toString()}';
//           _cameraInitialized = false;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     if (controller == null) return null;

//     // Get image rotation
//     final camera = _availableCameras.firstWhere(
//       (cam) => cam.lensDirection == _selectedLens,
//     );
    
//     final sensorOrientation = camera.sensorOrientation;
//     InputImageRotation? rotation;
    
//     if (Platform.isIOS) {
//       rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
//     } else if (Platform.isAndroid) {
//       var rotationCompensation = _orientations[controller!.value.deviceOrientation];
//       if (rotationCompensation == null) return null;
      
//       if (camera.lensDirection == CameraLensDirection.front) {
//         rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
//       } else {
//         rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
//       }
//       rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
//     }
    
//     if (rotation == null) return null;

//     // Get image format
//     final format = InputImageFormatValue.fromRawValue(image.format.raw);
//     if (format == null) {
//       print('Unsupported format: ${image.format.raw}');
//       return null;
//     }

//     // Add explicit format support check
//     if (Platform.isAndroid && format != InputImageFormat.nv21 && format != InputImageFormat.yuv420) {
//       print('Android: Unsupported format $format');
//       return null;
//     }

//     // Handle YUV420 format (3 planes) - REMOVE the single plane check
//     return InputImage.fromBytes(
//       bytes: image.planes.first.bytes, // Use Y plane (luminance) for detection
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: format,
//         bytesPerRow: image.planes.first.bytesPerRow,
//       ),
//     );
//   }

//   final Map<DeviceOrientation, int> _orientations = {
//     DeviceOrientation.portraitUp: 0,
//     DeviceOrientation.landscapeLeft: 90,
//     DeviceOrientation.portraitDown: 180,
//     DeviceOrientation.landscapeRight: 270,
//   };

//   Future<List<Map<String, dynamic>>> _getFaceRecords() async {
//     if (database == null) return [];
    
//     try {
//       final records = await database!.query(
//         'face_records',
//         orderBy: 'timestamp DESC',
//         limit: 10, // Get last 10 records
//       );
//       return records;
//     } catch (e) {
//       print('FaceCameraPage: Error getting face records: $e');
//       return [];
//     }
//   }

//   Future<void> _retryInitialization() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _permissionDenied = false;
//       _faceDetected = false;
//       _cameraInitialized = false;
//       _detectedFaces.clear();
//     });
    
//     if (controller != null) {
//       await controller!.dispose();
//       controller = null;
//     }
    
//     // Add delay before retry
//     await Future.delayed(const Duration(milliseconds: 1000));
//     await _initializeServices();
//   }

//   Future<void> _openAppSettings() async {
//     await openAppSettings();
//   }

//   Widget _buildFaceGuide() {
//     return Center(
//       child: Container(
//         width: 250,
//         height: 250,
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: Colors.white.withOpacity(0.5),
//             width: 2,
//           ),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Stack(
//           children: [
//             // Scanning animation
//             AnimatedBuilder(
//               animation: _scanAnimation,
//               builder: (context, child) {
//                 return Positioned(
//                   top: _scanAnimation.value * 250,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 2,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.transparent,
//                           Colors.blue.withOpacity(0.5),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             // Corner decorations
//             ...List.generate(4, (index) {
//               final isTop = index < 2;
//               final isLeft = index % 2 == 0;
//               return Positioned(
//                 top: isTop ? 0 : null,
//                 bottom: isTop ? null : 0,
//                 left: isLeft ? 0 : null,
//                 right: isLeft ? null : 0,
//                 child: Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     border: Border(
//                       top: isTop ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//                       bottom: isTop ? BorderSide.none : BorderSide(color: Colors.white, width: 3),
//                       left: isLeft ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//                       right: isLeft ? BorderSide.none : BorderSide(color: Colors.white, width: 3),
//                     ),
//                   ),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCameraView() {
//     if (!_cameraInitialized || controller == null) {
//       return Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.black,
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Loading camera...',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     try {
//       final size = MediaQuery.of(builderContext).size;
//       final scale = 1 / (controller!.value.aspectRatio * size.aspectRatio);

//       return Stack(
//         children: [
//           // Camera preview with proper aspect ratio
//           Transform.scale(
//             scale: scale,
//             child: Center(
//               child: CameraPreview(controller!),
//             ),
//           ),
          
//           // Face detection overlay
//           if (_detectedFaces.isNotEmpty)
//             Positioned.fill(
//               child: CustomPaint(
//                 painter: FaceDetectorPainter(
//                   _detectedFaces,
//                   controller!.value.previewSize!,
//                 ),
//               ),
//             ),
          
//           // Face guide and scanning animation
//           _buildFaceGuide(),
          
//           // Status indicator
//           Positioned(
//             top: 20,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: _faceDetected ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     _faceDetected ? Icons.face : Icons.face_retouching_off,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     _faceDetected ? 'Face Detected' : 'Position Your Face',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           // Camera controls
//           Positioned(
//             top: 20,
//             right: 20,
//             child: Row(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
//                     onPressed: () => _switchCamera(builderContext),
//                     tooltip: 'Switch Camera Direction',
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () => Navigator.pop(builderContext),
//                     tooltip: 'Go Back',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       );
//     } catch (e) {
//       print('FaceCameraPage: Error building camera view: $e');
//       return Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.black,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red, size: 48),
//               const SizedBox(height: 16),
//               Text(
//                 'Camera Error: $e',
//                 style: const TextStyle(color: Colors.white, fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Builder(
//       builder: (BuildContext context) {
//         builderContext = context;
//         return Scaffold(
//           backgroundColor: Colors.black,
//           body: SafeArea(
//             child: Stack(
//               children: [
//                 // Camera view
//                 SizedBox(
//                   height: MediaQuery.of(context).size.height,
//                   child: _isLoading
//                       ? const Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF143CFF)),
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Initializing face recognition...',
//                                 style: TextStyle(fontSize: 16, color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         )
//                       : _errorMessage != null
//                           ? Center(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(24),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(
//                                       Icons.error_outline, 
//                                       color: Colors.red, 
//                                       size: 64,
//                                     ),
//                                     const SizedBox(height: 24),
//                                     Text(
//                                       _errorMessage!,
//                                       style: const TextStyle(
//                                         fontSize: 16, 
//                                         color: Colors.red,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                     const SizedBox(height: 32),
//                                     if (_permissionDenied) ...[
//                                       ElevatedButton.icon(
//                                         onPressed: _openAppSettings,
//                                         icon: const Icon(Icons.settings),
//                                         label: const Text('Open Settings'),
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: const Color(0xFF143CFF),
//                                           foregroundColor: Colors.white,
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 24, 
//                                             vertical: 12,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                     ],
//                                     ElevatedButton.icon(
//                                       onPressed: _retryInitialization,
//                                       icon: const Icon(Icons.refresh),
//                                       label: const Text('Retry'),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: const Color(0xFF143CFF),
//                                         foregroundColor: Colors.white,
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 24, 
//                                           vertical: 12,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             )
//                           : _buildCameraView(),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _scanAnimationController.dispose();
//     controller?.dispose();
//     faceDetector?.close();
//     database?.close();
//     super.dispose();
//   }
// }

// // Custom painter to draw face detection rectangles
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;

//   FaceDetectorPainter(this.faces, this.imageSize);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0
//       ..color = Colors.green;

//     for (Face face in faces) {
//       final double scaleX = size.width / imageSize.width;
//       final double scaleY = size.height / imageSize.height;

//       final Rect scaledRect = Rect.fromLTRB(
//         face.boundingBox.left * scaleX,
//         face.boundingBox.top * scaleY,
//         face.boundingBox.right * scaleX,
//         face.boundingBox.bottom * scaleY,
//       );

//       canvas.drawRect(scaledRect, paint);
      
//       if (face.landmarks.isNotEmpty) {
//         final Paint landmarkPaint = Paint()
//           ..style = PaintingStyle.fill
//           ..color = Colors.red;

//         for (FaceLandmark? landmark in face.landmarks.values) {
//           if (landmark != null) {
//             final Offset scaledPoint = Offset(
//               landmark.position.x * scaleX,
//               landmark.position.y * scaleY,
//             );
//             canvas.drawCircle(scaledPoint, 2, landmarkPaint);
//           }
//         }
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.faces != faces;
//   }
// }