import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL for the Flask backend hosting the eligibility endpoints.
const String _baseUrl = 'https://areeshasadaf56.pythonanywhere.com';

/// A single selectable medical condition, as returned by GET /conditions.
class Condition {
  final String id;
  final String label;

  Condition({required this.id, required this.label});

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(id: json['id'] as String, label: json['label'] as String);
  }
}

/// A single contraceptive method, as returned by GET /methods_reference.
class MethodInfo {
  final String id;
  final String label;

  MethodInfo({required this.id, required this.label});

  factory MethodInfo.fromJson(Map<String, dynamic> json) {
    return MethodInfo(id: json['id'] as String, label: json['label'] as String);
  }
}

/// The eligibility result for one method, as returned by POST /eligibility.
class MethodResult {
  final String methodLabel;
  final int category;

  MethodResult({required this.methodLabel, required this.category});

  factory MethodResult.fromJson(Map<String, dynamic> json) {
    return MethodResult(
      methodLabel: json['method_label'] as String,
      category: json['category'] as int,
    );
  }
}

/// One row of the effectiveness comparison, as returned by GET /effectiveness.
class EffectivenessEntry {
  final String method;
  final num typicalUseFailurePercent;
  final String? note;

  EffectivenessEntry({
    required this.method,
    required this.typicalUseFailurePercent,
    this.note,
  });

  factory EffectivenessEntry.fromJson(Map<String, dynamic> json) {
    return EffectivenessEntry(
      method: json['method'] as String,
      typicalUseFailurePercent: json['typical_use_failure_percent'] as num,
      note: json['note'] as String?,
    );
  }
}

class EligibilityApiService {
  Future<List<Condition>> fetchConditions() async {
    final response = await http.get(Uri.parse('$_baseUrl/conditions'));
    if (response.statusCode != 200) {
      throw Exception('Could not load conditions (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => Condition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MethodInfo>> fetchMethodsReference() async {
    final response = await http.get(Uri.parse('$_baseUrl/methods_reference'));
    if (response.statusCode != 200) {
      throw Exception('Could not load methods (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => MethodInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EffectivenessEntry>> fetchEffectiveness() async {
    final response = await http.get(Uri.parse('$_baseUrl/effectiveness'));
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load effectiveness data (${response.statusCode})',
      );
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => EffectivenessEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MethodResult>> checkEligibility(List<String> conditionIds) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/eligibility'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'condition_ids': conditionIds}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(
        body['detail'] ??
            'Could not check eligibility (${response.statusCode})',
      );
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => MethodResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
