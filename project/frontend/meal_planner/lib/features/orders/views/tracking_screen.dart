import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_bloc.dart';
import '../../../core/theme/theme.dart';
import '../../../services/order_service.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(LoadOrderTrackingEvent(id: widget.orderId));
  }

  void _simulateNextStatus(String currentStatus) {
    String nextStatus;
    switch (currentStatus) {
      case 'PENDING':
        nextStatus = 'CONFIRMED';
        break;
      case 'CONFIRMED':
        nextStatus = 'PACKED';
        break;
      case 'PACKED':
        nextStatus = 'OUT_FOR_DELIVERY';
        break;
      case 'OUT_FOR_DELIVERY':
        nextStatus = 'DELIVERED';
        break;
      default:
        return;
    }
    context.read<OrderBloc>().add(
          SimulateOrderDeliveryEvent(id: widget.orderId, nextStatus: nextStatus),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
          } else if (state is OrderTrackingLoaded) {
            final tracking = state.tracking;
            final status = tracking.status;

            return Column(
              children: [
                // Top App Bar
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
                          onPressed: () => context.go('/'),
                        ),
                        const Text(
                          'Zest',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            letterSpacing: -1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.help, color: AppColors.tertiary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content Scrollable
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 40.0),
                    children: [
                      // Delivery Status Hero
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ESTIMATED ARRIVAL',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '12:45 PM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.directions_bike, color: AppColors.primaryColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Order #ZEST-${widget.orderId} is $status',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Map view placeholder
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                          boxShadow: AppTheme.cardShadow,
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Timeline
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          'Order Progress',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(status),
                      const SizedBox(height: 24),

                      // Driver Info
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=100&auto=format&fit=crop',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Marco • Zest Partner',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.orange, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            '4.9 (2k+ deliveries)',
                                            style: TextStyle(fontSize: 11, color: AppColors.tertiary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.call, size: 18),
                                    label: const Text('Contact Driver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.help_outline, size: 18),
                                    label: const Text('Get Help'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Simulator Control
                      if (status != 'DELIVERED')
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _simulateNextStatus(status),
                            icon: const Icon(Icons.flash_on, color: AppColors.secondary),
                            label: const Text('Simulate Next Status'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              backgroundColor: AppColors.secondaryContainer.withOpacity(0.1),
                              side: const BorderSide(color: AppColors.secondaryContainer, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Failed to load tracking information.'));
          }
        },
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = ['PENDING', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    final labels = ['Pending', 'Confirmed', 'Packed', 'Out for Delivery', 'Delivered'];
    
    final currentIdx = statuses.indexOf(currentStatus);

    return Column(
      children: List.generate(statuses.length, (idx) {
        final stepStatus = statuses[idx];
        final stepLabel = labels[idx];
        
        final isCompleted = idx < currentIdx;
        final isActive = idx == currentIdx;
        final isFuture = idx > currentIdx;

        Color dotColor;
        if (isCompleted || isActive) {
          dotColor = AppColors.primaryColor;
        } else {
          dotColor = AppColors.outlineVariant;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: isActive 
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.4),
                                  spreadRadius: 4,
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                    if (idx < statuses.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? AppColors.primaryColor : AppColors.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: (isActive || isCompleted) ? FontWeight.w700 : FontWeight.w500,
                          color: isActive 
                              ? AppColors.primaryColor 
                              : isCompleted 
                                  ? AppColors.onSurface 
                                  : AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive 
                            ? 'Active State' 
                            : isCompleted 
                                ? 'Completed' 
                                : 'Expected soon',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
