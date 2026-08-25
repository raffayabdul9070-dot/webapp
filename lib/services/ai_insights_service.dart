import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/heat_alert.dart';

class AiInsightsService {
  final http.Client _client = http.Client();
  final String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  void dispose() {
    _client.close();
  }

  String _fallbackInsight(HeatAlert alert) {
    switch (alert.severity) {
      case HeatSeverity.normal:
        return 'AI Analysis: Conditions are stable. Continue monitoring the grid and keep response teams on standby.';
      case HeatSeverity.watch:
        return 'AI Analysis: Elevated heat detected. Check on vulnerable residents and prepare nearby cooling resources.';
      case HeatSeverity.warning:
        return 'AI Analysis: Dangerous heat detected. Notify responders and move outdoor activity to a cooler location.';
      case HeatSeverity.emergency:
        return 'AI Analysis: Extreme heat detected. Activate emergency response and contact vulnerable residents immediately.';
    }
  }

  Future<String> generateInsight(HeatAlert alert) async {
    if (AppConfig.groqApiKey.isEmpty) {
      return _fallbackInsight(alert);
    }

    final prompt = """
You are a highly advanced, ultra-professional AI emergency response assistant (like a futuristic J.A.R.V.I.S).
Analyze this heatwave alert and provide a 2-sentence actionable emergency plan.
Keep it strictly under 30 words. Start with 'AI Analysis:'.

Alert Data:
Location: ${alert.reading.locationName} (Grid ${alert.reading.gridId})
Temperature: ${alert.reading.effectiveTempF.toStringAsFixed(1)}°F
Severity: ${alert.severity.label}
""";

    try {
      final response = await _client.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 80,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final content = choices.first['message']?['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        return _fallbackInsight(alert);
      } else {
        return _fallbackInsight(alert);
      }
    } catch (e) {
      return _fallbackInsight(alert);
    }
  }
}
