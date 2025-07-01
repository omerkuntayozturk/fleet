import 'package:flutter/material.dart';
class MetricsCard extends StatelessWidget {
 final IconData icon;
 final String label, value;
 final Color color;
 const MetricsCard({super.key, required this.icon, required this.label, required this.value, required this.color});
 @override
 Widget build(BuildContext ctx) {
   return Card(
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Row(children: [
         Icon(icon, size: 36, color: color),
         const SizedBox(width: 12),
         Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
           Text(label, style: Theme.of(ctx).textTheme.bodyLarge),
           Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
         ]),
       ]),
     ),
   );
 }
}