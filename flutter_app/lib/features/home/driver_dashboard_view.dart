import 'package:flutter/material.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/info_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/empty_state_widget.dart';

class DriverDashboardView extends StatelessWidget {
  final String driverName;
  final String profileImageUrl;
  final double monthlyEarnings;
  final Map<String, dynamic>? currentTrip;
  final List<dynamic> upcomingTrips;
  final VoidCallback onStartTrip;
  final VoidCallback onEndTrip;
  final Function(dynamic) onTripTap;

  const DriverDashboardView({
    super.key,
    required this.driverName,
    this.profileImageUrl = '',
    required this.monthlyEarnings,
    this.currentTrip,
    required this.upcomingTrips,
    required this.onStartTrip,
    required this.onEndTrip,
    required this.onTripTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(theme),
            const SizedBox(height: 32),
            _buildMainActions(theme),
            const SizedBox(height: 32),
            _buildTodayTrip(theme),
            const SizedBox(height: 24),
            _buildEarnings(theme),
            const SizedBox(height: 24),
            _buildUpcomingTrips(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
            child: profileImageUrl.isEmpty 
                ? Icon(Icons.person, size: 36, color: theme.colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                driverName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(ThemeData theme) {
    final isTripActive = currentTrip != null && currentTrip!['status'] == 'in_progress';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          PrimaryButton(
            text: 'START TRIP',
            icon: Icons.play_arrow_rounded,
            height: 64,
            backgroundColor: isTripActive ? Colors.grey : Colors.green.shade600,
            onPressed: isTripActive ? null : onStartTrip,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'END TRIP',
            icon: Icons.stop_rounded,
            height: 64,
            backgroundColor: !isTripActive ? Colors.grey : Colors.orange.shade600,
            onPressed: !isTripActive ? null : onEndTrip,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTrip(ThemeData theme) {
    if (currentTrip == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: EmptyStateWidget(
          icon: Icons.directions_car_outlined,
          title: 'No Active Trip',
          subtitle: 'You are currently not on any active trip.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Current Trip',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          elevation: theme.brightness == Brightness.dark ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '#${currentTrip!['id'].toString().substring(0, 8)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(status: currentTrip!['status']),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.my_location, size: 20, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentTrip!['pickup'] ?? 'Unknown Pickup',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
                  child: Container(
                    height: 24,
                    width: 2,
                    color: theme.dividerColor,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentTrip!['drop'] ?? 'Unknown Drop',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_car_filled, size: 20, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentTrip!['vehicle'] ?? 'Assigned Vehicle',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarnings(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Earnings Overview',
              style: theme.textTheme.titleMedium,
            ),
          ),
          DashboardCard(
            title: 'Available Earnings',
            value: '₹${monthlyEarnings.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
            colorAccent: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTrips(ThemeData theme) {
    if (upcomingTrips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Upcoming Trips',
            style: theme.textTheme.titleMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcomingTrips.length,
          itemBuilder: (context, index) {
            final trip = upcomingTrips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InfoTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                ),
                title: trip.pickupLocation ?? 'Unknown',
                subtitle: trip.pickupDateTime?.toString().split(' ')[0] ?? 'Unknown Date',
                trailing: StatusChip(status: trip.status ?? 'scheduled'),
                onTap: () => onTripTap(trip),
              ),
            );
          },
        ),
      ],
    );
  }
}
