import '../core/network/dio_client.dart';

class GroceryItem {
  final int id;
  final String itemName;
  final double quantity;
  final String unit;
  final String status;
  final String? expiryDate;

  GroceryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.status,
    this.expiryDate,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] ?? 0,
      itemName: json['itemName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      status: json['status'] ?? 'IN_STOCK',
      expiryDate: json['expiryDate'],
    );
  }
}

class GroceryService {
  final DioClient _dioClient;

  GroceryService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<GroceryItem>> getGroceries() async {
    try {
      final response = await _dioClient.dio.get('/api/groceries');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GroceryItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int?> addGrocery({
    required String itemName,
    required double quantity,
    required String unit,
    String? expiryDate,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/groceries',
        data: {
          'itemName': itemName,
          'quantity': quantity,
          'unit': unit,
          if (expiryDate != null) 'expiryDate': expiryDate,
        },
      );
      if (response.statusCode == 201) {
        return response.data['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateGrocery({required int id, required double quantity}) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/groceries/$id',
        data: {'quantity': quantity},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGrocery({required int id}) async {
    try {
      final response = await _dioClient.dio.delete('/api/groceries/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
