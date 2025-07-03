import 'package:fleet/views/list/employee_list_page.dart';
import 'package:fleet/views/contracts/contracts_page.dart';
import 'package:fleet/views/odometers/odometers_page.dart';
import 'package:fleet/views/services/services_page.dart';
import 'package:fleet/views/vehicles/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import '../views/dashboard/dashboard_page.dart';
import '../views/login/login_screen.dart';
import '../views/login/register_screen.dart';
import '../views/settings/settings_page.dart';
import '../views/login/verification_screen.dart';
import '../views/subscription/subscription.dart';
import '../views/login/membership_details_screen.dart'; // Add this import

class AppRoutes {
  // Route names as constants
  static const String login = '/login';
  static const String register = '/register';
  static const String verification = '/verification';
  static const String dashboard = '/';
  static const String contracts = '/contracts';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String odometer = '/odometer';
  static const String subscription = '/subscription';
  static const String service = '/service';
  static const String membershipDetails = '/membership_details'; // Add this constant
  static const String list = '/list'; // Add this constant
  static const String vehicles = '/vehicles'; // Add this constant




  // Route map
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    dashboard: (_) => const DashboardPage(),
    contracts: (_) => const ContractsPage(),
    settings: (_) => const SettingsPage(),
    odometer: (_) => const OdometersPage(),
    subscription: (_) => const SubscriptionScreen(),
    service: (_) => const ServicesPage(),
    membershipDetails: (_) => const MembershipDetailsScreen(), // Add this route
    list: (_) => const EmployeeListPage(), // Add this route
    vehicles: (_) => const VehiclesPage(), // Add this route



  };

  // Special routes that need parameters
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == verification) {
      // Extract arguments
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => VerificationScreen(
          email: args['email'] ?? '',
          password: args['password'] ?? '',
          isGoogleSignIn: args['isGoogleSignIn'] ?? false,
          googleCredential: args['googleCredential'],
        ),
      );
    }
    return null;
  }

  // Navigation helpers
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  static Future<T?> navigateToReplacement<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }

  static void navigateToAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false, arguments: arguments);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static void navigateToWithPermissionCheck(BuildContext context, String route) {
    // We already have permission gates in the route definitions,
    // so we can just use the standard navigation
    navigateTo(context, route);
  }
}
