import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

export 'translation_service.dart';

Future<String> translateText(String textToTranslate) async {
  final prefs = await SharedPreferences.getInstance();
  final apiUrl =
      'https://translation.googleapis.com/language/translate/v2/?key=AIzaSyB9_Z-o83Ylc_hUApIhr1BctN7NFaeA5Vg';
  final targetTranslateCode = prefs.getString('languageCode') ?? 'en';
  final response = await http.post(
    Uri.parse(apiUrl),
    body: jsonEncode({
      'q': textToTranslate,
      'target': targetTranslateCode,
    }),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final translatedText = data['data']['translations'][0]['translatedText'];
    return translatedText;
  } else {
    throw Exception('Failed to translate text');
  }
}
