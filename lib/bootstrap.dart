import 'package:bloc/bloc.dart';
import 'package:cabina/app/view/app.dart';
import 'package:cabina/common/network/api_client.dart';
import 'package:cabina/common/observers/app_bloc_observer.dart';
import 'package:cabina/common/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final localStorage = LocalStorage(
    prefs: await SharedPreferences.getInstance(),
  );
  final apiClient = ApiClient();
  runApp(CabinaApp(localStorage: localStorage, apiClient: apiClient));
}
