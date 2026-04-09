/// Role definitions and permissions for the Travel Fleet application
enum UserRole {
  owner,
  employee,
  driver,
}

extension UserRoleExtension on UserRole {
  String get value {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner/Admin';
      case UserRole.employee:
        return 'Employee';
      case UserRole.driver:
        return 'Driver';
    }
  }

  bool get canScheduleTrip => true;

  bool get canAssignVehicleDriver {
    return this == UserRole.owner || this == UserRole.employee;
  }

  bool get canManageVehicles {
    return this == UserRole.owner || this == UserRole.employee;
  }

  bool get canManageEmployees {
    return this == UserRole.owner;
  }

  bool get canManageBilling {
    return this == UserRole.owner || this == UserRole.employee;
  }

  bool get canViewAlerts => true;

  bool get canApplyLeave => true;

  bool get canManageDrivers {
    return this == UserRole.owner || this == UserRole.employee;
  }

  bool get canApproveLeaves {
    return this == UserRole.owner;
  }

  bool get canManageSalary {
    return this == UserRole.owner;
  }

  bool get canUpdateDriverEarnings {
    return this == UserRole.owner || this == UserRole.employee;
  }

  bool get canStartEndTrip {
    return this == UserRole.driver;
  }

  bool get canEnterTripDetails {
    return this == UserRole.driver;
  }

  bool get canUseGPS {
    return this == UserRole.driver;
  }

  bool get canViewEarnings {
    return this == UserRole.driver;
  }

  bool get canViewAssignedTrips {
    return this == UserRole.driver;
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.employee,
    );
  }
}

/// Available screens for each role
class RoleScreens {
  static const List<String> ownerScreens = [
    'home',
    'trips',
    'vehicles',
    'drivers',
    'billing',
    'payments',
    'users',
    'alerts',
    'settings',
  ];

  static const List<String> employeeScreens = [
    'home',
    'trips',
    'vehicles',
    'drivers',
    'billing',
    'payments',
    'alerts',
    'settings',
  ];

  static const List<String> driverScreens = [
    'home',
    'trips',
    'earnings',
    'alerts',
    'settings',
  ];

  static List<String> getScreensForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return ownerScreens;
      case UserRole.employee:
        return employeeScreens;
      case UserRole.driver:
        return driverScreens;
    }
  }
}
