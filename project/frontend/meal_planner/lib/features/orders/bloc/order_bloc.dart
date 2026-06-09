import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/order_service.dart';

abstract class OrderEvent {}
class LoadOrdersEvent extends OrderEvent {}
class LoadOrderDetailsEvent extends OrderEvent {
  final int id;
  LoadOrderDetailsEvent({required this.id});
}
class LoadOrderTrackingEvent extends OrderEvent {
  final int id;
  LoadOrderTrackingEvent({required this.id});
}
class SimulateOrderDeliveryEvent extends OrderEvent {
  final int id;
  final String nextStatus;
  SimulateOrderDeliveryEvent({required this.id, required this.nextStatus});
}

abstract class OrderState {}
class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrdersLoaded extends OrderState {
  final List<OrderModel> orders;
  OrdersLoaded(this.orders);
}
class OrderDetailsLoaded extends OrderState {
  final OrderModel order;
  OrderDetailsLoaded(this.order);
}
class OrderTrackingLoaded extends OrderState {
  final OrderTracking tracking;
  OrderTrackingLoaded(this.tracking);
}
class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}
class OrderStatusUpdated extends OrderState {
  final int id;
  final String newStatus;
  OrderStatusUpdated({required this.id, required this.newStatus});
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;

  OrderBloc({OrderService? orderService})
      : _orderService = orderService ?? OrderService(),
        super(OrderInitial()) {
    on<LoadOrdersEvent>((event, emit) async {
      emit(OrderLoading());
      final orders = await _orderService.getOrders();
      emit(OrdersLoaded(orders));
    });

    on<LoadOrderDetailsEvent>((event, emit) async {
      emit(OrderLoading());
      final order = await _orderService.getOrderDetails(event.id);
      if (order != null) {
        emit(OrderDetailsLoaded(order));
      } else {
        emit(OrderError('Failed to load order details'));
      }
    });

    on<LoadOrderTrackingEvent>((event, emit) async {
      emit(OrderLoading());
      final tracking = await _orderService.getOrderTracking(event.id);
      if (tracking != null) {
        emit(OrderTrackingLoaded(tracking));
      } else {
        emit(OrderError('Failed to load tracking details'));
      }
    });

    on<SimulateOrderDeliveryEvent>((event, emit) async {
      emit(OrderLoading());
      final success = await _orderService.updateOrderStatus(event.id, event.nextStatus);
      if (success) {
        final tracking = await _orderService.getOrderTracking(event.id);
        if (tracking != null) {
          emit(OrderStatusUpdated(id: event.id, newStatus: event.nextStatus));
          emit(OrderTrackingLoaded(tracking));
        } else {
          emit(OrderError('Status updated but failed to reload tracking'));
        }
      } else {
        emit(OrderError('Failed to update order status'));
      }
    });
  }
}
