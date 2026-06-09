import '../core/network/dio_client.dart';

class OrderItemModel {
  final int id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final double price;

  OrderItemModel({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      ingredientName: json['ingredientName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String paymentMethod;
  final String estimatedDelivery;
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.estimatedDelivery,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'CARD',
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      createdAt: json['createdAt'] ?? '',
      items: itemsList != null
          ? itemsList.map((i) => OrderItemModel.fromJson(i)).toList()
          : [],
    );
  }
}

class OrderTrackingEvent {
  final String status;
  final String time;
  final String notes;

  OrderTrackingEvent({
    required this.status,
    required this.time,
    required this.notes,
  });

  factory OrderTrackingEvent.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEvent(
      status: json['status'] ?? '',
      time: json['time'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class OrderTracking {
  final int orderId;
  final String status;
  final String estimatedDelivery;
  final List<OrderTrackingEvent> events;

  OrderTracking({
    required this.orderId,
    required this.status,
    required this.estimatedDelivery,
    required this.events,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    var eventsList = json['events'] as List?;
    return OrderTracking(
      orderId: json['orderId'] ?? 0,
      status: json['status'] ?? '',
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      events: eventsList != null
          ? eventsList.map((i) => OrderTrackingEvent.fromJson(i)).toList()
          : [],
    );
  }
}

class OrderService {
  final DioClient _dioClient;

  OrderService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<int?> addToCart(List<int> shoppingListItemIds) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/orders/cart',
        data: {'shoppingListItemIds': shoppingListItemIds},
      );
      if (response.statusCode == 200) {
        return response.data['cartId'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> placeOrder({
    required int shoppingListId,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/orders',
        data: {
          'shoppingListId': shoppingListId,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
        },
      );
      if (response.statusCode == 201) {
        return response.data; // contains orderId and status
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await _dioClient.dio.get('/api/orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<OrderModel?> getOrderDetails(int id) async {
    try {
      final response = await _dioClient.dio.get('/api/orders/$id');
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OrderTracking?> getOrderTracking(int id) async {
    try {
      final response = await _dioClient.dio.get('/api/orders/$id/tracking');
      if (response.statusCode == 200) {
        return OrderTracking.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/orders/$id/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
