import 'dart:convert';
import 'package:flutter/services.dart';

Future<String> loadJsonData(String pathFile) async {
  return await rootBundle.loadString(pathFile);
}

Future<Map<String, dynamic>> getLanguageData() async {
  String jsonContent = await loadJsonData('assets/language.json');
  Map<String, dynamic> jsonData = json.decode(jsonContent);
  return jsonData;
}
