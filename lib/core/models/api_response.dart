class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  // Helper methods
  bool get hasError => !isSuccess;

  String get errorMessage => error ?? 'Unknown error occurred';

  T get successData {
    if (!isSuccess || data == null) {
      throw Exception('No data available. Check isSuccess first.');
    }
    return data!;
  }

  // Functional programming style helpers
  R when<R>({
    required R Function(T data) success,
    required R Function(String error, int? statusCode) error,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return error(this.error!, statusCode);
    }
  }

  R? whenSuccess<R>(R Function(T data) callback) {
    if (isSuccess && data != null) {
      return callback(data!);
    }
    return null;
  }

  void whenError(void Function(String error, int? statusCode) callback) {
    if (hasError) {
      callback(errorMessage, statusCode);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(data: $data)';
    } else {
      return 'ApiResponse.error(error: $error, statusCode: $statusCode)';
    }
  }
}