import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/bootstrap/app_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  registerBundledFontLicenses();
  runApp(const ChigioBootstrapApp());
}
