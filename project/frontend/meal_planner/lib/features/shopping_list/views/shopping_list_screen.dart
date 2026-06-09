import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/shopping_list_bloc.dart';
import '../../../core/theme/theme.dart';
import '../../../services/shopping_list_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShoppingListBloc>().add(LoadShoppingListEvent());
  }

  String _getItemCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('apple') ||
        lowerName.contains('tomato') ||
        lowerName.contains('spinach') ||
        lowerName.contains('lettuce') ||
        lowerName.contains('avocado') ||
        lowerName.contains('onion') ||
        lowerName.contains('basil')) {
      return 'Produce';
    }
    if (lowerName.contains('milk') ||
        lowerName.contains('yogurt') ||
        lowerName.contains('egg') ||
        lowerName.contains('cheese') ||
        lowerName.contains('butter')) {
      return 'Dairy & Eggs';
    }
    if (lowerName.contains('chicken') ||
        lowerName.contains('beef') ||
        lowerName.contains('pork') ||
        lowerName.contains('salmon') ||
        lowerName.contains('fish') ||
        lowerName.contains('tofu') ||
        lowerName.contains('shrimp')) {
      return 'Protein';
    }
    return 'Pantry';
  }

  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: 'pcs');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = double.tryParse(qtyController.text) ?? 1.0;
              final unit = unitController.text.trim();
              if (name.isNotEmpty) {
                context.read<ShoppingListBloc>().add(
                  AddCustomItemEvent(
                    itemName: name,
                    quantity: qty,
                    unit: unit,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShoppingListBloc, ShoppingListState>(
      listener: (context, state) {
        if (state is OrderCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order successfully placed! Status: ${state.status}'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
          // Redirect to Order Tracking screen
          context.push('/tracking/${state.orderId}');
        } else if (state is ShoppingListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Navigation Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: 70,
                  backgroundColor: AppColors.surface.withOpacity(0.85),
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.primaryColor),
                    onPressed: () {},
                  ),
                  title: const Text(
                    'Shopping List',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: AppColors.primaryColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppColors.primaryColor),
                      onPressed: () {},
                    ),
                  ],
                ),

                // Main Shopping checklist
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 240.0),
                  sliver: BlocBuilder<ShoppingListBloc, ShoppingListState>(
                    builder: (context, state) {
                      if (state is ShoppingListLoading) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                        );
                      } else if (state is ShoppingListLoaded) {
                        final list = state.list;
                        if (list.items.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Your shopping list is empty.',
                                style: TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                              ),
                            ),
                          );
                        }

                        // Group items by category
                        final Map<String, List<ShoppingListItem>> grouped = {};
                        for (final item in list.items) {
                          final cat = _getItemCategory(item.ingredientName);
                          grouped.putIfAbsent(cat, () => []).add(item);
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = grouped.keys.elementAt(index);
                              final catItems = grouped[cat]!;
                              return _buildCategorySection(cat, catItems);
                            },
                            childCount: grouped.keys.length,
                          ),
                        );
                      } else {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('Failed to load shopping list.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // Sticky Bottom Footer Summary Card
            BlocBuilder<ShoppingListBloc, ShoppingListState>(
              builder: (context, state) {
                if (state is ShoppingListLoaded) {
                  final list = state.list;
                  final totalCount = list.items.length;
                  final checkedCount = list.items.where((i) => i.isChecked).length;
                  final uncheckedCount = totalCount - checkedCount;

                  return Positioned(
                    left: 20,
                    right: 20,
                    bottom: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
                        boxShadow: AppTheme.fabShadow,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Selection',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.tertiary,
                                    ),
                                  ),
                                  Text(
                                    '$uncheckedCount Items Remaining',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share, color: AppColors.tertiary),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
                                    onPressed: _showAddCustomItemDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ShoppingListBloc>().add(
                                    CheckoutShoppingListEvent(
                                      shoppingListId: list.shoppingListId,
                                      address: 'Mumbai',
                                      paymentMethod: 'CARD',
                                    ),
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart),
                                SizedBox(width: 8),
                                Text(
                                  'Order Groceries',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<ShoppingListItem> items) {
    IconData catIcon;
    switch (category) {
      case 'Produce':
        catIcon = Icons.eco;
        break;
      case 'Dairy & Eggs':
        catIcon = Icons.egg_alt;
        break;
      case 'Protein':
        catIcon = Icons.restaurant;
        break;
      default:
        catIcon = Icons.kitchen;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(catIcon, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${items.length} items',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.map((item) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x1AE2E8F0), width: 0.5)),
                ),
                child: CheckboxListTile(
                  value: item.isChecked,
                  onChanged: (val) {
                    context.read<ShoppingListBloc>().add(ToggleItemCheckedEvent(id: item.id));
                  },
                  activeColor: AppColors.primaryColor,
                  checkboxShape: const CircleBorder(),
                  title: Text(
                    item.ingredientName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: item.isChecked ? AppColors.tertiary : AppColors.onSurface,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${item.quantity} ${item.unit}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
