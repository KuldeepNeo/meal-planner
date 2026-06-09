import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/shopping_list_service.dart';
import '../../../services/order_service.dart';

abstract class ShoppingListEvent {}
class LoadShoppingListEvent extends ShoppingListEvent {}
class AddCustomItemEvent extends ShoppingListEvent {
  final String itemName;
  final double quantity;
  final String unit;
  AddCustomItemEvent({required this.itemName, required this.quantity, required this.unit});
}
class UpdateItemQtyEvent extends ShoppingListEvent {
  final int id;
  final double quantity;
  UpdateItemQtyEvent({required this.id, required this.quantity});
}
class DeleteItemEvent extends ShoppingListEvent {
  final int id;
  DeleteItemEvent({required this.id});
}
class ToggleItemCheckedEvent extends ShoppingListEvent {
  final int id;
  ToggleItemCheckedEvent({required this.id});
}
class CheckoutShoppingListEvent extends ShoppingListEvent {
  final int shoppingListId;
  final String address;
  final String paymentMethod;
  CheckoutShoppingListEvent({
    required this.shoppingListId,
    required this.address,
    required this.paymentMethod,
  });
}

abstract class ShoppingListState {}
class ShoppingListInitial extends ShoppingListState {}
class ShoppingListLoading extends ShoppingListState {}
class ShoppingListLoaded extends ShoppingListState {
  final ShoppingList list;
  ShoppingListLoaded(this.list);
}
class ShoppingListError extends ShoppingListState {
  final String message;
  ShoppingListError(this.message);
}
class OrderCheckoutSuccess extends ShoppingListState {
  final int orderId;
  final String status;
  OrderCheckoutSuccess({required this.orderId, required this.status});
}

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListService _shoppingListService;
  final OrderService _orderService;

  ShoppingListBloc({ShoppingListService? shoppingListService, OrderService? orderService})
      : _shoppingListService = shoppingListService ?? ShoppingListService(),
        _orderService = orderService ?? OrderService(),
        super(ShoppingListInitial()) {
    on<LoadShoppingListEvent>((event, emit) async {
      emit(ShoppingListLoading());
      final list = await _shoppingListService.getShoppingList();
      if (list != null) {
        emit(ShoppingListLoaded(list));
      } else {
        emit(ShoppingListError('Failed to load shopping list'));
      }
    });

    on<AddCustomItemEvent>((event, emit) async {
      final currentState = state;
      if (currentState is ShoppingListLoaded) {
        emit(ShoppingListLoading());
        final id = await _shoppingListService.addCustomItem(
          itemName: event.itemName,
          quantity: event.quantity,
          unit: event.unit,
        );
        if (id != null) {
          final list = await _shoppingListService.getShoppingList();
          if (list != null) {
            emit(ShoppingListLoaded(list));
          } else {
            emit(ShoppingListLoaded(currentState.list));
          }
        } else {
          emit(ShoppingListError('Failed to add custom item'));
          emit(ShoppingListLoaded(currentState.list));
        }
      }
    });

    on<UpdateItemQtyEvent>((event, emit) async {
      final currentState = state;
      if (currentState is ShoppingListLoaded) {
        emit(ShoppingListLoading());
        final success = await _shoppingListService.updateItemQuantity(id: event.id, quantity: event.quantity);
        if (success) {
          final list = await _shoppingListService.getShoppingList();
          if (list != null) {
            emit(ShoppingListLoaded(list));
          } else {
            emit(ShoppingListLoaded(currentState.list));
          }
        } else {
          emit(ShoppingListError('Failed to update quantity'));
          emit(ShoppingListLoaded(currentState.list));
        }
      }
    });

    on<DeleteItemEvent>((event, emit) async {
      final currentState = state;
      if (currentState is ShoppingListLoaded) {
        emit(ShoppingListLoading());
        final success = await _shoppingListService.deleteItem(event.id);
        if (success) {
          final list = await _shoppingListService.getShoppingList();
          if (list != null) {
            emit(ShoppingListLoaded(list));
          } else {
            emit(ShoppingListLoaded(currentState.list));
          }
        } else {
          emit(ShoppingListError('Failed to delete item'));
          emit(ShoppingListLoaded(currentState.list));
        }
      }
    });

    on<ToggleItemCheckedEvent>((event, emit) {
      final currentState = state;
      if (currentState is ShoppingListLoaded) {
        final updatedItems = currentState.list.items.map((item) {
          if (item.id == event.id) {
            return item.copyWith(isChecked: !item.isChecked);
          }
          return item;
        }).toList();
        emit(ShoppingListLoaded(ShoppingList(
          shoppingListId: currentState.list.shoppingListId,
          items: updatedItems,
        )));
      }
    });

    on<CheckoutShoppingListEvent>((event, emit) async {
      final currentState = state;
      if (currentState is ShoppingListLoaded) {
        emit(ShoppingListLoading());
        // First add item ids to cart (using checked items, or all items if none are checked)
        final idsToCart = currentState.list.items
            .where((item) => item.isChecked)
            .map((item) => item.id)
            .toList();
            
        final finalIds = idsToCart.isEmpty 
            ? currentState.list.items.map((item) => item.id).toList()
            : idsToCart;

        if (finalIds.isEmpty) {
          emit(ShoppingListError('Cart is empty. Nothing to checkout.'));
          emit(ShoppingListLoaded(currentState.list));
          return;
        }

        final cartId = await _orderService.addToCart(finalIds);
        if (cartId == null) {
          emit(ShoppingListError('Failed to add items to cart'));
          emit(ShoppingListLoaded(currentState.list));
          return;
        }

        final result = await _orderService.placeOrder(
          shoppingListId: event.shoppingListId,
          deliveryAddress: event.address,
          paymentMethod: event.paymentMethod,
        );

        if (result != null) {
          emit(OrderCheckoutSuccess(
            orderId: result['orderId'],
            status: result['status'],
          ));
        } else {
          emit(ShoppingListError('Failed to place order'));
          emit(ShoppingListLoaded(currentState.list));
        }
      }
    });
  }
}
