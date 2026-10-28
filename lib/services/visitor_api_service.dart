import 'package:dio/dio.dart';

import '../models/visitor.dart';

class VisitorApiService {
  VisitorApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://6ae18f6fbe3bc8fead98bcdf.mockapi.io',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final Dio _dio;

  // Get all visitors
  Future<List<Visitor>> getVisitors() async {
    final response = await _dio.get('/visitors');

    if (response.data is! List) {
      throw const FormatException('Invalid visitors response');
    }

    return (response.data as List)
        .map((item) => Visitor.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  // Get a visitor by ID
  Future<Visitor> getVisitor(String id) async {
    final response = await _dio.get('/visitors/$id');

    return Visitor.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // Register a visitor
  Future<Visitor> createVisitor(Visitor visitor) async {
    final response = await _dio.post('/visitors', data: visitor.toJson());

    return Visitor.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // Update visitor details or status
  Future<Visitor> updateVisitor(Visitor visitor) async {
    final response = await _dio.put(
      '/visitors/${visitor.id}',
      data: visitor.toJson(),
    );

    return Visitor.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // Delete a visitor
  Future<void> deleteVisitor(String id) async {
    await _dio.delete('/visitors/$id');
  }
}
