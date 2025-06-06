import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/api_response.dart';

class ApiClient {
  final SupabaseClient _client;

  ApiClient(this._client);

  // Base URL for your API

  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000/api/v1'
      : 'http://localhost:3000/api/v1';


  // Helper method to get current user ID
  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // Helper method to get auth headers
  Map<String, String> get _headers {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('No active session');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      String url = '$baseUrl$endpoint';

      if (queryParams != null && queryParams.isNotEmpty) {
        final query = Uri(queryParameters: queryParams.map(
              (key, value) => MapEntry(key, value.toString()),
        )).query;
        url += '?$query';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);

        // Handle your API's response structure: {"data": ..., "success": true}
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
          final data = responseBody['data'];
          return ApiResponse.success(
            fromJson != null ? fromJson(data) : data as T,
          );
        } else {
          // Fallback for direct data response
          return ApiResponse.success(
            fromJson != null ? fromJson(responseBody) : responseBody as T,
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        return ApiResponse.error(
          errorBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);

        // Handle your API's response structure: {"data": ..., "success": true}
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
          final data = responseBody['data'];
          return ApiResponse.success(
            fromJson != null ? fromJson(data) : data as T,
          );
        } else {
          // Fallback for direct data response
          return ApiResponse.success(
            fromJson != null ? fromJson(responseBody) : responseBody as T,
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        return ApiResponse.error(
          errorBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);

        // Handle your API's response structure: {"data": ..., "success": true}
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
          final data = responseBody['data'];
          return ApiResponse.success(
            fromJson != null ? fromJson(data) : data as T,
          );
        } else {
          // Fallback for direct data response
          return ApiResponse.success(
            fromJson != null ? fromJson(responseBody) : responseBody as T,
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        return ApiResponse.error(
          errorBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Generic DELETE request
  Future<ApiResponse<bool>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(true);
      } else {
        final errorBody = json.decode(response.body);
        return ApiResponse.error(
          errorBody['message'] ?? 'Delete failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);

        // Handle your API's response structure: {"data": ..., "success": true}
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
          final data = responseBody['data'];
          return ApiResponse.success(
            fromJson != null ? fromJson(data) : data as T,
          );
        } else {
          // Fallback for direct data response
          return ApiResponse.success(
            fromJson != null ? fromJson(responseBody) : responseBody as T,
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        return ApiResponse.error(
          errorBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}