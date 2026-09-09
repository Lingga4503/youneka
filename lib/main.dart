import 'package:flutter/material.dart';
import 'package:flow/app/app.dart';
import 'package:flow/core/services/user_profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserProfileService.instance.initialize();
  runApp(const YounekaApp());
}
