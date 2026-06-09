import '../core/network/dio_client.dart';

class AnalyticsModel {
  final double weeklyMealPlanCreationRate;
  final double groceryTrackingUsage;
  final double recipeCreationRate;
  final double groceryOrderConversionRate;
  final double userRetentionRate;
  final double averageMealPlansPerUserPerMonth;
  final double shoppingListGenerationRate;
  final double inventoryAccuracyRate;
  final double orderCompletionRate;
  final double foodWasteReduction;
  final double monthlyActiveUserGrowth;

  AnalyticsModel({
    required this.weeklyMealPlanCreationRate,
    required this.groceryTrackingUsage,
    required this.recipeCreationRate,
    required this.groceryOrderConversionRate,
    required this.userRetentionRate,
    required this.averageMealPlansPerUserPerMonth,
    required this.shoppingListGenerationRate,
    required this.inventoryAccuracyRate,
    required this.orderCompletionRate,
    required this.foodWasteReduction,
    required this.monthlyActiveUserGrowth,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      weeklyMealPlanCreationRate: (json['weeklyMealPlanCreationRate'] as num?)?.toDouble() ?? 0.0,
      groceryTrackingUsage: (json['groceryTrackingUsage'] as num?)?.toDouble() ?? 0.0,
      recipeCreationRate: (json['recipeCreationRate'] as num?)?.toDouble() ?? 0.0,
      groceryOrderConversionRate: (json['groceryOrderConversionRate'] as num?)?.toDouble() ?? 0.0,
      userRetentionRate: (json['userRetentionRate'] as num?)?.toDouble() ?? 0.0,
      averageMealPlansPerUserPerMonth: (json['averageMealPlansPerUserPerMonth'] as num?)?.toDouble() ?? 0.0,
      shoppingListGenerationRate: (json['shoppingListGenerationRate'] as num?)?.toDouble() ?? 0.0,
      inventoryAccuracyRate: (json['inventoryAccuracyRate'] as num?)?.toDouble() ?? 0.0,
      orderCompletionRate: (json['orderCompletionRate'] as num?)?.toDouble() ?? 0.0,
      foodWasteReduction: (json['foodWasteReduction'] as num?)?.toDouble() ?? 0.0,
      monthlyActiveUserGrowth: (json['monthlyActiveUserGrowth'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnalyticsService {
  final DioClient _dioClient;

  AnalyticsService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<AnalyticsModel?> getAnalytics() async {
    try {
      final response = await _dioClient.dio.get('/api/analytics');
      if (response.statusCode == 200) {
        return AnalyticsModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
