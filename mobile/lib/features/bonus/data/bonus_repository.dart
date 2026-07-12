import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

class BonusRepository {
  BonusRepository({DioClient? dioClient}) : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;

  Future<int> fetchBalance() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/bonus/balance');
    final data = unwrapData(response.data);
    return (data['balance'] as num?)?.toInt() ?? 0;
  }

  Future<BonusHistoryPage> fetchHistory({required int page, int pageSize = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/bonus/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = unwrapData(response.data);
    final items = (data['items'] as List? ?? [])
        .map((e) => BonusTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BonusHistoryPage(
      items: items,
      total: (data['total'] as num?)?.toInt() ?? items.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
      hasMore: page < ((data['totalPages'] as num?)?.toInt() ?? page),
    );
  }
}

class BonusHistoryPage {
  BonusHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<BonusTransaction> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

class BonusTransaction {
  BonusTransaction({
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory BonusTransaction.fromJson(Map<String, dynamic> json) {
    return BonusTransaction(
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final String type;
  final double amount;
  final String? description;
  final String createdAt;
}
