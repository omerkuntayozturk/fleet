import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'views/vehicles/vehicle_list_page.dart';
import 'views/vehicles/vehicle_kanban_page.dart';
import 'views/vehicles/vehicle_detail_page.dart';
import 'views/contracts/contracts_page.dart';
import 'views/odometers/odometers_page.dart';
import 'views/services/services_page.dart';
import 'views/reports/reports_page.dart';
import 'views/settings/settings_page.dart';
class MyApp extends StatelessWidget {
 const MyApp({super.key});
 @override
 Widget build(BuildContext ctx) {
   return MaterialApp(
     title: 'Fleet Management',
     theme: AppTheme.light,
     debugShowCheckedModeBanner: false,
     initialRoute: '/',
     routes: {
       '/': (_) => const VehicleListPage(),
       '/kanban': (_) => const VehicleKanbanPage(),
       '/vehicle_detail': (_) => const VehicleDetailPage(),
       '/contracts': (_) => const ContractsPage(),
       '/odometers': (_) => const OdometersPage(),
       '/services': (_) => const ServicesPage(),
       '/reports': (_) => const ReportsPage(),
       '/settings': (_) => const SettingsPage(),
     },
   );
 }
}