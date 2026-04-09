import '../constants/role_permissions.dart';

/// Helper class for role-based API operations and validation
class RoleBasedHelper {
  /// Check if user has permission for specific operation
  static bool hasPermission(
    UserRole role,
    String operationName,
  ) {
    switch (operationName) {
      case 'schedule_trip':
        return role.canScheduleTrip;
      case 'assign_vehicle_driver':
        return role.canAssignVehicleDriver;
      case 'manage_vehicles':
        return role.canManageVehicles;
      case 'manage_employees':
        return role.canManageEmployees;
      case 'manage_billing':
        return role.canManageBilling;
      case 'view_alerts':
        return role.canViewAlerts;
      case 'apply_leave':
        return role.canApplyLeave;
      case 'manage_drivers':
        return role.canManageDrivers;
      case 'approve_leaves':
        return role.canApproveLeaves;
      case 'manage_salary':
        return role.canManageSalary;
      case 'update_driver_earnings':
        return role.canUpdateDriverEarnings;
      case 'start_end_trip':
        return role.canStartEndTrip;
      case 'enter_trip_details':
        return role.canEnterTripDetails;
      case 'use_gps':
        return role.canUseGPS;
      case 'view_earnings':
        return role.canViewEarnings;
      case 'view_assigned_trips':
        return role.canViewAssignedTrips;
      default:
        return false;
    }
  }

  /// Get error message for permission denied
  static String getPermissionDeniedMessage(String operationName) {
    return 'You do not have permission to $operationName. Please contact your administrator.';
  }

  /// Filter list items based on role permissions
  static List<T> filterByRole<T>(
    List<T> items,
    UserRole role,
    bool Function(T, UserRole) shouldInclude,
  ) {
    return items.where((item) => shouldInclude(item, role)).toList();
  }
}
