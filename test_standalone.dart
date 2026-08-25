import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = '988372b529a5d134977e3e3d989d0146';
  final baseUrl = 'https://api.fortyguard.com/v1';
  final client = http.Client();

  try {
    final now = DateTime.now().toUtc();
    final requestBody = <String, dynamic>{
      'latitude': 40.4173,
      'longitude': -82.9071,
      'temperature': 91.0,
      'parameters': [
        'temperature_celsius',
        'heat_index_celsius',
        'relative_humidity_percent'
      ],
      'date_time': {
        'filter_type': 1,
        'start_date': now.toIso8601String().split('T')[0],
        'start_time': now.toIso8601String().split('T')[1].substring(0, 5),
      },
    };

    final postUri = Uri.parse('\$baseUrl/env_params');
    final postResponse = await client.post(
      postUri,
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    print('POST STATUS: \${postResponse.statusCode}');
    print('POST BODY: \${postResponse.body}');

    final postBody = jsonDecode(postResponse.body);
    final activityId = (postBody['data'] != null && postBody['data'] is Map) 
        ? postBody['data']['activity_id'] 
        : postBody['activity_id'];

    if (activityId == null) {
      print('NO ACTIVITY ID. FALLBACK DATA: \${postBody['data'] ?? postBody}');
      return;
    }

    print('POLLING FOR ACTIVITY: \$activityId');
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final statusUri = Uri.parse('\$baseUrl/status/\$activityId');
      final statusResponse = await client.get(
        statusUri,
        headers: {
          'api-key': apiKey,
          'Accept': 'application/json',
        },
      );

      print('POLL \$i STATUS: \${statusResponse.statusCode}');
      final statusBody = jsonDecode(statusResponse.body);
      final statusVal = (statusBody['data'] != null && statusBody['data'] is Map) 
          ? (statusBody['data']['status'] ?? statusBody['status']) 
          : statusBody['status'];
      final statusStr = (statusVal ?? '').toString().toLowerCase();

      print('POLL \$i STATUS STRING: \$statusStr');

      if (statusStr == 'completed') {
        final dataBlock = statusBody['data'] ?? statusBody;
        Map<String, dynamic> data = {};
        
        if (dataBlock['result'] != null && 
            dataBlock['result']['locations'] != null && 
            (dataBlock['result']['locations'] as List).isNotEmpty) {
          data = Map<String, dynamic>.from(dataBlock['result']['locations'][0]);
          print('EXTRACTED DATA: \$data');
        } else {
          print('WARNING: RESULT OR LOCATIONS IS EMPTY. DATABLOCK: \$dataBlock');
        }
        return;
      }
    }
    print('TIMED OUT!');
  } finally {
    client.close();
  }
}
