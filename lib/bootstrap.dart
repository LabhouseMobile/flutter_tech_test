import 'package:cabina/app/view/app.dart';
import 'package:cabina/common/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();
  runApp(CabinaApp(prefs: prefs, apiClient: apiClient));
}
