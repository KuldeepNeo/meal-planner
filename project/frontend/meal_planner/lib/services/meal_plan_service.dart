import '../core/network/dio_client.dart';

class MealPlanItem {
  final int id;
  final String mealDate;
  final String mealType;
  final int recipeId;
  final int servingCount;
  final String recipeName;

  MealPlanItem({
    required this.id,
    required this.mealDate,
    required this.mealType,
    required this.recipeId,
    required this.servingCount,
    required this.recipeName,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'] ?? 0,
      mealDate: json['mealDate'] ?? '',
      mealType: json['mealType'] ?? '',
      recipeId: json['recipeId'] ?? 0,
      servingCount: json['servingCount'] ?? 1,
      recipeName: json['recipeName'] ?? '',
    );
  }
}

class MealPlan {
  final int id;
  final String startDate;
  final String endDate;
  final List<MealPlanItem> items;

  MealPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.items = const [],
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] as List?;
    return MealPlan(
      id: json['id'] ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      items: itemList != null
          ? itemList.map((i) => MealPlanItem.fromJson(i)).toList()
          : [],
    );
  }
}

class MealPlanItemResult {
  final int id;
  final String? warning;

  MealPlanItemResult({required this.id, this.warning});
}

class MealPlanService {
  final DioClient _dioClient;

  MealPlanService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<MealPlan>> getMealPlans() async {
    try {
      final response = await _dioClient.dio.get('/api/meal-plans');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MealPlan.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<MealPlan?> getMealPlanDetails(int id) async {
    try {
      final response = await _dioClient.dio.get('/api/meal-plans/$id');
      if (response.statusCode == 200) {
        return MealPlan.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> createMealPlan({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/meal-plans',
        data: {'startDate': startDate, 'endDate': endDate},
      );
      if (response.statusCode == 201) {
        return response.data['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<MealPlanItemResult?> addMealPlanItem({
    required int mealPlanId,
    required String mealDate,
    required String mealType,
    required int recipeId,
    int? servingCount,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/meal-plans/$mealPlanId/items',
        data: {
          'mealDate': mealDate,
          'mealType': mealType,
          'recipeId': recipeId,
          if (servingCount != null) 'servingCount': servingCount,
        },
      );
      if (response.statusCode == 201) {
        return MealPlanItemResult(
          id: response.data['id'],
          warning: response.data['warning'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteMealPlan(int id) async {
    try {
      final response = await _dioClient.dio.delete('/api/meal-plans/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
