// lib/main.dart

import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;
import 'package:valoqui/app.dart';
import 'package:valoqui/core/di/service_locator.dart';
import 'package:valoqui/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must init before get_it because DioClient
  // depends on SecureStorageService which uses Android Keystore
  // Note: This will throw an error until you run 'flutterfire configure'
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Exception catch (e) {
    debugPrint("Firebase not configured correctly: $e");
    // For development, we might want to continue without Firebase
    // if we are just testing UI components.
  }

  // ← ADD THIS — must happen before setupServiceLocator()
  // sherpa_onnx loads its native .so library here.
  // Any call to OfflineTts or VoiceActivityDetector before this
  // throws "Please initialize sherpa-onnx first".
  sherpa.initBindings();

  // Register all dependencies
  await setupServiceLocator();

  // Inside main(), before runApp:
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // makes status bar transparent
      statusBarIconBrightness: Brightness.light, // white icons on dark bg
    ),
  );
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ValoquiApp());
}
