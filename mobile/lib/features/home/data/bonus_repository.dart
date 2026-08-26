import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

class BonusRepository {
  BonusRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;

  Future<int> fetchBalance() async {
    final summary = await fetchAccountSummary();
    return summary.balance.toInt();
  }

  Future<BonusAccountSummary> fetchAccountSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/bonus/balance');
    final data = unwrapDataMap(response.data);
    return BonusAccountSummary(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      totalEarned: (data['totalEarned'] as num?)?.toDouble() ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<BonusHistoryPage> fetchHistory({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/bonus/history',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final data = unwrapDataMap(response.data);
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => BonusTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return BonusHistoryPage(
      items: items,
      total: (data['total'] as num?)?.toInt() ?? items.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class BonusAccountSummary {
  const BonusAccountSummary({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
  });

  final double balance;
  final double totalEarned;
  final double totalSpent;
}

class BonusHistoryPage {
  const BonusHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<BonusTransaction> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class BonusTransaction {
  BonusTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.createdAt,
  });

  factory BonusTransaction.fromJson(Map<String, dynamic> json) {
    return BonusTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String type;
  final double amount;
  final String? description;
  final String? createdAt;
}
