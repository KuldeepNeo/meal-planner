import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/grocery_service.dart';

abstract class InventoryEvent {}
class LoadInventory extends InventoryEvent {}
class AddInventoryItem extends InventoryEvent {
  final String itemName;
  final double quantity;
  final String unit;
  final String? expiryDate;
  AddInventoryItem({required this.itemName, required this.quantity, required this.unit, this.expiryDate});
}
class UpdateInventoryItemQty extends InventoryEvent {
  final int id;
  final double quantity;
  UpdateInventoryItemQty({required this.id, required this.quantity});
}
class DeleteInventoryItem extends InventoryEvent {
  final int id;
  DeleteInventoryItem({required this.id});
}

abstract class InventoryState {}
class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<GroceryItem> items;
  InventoryLoaded(this.items);
}
class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}
class InventoryActionSuccess extends InventoryState {
  final String message;
  InventoryActionSuccess(this.message);
}

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GroceryService _groceryService;

  InventoryBloc({GroceryService? groceryService})
      : _groceryService = groceryService ?? GroceryService(),
        super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());
      final items = await _groceryService.getGroceries();
      emit(InventoryLoaded(items));
    });

    on<AddInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      final id = await _groceryService.addGrocery(
        itemName: event.itemName,
        quantity: event.quantity,
        unit: event.unit,
        expiryDate: event.expiryDate,
      );
      if (id != null) {
        final items = await _groceryService.getGroceries();
        emit(InventoryActionSuccess('Item added successfully'));
        emit(InventoryLoaded(items));
      } else {
        emit(InventoryError('Failed to add item'));
      }
    });

    on<UpdateInventoryItemQty>((event, emit) async {
      emit(InventoryLoading());
      final success = await _groceryService.updateGrocery(id: event.id, quantity: event.quantity);
      if (success) {
        final items = await _groceryService.getGroceries();
        emit(InventoryActionSuccess('Quantity updated successfully'));
        emit(InventoryLoaded(items));
      } else {
        emit(InventoryError('Failed to update quantity'));
      }
    });

    on<DeleteInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      final success = await _groceryService.deleteGrocery(id: event.id);
      if (success) {
        final items = await _groceryService.getGroceries();
        emit(InventoryActionSuccess('Item deleted successfully'));
        emit(InventoryLoaded(items));
      } else {
        emit(InventoryError('Failed to delete item'));
      }
    });
  }
}
