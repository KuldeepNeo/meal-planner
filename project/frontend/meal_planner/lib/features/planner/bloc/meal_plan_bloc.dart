import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/meal_plan_service.dart';

abstract class MealPlanEvent {}
class LoadMealPlans extends MealPlanEvent {}
class CreateMealPlanEvent extends MealPlanEvent {
  final String startDate;
  final String endDate;
  CreateMealPlanEvent({required this.startDate, required this.endDate});
}
class AddMealPlanItemEvent extends MealPlanEvent {
  final int mealPlanId;
  final String mealDate;
  final String mealType;
  final int recipeId;
  final int? servingCount;
  AddMealPlanItemEvent({
    required this.mealPlanId,
    required this.mealDate,
    required this.mealType,
    required this.recipeId,
    this.servingCount,
  });
}
class DeleteMealPlanEvent extends MealPlanEvent {
  final int id;
  DeleteMealPlanEvent({required this.id});
}

abstract class MealPlanState {}
class MealPlanInitial extends MealPlanState {}
class MealPlanLoading extends MealPlanState {}
class MealPlansLoaded extends MealPlanState {
  final List<MealPlan> plans;
  final MealPlan? activePlan;
  final String? warningMessage;
  MealPlansLoaded({required this.plans, this.activePlan, this.warningMessage});
}
class MealPlanError extends MealPlanState {
  final String message;
  MealPlanError(this.message);
}

class MealPlanBloc extends Bloc<MealPlanEvent, MealPlanState> {
  final MealPlanService _mealPlanService;

  MealPlanBloc({MealPlanService? mealPlanService})
      : _mealPlanService = mealPlanService ?? MealPlanService(),
        super(MealPlanInitial()) {
    on<LoadMealPlans>((event, emit) async {
      emit(MealPlanLoading());
      final plans = await _mealPlanService.getMealPlans();
      MealPlan? activePlan;
      if (plans.isNotEmpty) {
        // Fetch details of the latest plan
        activePlan = await _mealPlanService.getMealPlanDetails(plans.first.id);
      }
      emit(MealPlansLoaded(plans: plans, activePlan: activePlan));
    });

    on<CreateMealPlanEvent>((event, emit) async {
      emit(MealPlanLoading());
      final id = await _mealPlanService.createMealPlan(startDate: event.startDate, endDate: event.endDate);
      if (id != null) {
        final plans = await _mealPlanService.getMealPlans();
        final activePlan = await _mealPlanService.getMealPlanDetails(id);
        emit(MealPlansLoaded(plans: plans, activePlan: activePlan));
      } else {
        emit(MealPlanError('Failed to create meal plan'));
      }
    });

    on<AddMealPlanItemEvent>((event, emit) async {
      final currentState = state;
      List<MealPlan> plans = [];
      MealPlan? activePlan;
      if (currentState is MealPlansLoaded) {
        plans = currentState.plans;
        activePlan = currentState.activePlan;
      }
      
      emit(MealPlanLoading());
      final result = await _mealPlanService.addMealPlanItem(
        mealPlanId: event.mealPlanId,
        mealDate: event.mealDate,
        mealType: event.mealType,
        recipeId: event.recipeId,
        servingCount: event.servingCount,
      );

      if (result != null) {
        final updatedPlan = await _mealPlanService.getMealPlanDetails(event.mealPlanId);
        emit(MealPlansLoaded(
          plans: plans,
          activePlan: updatedPlan,
          warningMessage: result.warning,
        ));
      } else {
        emit(MealPlanError('Failed to add meal item'));
        emit(MealPlansLoaded(plans: plans, activePlan: activePlan));
      }
    });

    on<DeleteMealPlanEvent>((event, emit) async {
      emit(MealPlanLoading());
      final success = await _mealPlanService.deleteMealPlan(event.id);
      if (success) {
        final plans = await _mealPlanService.getMealPlans();
        MealPlan? activePlan;
        if (plans.isNotEmpty) {
          activePlan = await _mealPlanService.getMealPlanDetails(plans.first.id);
        }
        emit(MealPlansLoaded(plans: plans, activePlan: activePlan));
      } else {
        emit(MealPlanError('Failed to delete meal plan'));
      }
    });
  }
}
