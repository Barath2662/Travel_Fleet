import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/bill.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../models/app_user.dart';
import 'auth_provider.dart';

class AppState {
  final bool loading;
  final String? error;
  final List<TripModel> trips;
  final List<BillModel> bills;
  final List<VehicleModel> vehicles;
  final Map<String, double> vehicleBataRates;
  final List<DriverModel> drivers;
  final List<PaymentModel> payments;
  final List<AppNotification> notifications;
  final List<AppUser> users;

  const AppState({
    this.loading = false,
    this.error,
    this.trips = const [],
    this.bills = const [],
    this.vehicles = const [],
    this.vehicleBataRates = const {},
    this.drivers = const [],
    this.payments = const [],
    this.notifications = const [],
    this.users = const [],
  });

  AppState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<TripModel>? trips,
    List<BillModel>? bills,
    List<VehicleModel>? vehicles,
    Map<String, double>? vehicleBataRates,
    List<DriverModel>? drivers,
    List<PaymentModel>? payments,
    List<AppNotification>? notifications,
    List<AppUser>? users,
  }) {
    return AppState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      trips: trips ?? this.trips,
      bills: bills ?? this.bills,
      vehicles: vehicles ?? this.vehicles,
      vehicleBataRates: vehicleBataRates ?? this.vehicleBataRates,
      drivers: drivers ?? this.drivers,
      payments: payments ?? this.payments,
      notifications: notifications ?? this.notifications,
      users: users ?? this.users,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this.ref) : super(const AppState());

  final Ref ref;

  String _toMessage(Object error) => error.toString().replaceFirst('Exception: ', '').trim();

  String get token => ref.read(authProvider).token ?? '';

  Future<void> fetchTrips() async {
    await _fetchList('/trips', onData: (items) {
      state = state.copyWith(trips: items.map((e) => TripModel.fromJson(e)).toList());
    });
  }

  Future<void> fetchBills() async {
    await _fetchList('/bills', onData: (items) {
      state = state.copyWith(bills: items.map((e) => BillModel.fromJson(e)).toList());
    });
  }

  Future<void> fetchVehicles() async {
    await _fetchList('/vehicles', onData: (items) {
      state = state.copyWith(vehicles: items.map((e) => VehicleModel.fromJson(e)).toList());
    });
  }

  Future<void> fetchVehicleBataRates() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.get('/vehicle-bata-rates', token: token) as List<dynamic>;
      final map = <String, double>{};
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final category = item['category']?.toString();
          final amount = (item['amount'] as num?)?.toDouble();
          if (category != null && amount != null) {
            map[category] = amount;
          }
        }
      }
      state = state.copyWith(loading: false, vehicleBataRates: map);
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
    }
  }

  Future<void> setVehicleBataRate({required String category, required double amount}) async {
    await _put('/vehicle-bata-rates/$category', {'amount': amount});
    await fetchVehicleBataRates();
  }

  Future<void> fetchDrivers() async {
    await _fetchList('/drivers', onData: (items) {
      state = state.copyWith(drivers: items.map((e) => DriverModel.fromJson(e)).toList());
    });
  }

  Future<void> fetchPayments() async {
    await _fetchList('/payments', onData: (items) {
      state = state.copyWith(payments: items.map((e) => PaymentModel.fromJson(e)).toList());
    });
  }

  Future<void> fetchNotifications() async {
    await _fetchList('/notifications', onData: (items) {
      state = state.copyWith(notifications: items.map((e) => AppNotification.fromJson(e)).toList());
    });
  }

  Future<void> fetchUsers() async {
    await _fetchList('/auth/users', onData: (items) {
      state = state.copyWith(users: items.map((e) => AppUser.fromJson(e)).toList());
    });
  }

  Future<void> createTrip(Map<String, dynamic> payload) async {
    await _post('/trip', payload);
    await fetchTrips();
  }

  Future<void> startTrip(String id, int startKm) async {
    await _put('/trip/$id/start', {'startKm': startKm});
    await fetchTrips();
  }

  Future<void> endTrip(String id, Map<String, dynamic> payload) async {
    await _put('/trip/$id/end', payload);
    await fetchTrips();
  }

  Future<void> addAdvance(String id, double amount) async {
    await _post('/trip/$id/advance', {'amount': amount});
    await fetchTrips();
  }

  Future<void> addRoutePoint(String id, {required double latitude, required double longitude}) async {
    await _post('/trip/$id/route-point', {'latitude': latitude, 'longitude': longitude});
  }

  Future<void> assignTripBata(String id, double amount) async {
    await _put('/trip/$id/bata', {'amount': amount});
    await fetchTrips();
  }

  Future<void> createBill(Map<String, dynamic> payload) async {
    await _post('/bill', payload);
    await fetchBills();
  }

  Future<void> createVehicle(Map<String, dynamic> payload) async {
    await _post('/vehicle', payload);
    await fetchVehicles();
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> payload) async {
    await _put('/vehicle/$id', payload);
    await fetchVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await _delete('/vehicle/$id');
    await fetchVehicles();
  }

  Future<void> createDriver(Map<String, dynamic> payload) async {
    await _post('/driver', payload);
    await fetchDrivers();
  }

  Future<void> updateDriver(String id, Map<String, dynamic> payload) async {
    await _put('/driver/$id', payload);
    await fetchDrivers();
  }

  Future<void> deleteDriver(String id) async {
    await _delete('/driver/$id');
    await fetchDrivers();
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    await _post('/auth/users', payload);
    await fetchUsers();
  }

  Future<void> updateUser(String id, Map<String, dynamic> payload) async {
    await _put('/auth/users/$id', payload);
    await fetchUsers();
  }

  Future<void> deleteUser(String id) async {
    await _delete('/auth/users/$id');
    await fetchUsers();
  }

  Future<void> createPayment(Map<String, dynamic> payload) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.post('/payment', payload, token: token);
      debugPrint('createPayment response: $response');

      if (response is Map<String, dynamic>) {
        final rawBill = response['bill'];
        if (rawBill is Map<String, dynamic>) {
          final updatedBill = BillModel.fromJson(rawBill);
          final nextBills = state.bills
              .map((bill) => bill.id == updatedBill.id ? updatedBill : bill)
              .toList();
          final hasBill = nextBills.any((bill) => bill.id == updatedBill.id);
          state = state.copyWith(
            bills: hasBill ? nextBills : [updatedBill, ...state.bills],
          );
        }
      }

      state = state.copyWith(loading: false);
      await fetchBills();
      await fetchPayments();
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
      rethrow;
    }
  }

  Future<void> applyDriverLeave(String id, {required DateTime from, required DateTime to, required String reason}) async {
    await _post('/driver/$id/leave', {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'reason': reason,
    });
    await fetchDrivers();
  }

  Future<void> approveDriverLeave(String id, {required String leaveId, required String status}) async {
    await _put('/driver/$id/leave/approve', {'leaveId': leaveId, 'status': status});
    await fetchDrivers();
  }

  Future<Map<String, dynamic>> fetchDriverPayroll(String id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/driver/$id/payroll', token: token) as Map<String, dynamic>;
      state = state.copyWith(loading: false);
      return data;
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
      rethrow;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _put('/notifications/$id/read', {});
    await fetchNotifications();
  }

  Future<void> _fetchList(String path, {required void Function(List<Map<String, dynamic>>) onData}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.get(path, token: token) as List<dynamic>;
      final items = raw.cast<Map<String, dynamic>>();
      onData(items);
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
    }
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(apiServiceProvider).post(path, body, token: token);
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
      rethrow;
    }
  }

  Future<void> _put(String path, Map<String, dynamic> body) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(apiServiceProvider).put(path, body, token: token);
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
      rethrow;
    }
  }

  Future<void> _delete(String path) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(apiServiceProvider).delete(path, token: token);
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
      rethrow;
    }
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});
