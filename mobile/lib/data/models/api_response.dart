// ApiResponse wraps backend results in one common object.
// Repositories return this so ViewModels can handle success and failure the same way.
class ApiResponse<T> {
  // True when the HTTP call worked and the backend accepted the request.
  final bool success;

  // Message from the backend, or a simple app-made network error message.
  final String? message;

  // Optional data, already converted into the Dart type the caller expects.
  final T? data;

  ApiResponse({required this.success, this.message, this.data});

  // Build an ApiResponse from backend JSON.
  // fromJsonT converts the nested data field into the correct Dart type.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }
}
