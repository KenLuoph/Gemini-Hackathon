import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/trip_plan.dart';
import '../models/validation_result.dart';

/// REST API client for backend communication
/// 
/// Handles all HTTP requests to the FastAPI backend.
/// Includes error handling, timeouts, and response parsing.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Generate a trip plan
  /// 
  /// POST /api/plan/generate
  /// 
  /// Example:
  /// ```dart
  /// final result = await apiClient.generatePlan(
  ///   intent: "Plan a date in SF",
  ///   budgetLimit: 200.0,
  ///   preferences: ["food", "art"],
  /// );
  /// ```
  Future<PlanGenerationResponse> generatePlan({
    required String intent,
    String? userId,
    double? budgetLimit,
    List<String>? preferences,
    bool? sensitiveToRain,
    List<String>? dietaryRestrictions,
    Map<String, dynamic>? mobilityConstraints,
  }) async {
    final url = Uri.parse('$baseUrl${AppConfig.apiPrefix}/plan/generate');

    // Build request body
    final Map<String, dynamic> requestBody = {
      'intent': intent,
    };

    // Add optional fields
    if (userId != null) {
      requestBody['user_id'] = userId;
    }

    // Build preferences object
    final Map<String, dynamic> preferencesMap = {};
    
    if (budgetLimit != null) {
      preferencesMap['budget_limit'] = budgetLimit;
    }
    
    if (preferences != null && preferences.isNotEmpty) {
      preferencesMap['preferences'] = preferences;
    }
    
    if (sensitiveToRain != null) {
      preferencesMap['sensitive_to_rain'] = sensitiveToRain;
    }
    
    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      preferencesMap['dietary_restrictions'] = dietaryRestrictions;
    }
    
    if (mobilityConstraints != null && mobilityConstraints.isNotEmpty) {
      preferencesMap['mobility_constraints'] = mobilityConstraints;
    }

    if (preferencesMap.isNotEmpty) {
      requestBody['preferences'] = preferencesMap;
    }

    try {
      if (AppConfig.enableDebugLogging) {
        print('📤 API Request: POST ${url.path}');
        print('📤 Body: ${jsonEncode(requestBody)}');
      }

      final response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(AppConfig.apiTimeout);

      if (AppConfig.enableDebugLogging) {
        print('📥 API Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return PlanGenerationResponse.fromJson(jsonData);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to generate plan: ${response.body}',
        );
      }
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected error: $e',
      );
    }
  }

  /// Confirm a plan (activate monitoring)
  /// 
  /// POST /api/plan/{planId}/confirm
  Future<Map<String, dynamic>> confirmPlan(String planId) async {
    final url = Uri.parse(
      '$baseUrl${AppConfig.apiPrefix}/plan/$planId/confirm',
    );

    try {
      if (AppConfig.enableDebugLogging) {
        print('📤 Confirming plan: $planId');
      }

      final response = await _httpClient
          .post(url, headers: {'Content-Type': 'application/json'})
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to confirm plan: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Error confirming plan: $e');
    }
  }

  /// Get plan details by ID
  /// 
  /// GET /api/plan/{planId}
  Future<TripPlan> getPlan(String planId) async {
    final url = Uri.parse(
      '$baseUrl${AppConfig.apiPrefix}/plan/$planId',
    );

    try {
      final response = await _httpClient
          .get(url)
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TripPlan.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ApiException(
          statusCode: 404,
          message: 'Plan not found',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to fetch plan: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Error fetching plan: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Response model for plan generation
class PlanGenerationResponse {
  final bool success;
  final TripPlan? data;
  final ValidationResult? validation;
  final String? error;

  const PlanGenerationResponse({
    required this.success,
    this.data,
    this.validation,
    this.error,
  });

  factory PlanGenerationResponse.fromJson(Map<String, dynamic> json) {
    return PlanGenerationResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? TripPlan.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      validation: json['validation'] != null
          ? ValidationResult.fromJson(json['validation'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// User-friendly error message
  String get userMessage {
    if (statusCode == 0) {
      return 'Network connection error. Please check your internet.';
    } else if (statusCode == 408) {
      return 'Request timeout. The server is taking too long to respond.';
    } else if (statusCode == 404) {
      return 'Resource not found.';
    } else if (statusCode >= 500) {
      return 'Server error. Please try again later.';
    } else {
      return message;
    }
  }
}