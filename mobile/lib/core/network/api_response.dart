dynamic unwrapData(dynamic body) {
  if (body == null) return null;
  if (body is Map<String, dynamic>) {
    if (body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }
  if (body is Map) {
    final map = Map<String, dynamic>.from(body);
    if (map.containsKey('data')) {
      return map['data'];
    }
    return map;
  }
  return body;
}

String? unwrapErrorMessage(Map<String, dynamic>? body) {
  if (body == null) return null;
  final error = body['error'];
  if (error is Map && error['message'] is String) {
    return error['message'] as String;
  }
  return null;
}
