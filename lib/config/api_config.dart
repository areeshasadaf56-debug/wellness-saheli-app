// api_config.dart
//
// Single source of truth for the backend base URL. Every API service
// (eligibility_api_service.dart, and any prediction service) should read
// from ApiConfig.baseUrl rather than hardcoding a URL directly.

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
