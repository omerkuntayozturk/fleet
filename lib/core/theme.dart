import 'package:flutter/material.dart';
class AppTheme {
 static final light = ThemeData(
   primarySwatch: Colors.indigo,
   scaffoldBackgroundColor: Colors.grey[50],
   appBarTheme: const AppBarTheme(
     backgroundColor: Colors.white,
     foregroundColor: Colors.black87,
     elevation: 0,
   ),
   cardTheme: CardTheme(
     elevation: 2,
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
   ),
   textTheme: const TextTheme(
     titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
     bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
   ),
 );
}