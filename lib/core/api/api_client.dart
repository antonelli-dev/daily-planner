import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_response.dart';

class ApiClient {
  final SupabaseClient _client;

  ApiClient(this._client);

  // Base URL for your API
  String get baseUrl => 'http://localhost:3000/api/v1'; // Replace with your API URL

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

      final response = await _client.functions.invoke(
        'api-proxy',
        body: {
          'method': 'GET',
          'url': url,
          'headers': _headers,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        return ApiResponse.success(
          fromJson != null ? fromJson(data) : data as T,
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Request failed',
          response.status,
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
      final response = await _client.functions.invoke(
        'api-proxy',
        body: {
          'method': 'POST',
          'url': '$baseUrl$endpoint',
          'headers': _headers,
          'body': body,
        },
      );

      if (response.status >= 200 && response.status < 300) {
        final data = response.data;
        return ApiResponse.success(
          fromJson != null ? fromJson(data) : data as T,
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Request failed',
          response.status,
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
      final response = await _client.functions.invoke(
        'api-proxy',
        body: {
          'method': 'PUT',
          'url': '$baseUrl$endpoint',
          'headers': _headers,
          'body': body,
        },
      );

      if (response.status >= 200 && response.status < 300) {
        final data = response.data;
        return ApiResponse.success(
          fromJson != null ? fromJson(data) : data as T,
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Request failed',
          response.status,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Generic DELETE request
  Future<ApiResponse<bool>> delete(String endpoint) async {
    try {
      final response = await _client.functions.invoke(
        'api-proxy',
        body: {
          'method': 'DELETE',
          'url': '$baseUrl$endpoint',
          'headers': _headers,
        },
      );

      if (response.status >= 200 && response.status < 300) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Delete failed',
          response.status,
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
      final response = await _client.functions.invoke(
        'api-proxy',
        body: {
          'method': 'PATCH',
          'url': '$baseUrl$endpoint',
          'headers': _headers,
          'body': body,
        },
      );

      if (response.status >= 200 && response.status < 300) {
        final data = response.data;
        return ApiResponse.success(
          fromJson != null ? fromJson(data) : data as T,
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Request failed',
          response.status,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}