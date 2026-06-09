import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../../../core/theme/theme.dart';
import '../../../services/grocery_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(LoadInventory());
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // Determine category based on itemName
  String _getItemCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('apple') ||
        lowerName.contains('tomato') ||
        lowerName.contains('spinach') ||
        lowerName.contains('lettuce') ||
        lowerName.contains('avocado') ||
        lowerName.contains('onion')) {
      return 'Produce';
    }
    if (lowerName.contains('milk') ||
        lowerName.contains('yogurt') ||
        lowerName.contains('egg') ||
        lowerName.contains('cheese') ||
        lowerName.contains('butter')) {
      return 'Dairy';
    }
    if (lowerName.contains('chicken') ||
        lowerName.contains('beef') ||
        lowerName.contains('pork') ||
        lowerName.contains('salmon') ||
        lowerName.contains('fish') ||
        lowerName.contains('tofu')) {
      return 'Protein';
    }
    return 'Pantry';
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Produce':
        return 'https://images.unsplash.com/photo-1610348725531-843dff1444d1?q=80&w=200&auto=format&fit=crop';
      case 'Dairy':
        return 'https://images.unsplash.com/photo-1550583724-b2692b85b150?q=80&w=200&auto=format&fit=crop';
      case 'Protein':
        return 'https://images.unsplash.com/photo-1546964124-0cce460f38ef?q=80&w=200&auto=format&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=200&auto=format&fit=crop';
    }
  }

  void _showAddGroceryDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: 'pcs');
    final expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grocery Item'),
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
            const SizedBox(height: 12),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
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
              final expiry = expiryController.text.trim();
              if (name.isNotEmpty) {
                context.read<InventoryBloc>().add(
                  AddInventoryItem(
                    itemName: name,
                    quantity: qty,
                    unit: unit,
                    expiryDate: expiry.isNotEmpty ? expiry : null,
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

  void _showEditGroceryDialog(GroceryItem item) {
    final qtyController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${item.itemName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Unit: ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'New Quantity'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final qty = double.tryParse(qtyController.text) ?? item.quantity;
              context.read<InventoryBloc>().add(
                UpdateInventoryItemQty(
                  id: item.id,
                  quantity: qty,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
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
                  'Zest',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    letterSpacing: -1,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primaryColor),
                    onPressed: () {},
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              // Search bar and Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Search Input
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                          hintText: 'Search your pantry...',
                          fillColor: AppColors.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Chips
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('Produce'),
                            _buildFilterChip('Dairy'),
                            _buildFilterChip('Protein'),
                            _buildFilterChip('Pantry'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Inventory items section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                sliver: BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    if (state is InventoryLoading) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                      );
                    } else if (state is InventoryLoaded) {
                      final items = state.items.where((item) {
                        final matchesSearch = item.itemName.toLowerCase().contains(_searchQuery);
                        final itemCat = _getItemCategory(item.itemName);
                        final matchesCategory = _selectedCategory == 'All' || itemCat == _selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();

                      if (items.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No items in your inventory.',
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final itemCat = _getItemCategory(item.itemName);
                            final iconUrl = _getCategoryIcon(itemCat);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Dismissible(
                                key: Key('inv_${item.id}'),
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  color: Colors.green,
                                  child: const Icon(Icons.edit, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    // Edit
                                    _showEditGroceryDialog(item);
                                    return false; // don't dismiss card
                                  } else {
                                    // Delete
                                    context.read<InventoryBloc>().add(DeleteInventoryItem(id: item.id));
                                    return true; // do dismiss
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          iconUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  item.itemName,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface,
                                                  ),
                                                ),
                                                _buildStatusBadge(item.status),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.quantity} ${item.unit}${item.expiryDate != null ? ' • Exp. ${item.expiryDate}' : ''}',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                color: AppColors.tertiary,
                                              ),
                                            ),
                                            if (item.status == 'EXPIRING_SOON') ...[
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(100),
                                                child: const LinearProgressIndicator(
                                                  value: 0.15,
                                                  color: AppColors.error,
                                                  backgroundColor: AppColors.surfaceContainerHighest,
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      );
                    } else {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Failed to load inventory.',
                            style: TextStyle(fontFamily: 'Inter', color: AppColors.error),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showAddGroceryDialog,
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Text(
          category,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'IN_STOCK':
        bgColor = AppColors.primaryContainer.withOpacity(0.2);
        textColor = AppColors.primaryColor;
        text = 'In Stock';
        break;
      case 'LOW_STOCK':
        bgColor = AppColors.secondaryContainer.withOpacity(0.2);
        textColor = AppColors.secondary;
        text = 'Low Stock';
        break;
      case 'EXPIRING_SOON':
      case 'EXPIRING':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.error;
        text = 'Expiring';
        break;
      default:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.error;
        text = 'Out of Stock';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
