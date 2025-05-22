import 'package:flutter/material.dart';

class AppTheme {
 static final light = ThemeData(
   primarySwatch: Colors.teal,
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
     bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
     titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
   ),
 );
}