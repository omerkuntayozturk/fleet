import 'package:fleet/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../models/vehicle.dart';

class VehicleListPage extends StatefulWidget {
 const VehicleListPage({super.key});
 @override
 State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> with SingleTickerProviderStateMixin {
 final svc = VehicleService();
 late AnimationController _controller;
 final TextEditingController _searchController = TextEditingController();
 List<bool> _isStatsHovering = []; // List for stats cards hovering state

 @override
 void initState() {
   super.initState();
   _controller = AnimationController(
     duration: const Duration(milliseconds: 800),
     vsync: this,
   )..forward();
       
   // Initialize hovering states for stats cards
   _isStatsHovering = List.generate(4, (_) => false);
 }

 @override
 void dispose() {
   _controller.dispose();
   _searchController.dispose();
   super.dispose();
 }

 @override
 Widget build(BuildContext context) {
   final items = svc.getAll();
   
   return Scaffold(
     appBar: const TopBar(),
     drawer: const SideMenu(),
     body: SingleChildScrollView(
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Header section with title and search
             _buildHeaderSection(context),
             
             const SizedBox(height: 32),
             
             // Stats section
             _buildStatsSection(context),
             
             const SizedBox(height: 40),
             
             // Vehicles list section
             _buildVehiclesSection(context, items),
           ],
         ),
       ),
     ),
     floatingActionButton: FloatingActionButton(
       child: const Icon(Icons.add),
       onPressed: () {
         final v = Vehicle(
           id: DateTime.now().toIso8601String(),
           model: "", // Add empty string for required model parameter
           plate: "", // Add empty string for required plate parameter
         );
         svc.add(v);
         setState(() {});
       },
     ),
   );
 }

 Widget _buildHeaderSection(BuildContext context) {
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(0, -0.5),
                   end: Offset.zero,
                 ).animate(CurvedAnimation(
                   parent: _controller,
                   curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                 )),
                 child: Text(
                   'Araç Listesi',
                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).primaryColor,
                       ),
                 ),
               ),
               const SizedBox(height: 8),
               FadeTransition(
                 opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                   CurvedAnimation(
                     parent: _controller,
                     curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                   ),
                 ),
                 child: Text(
                   'Filodaki tüm araçları görüntüleyin',
                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         color: Colors.grey[600],
                       ),
                 ),
               ),
             ],
           ),
           SizedBox(
             width: 300,
             child: FadeTransition(
               opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                 CurvedAnimation(
                   parent: _controller,
                   curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                 ),
               ),
               child: TextField(
                 controller: _searchController,
                 decoration: InputDecoration(
                   hintText: 'Araç ara...',
                   prefixIcon: const Icon(Icons.search),
                   filled: true,
                   fillColor: Colors.grey[100],
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(30),
                     borderSide: BorderSide.none,
                   ),
                   contentPadding: const EdgeInsets.symmetric(vertical: 0),
                 ),
               ),
             ),
           ),
         ],
       ),
     ],
   );
 }

 Widget _buildStatsSection(BuildContext context) {
   return LayoutBuilder(
     builder: (ctx, constraints) {
       int cols = constraints.maxWidth > 1200
           ? 4
           : constraints.maxWidth > 800
               ? 2
               : 1;
       
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           FadeTransition(
             opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
               CurvedAnimation(
                 parent: _controller,
                 curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
               ),
             ),
             child: Text(
               'Araç İstatistikleri',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                     fontWeight: FontWeight.bold,
                   ),
             ),
           ),
           const SizedBox(height: 16),
           GridView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: cols,
               crossAxisSpacing: 24,
               mainAxisSpacing: 24,
               childAspectRatio: 1.5,
             ),
             itemCount: 4,
             itemBuilder: (context, index) {
               final List<Map<String, dynamic>> cards = [
                 {
                   'icon': Icons.directions_car,
                   'title': 'Toplam Araç',
                   'value': '${svc.getAll().length}',
                   'color': Colors.purple,
                   'trend': '+3%',
                   'isUp': true,
                 },
                 {
                   'icon': Icons.local_shipping,
                   'title': 'Kamyonlar',
                   'value': '12',
                   'color': Colors.orange,
                   'trend': '+2%',
                   'isUp': true,
                 },
                 {
                   'icon': Icons.two_wheeler,
                   'title': 'Motosikletler',
                   'value': '8',
                   'color': Colors.blue,
                   'trend': '+5%',
                   'isUp': true,
                 },
                 {
                   'icon': Icons.electric_car,
                   'title': 'Elektrikli',
                   'value': '6',
                   'color': Colors.green,
                   'trend': '+10%',
                   'isUp': true,
                 },
               ];

               return MouseRegion(
                 onEnter: (_) => setState(() => _isStatsHovering[index] = true),
                 onExit: (_) => setState(() => _isStatsHovering[index] = false),
                 child: AnimatedContainer(
                   duration: const Duration(milliseconds: 200),
                   transform: _isStatsHovering[index]
                       ? (Matrix4.identity()..translate(0, -5, 0))
                       : Matrix4.identity(),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                         color: cards[index]['color'].withOpacity(_isStatsHovering[index] ? 0.3 : 0.1),
                         blurRadius: 15,
                         offset: const Offset(0, 5),
                       ),
                     ],
                     border: Border.all(
                       color: _isStatsHovering[index]
                           ? cards[index]['color']
                           : Colors.grey[200]!,
                       width: 1,
                     ),
                   ),
                   child: Padding(
                     padding: const EdgeInsets.all(20),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: cards[index]['color'].withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Icon(
                                 cards[index]['icon'],
                                 color: cards[index]['color'],
                                 size: 24,
                               ),
                             ),
                             Row(
                               children: [
                                 Icon(
                                   cards[index]['isUp']
                                       ? Icons.arrow_upward
                                       : Icons.arrow_downward,
                                   color: cards[index]['isUp']
                                       ? Colors.green
                                       : Colors.red,
                                   size: 16,
                                 ),
                                 const SizedBox(width: 4),
                                 Text(
                                   cards[index]['trend'],
                                   style: TextStyle(
                                     color: cards[index]['isUp']
                                         ? Colors.green
                                         : Colors.red,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Text(
                           cards[index]['title'],
                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                 color: Colors.grey[600],
                               ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           cards[index]['value'],
                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                 fontWeight: FontWeight.bold,
                                 color: Theme.of(context).textTheme.bodyMedium?.color,
                               ),
                         ),
                       ],
                     ),
                   ),
                 ),
               );
             },
           ),
         ],
       );
     },
   );
 }

 Widget _buildVehiclesSection(BuildContext context, List<Vehicle> vehicles) {
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(
             'Araç Listesi',
             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                   fontWeight: FontWeight.bold,
                 ),
           ),
           TextButton.icon(
             icon: const Icon(Icons.refresh),
             label: const Text('Yenile'),
             onPressed: () {
               setState(() {});
             },
           ),
         ],
       ),
       const SizedBox(height: 16),
       Container(
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           boxShadow: [
             BoxShadow(
               color: Colors.grey.withOpacity(0.1),
               blurRadius: 10,
               offset: const Offset(0, 5),
             ),
           ],
         ),
         child: ListView.builder(
           shrinkWrap: true,
           physics: const NeverScrollableScrollPhysics(),
           padding: const EdgeInsets.all(12),
           itemCount: vehicles.length,
           itemBuilder: (context, i) => ListTile(
             title: Text(vehicles[i].model),
             subtitle: Text(vehicles[i].plate),
             onTap: () => Navigator.pushNamed(context, '/vehicle_detail', arguments: vehicles[i]),
           ),
         ),
       ),
     ],
   );
 }
}