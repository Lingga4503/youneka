import 'package:flutter/material.dart';
import 'package:flow/app/app.dart';
import 'package:flow/app/firebase/firebase_bootstrap.dart';
import 'package:flow/features/mentor/data/mentor_access_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFirebaseBootstrap.ensureInitialized();
  await MentorAccessService.instance.initialize();
  runApp(const YounekaApp());
}
