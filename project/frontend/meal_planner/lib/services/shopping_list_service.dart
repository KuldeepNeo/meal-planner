import '../core/network/dio_client.dart';

class ShoppingListItem {
  final int id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final bool isCustom;
  final bool isChecked; // Local state for checklist UI helper

  ShoppingListItem({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.isCustom,
    this.isChecked = false,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] ?? 0,
      ingredientName: json['ingredientName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      isCustom: json['isCustom'] ?? false,
    );
  }

  ShoppingListItem copyWith({bool? isChecked}) {
    return ShoppingListItem(
      id: id,
      ingredientName: ingredientName,
      quantity: quantity,
      unit: unit,
      isCustom: isCustom,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class ShoppingList {
  final int shoppingListId;
  final List<ShoppingListItem> items;

  ShoppingList({
    required this.shoppingListId,
    required this.items,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    return ShoppingList(
      shoppingListId: json['shoppingListId'] ?? 0,
      items: itemsList != null
          ? itemsList.map((i) => ShoppingListItem.fromJson(i)).toList()
          : [],
    );
  }
}

class ShoppingListService {
  final DioClient _dioClient;

  ShoppingListService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<ShoppingList?> getShoppingList() async {
    try {
      final response = await _dioClient.dio.get('/api/shopping-list');
      if (response.statusCode == 200) {
        return ShoppingList.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> addCustomItem({
    required String itemName,
    required double quantity,
    required String unit,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/shopping-list/custom-item',
        data: {
          'itemName': itemName,
          'quantity': quantity,
          'unit': unit,
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

  Future<bool> updateItemQuantity({required int id, required double quantity}) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/shopping-list/items/$id',
        data: {'quantity': quantity},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final response = await _dioClient.dio.delete('/api/shopping-list/items/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
