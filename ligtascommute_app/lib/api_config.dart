import 'package:flutter/foundation.dart';

class ApiConfig {
  static final String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api/' // for Flutter Web
      : 'http://192.168.184.171:8000/api/'; // for Android or other platforms
}
