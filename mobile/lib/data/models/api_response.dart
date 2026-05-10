// ApiResponse wraps backend responses in one common object.
class ApiResponse<T> {
  // Whether the request succeeded.
  final bool success;

  // Optional message from the backend or app.
  final String? message;

  // Optional typed data returned by the request.
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  // Build an ApiResponse from JSON.
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
