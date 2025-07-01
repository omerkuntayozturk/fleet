import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;

/// A utility class that provides platform-specific functionality
class PlatformUtil {
  /// Determines whether the app is running on the web platform
  static bool get isWeb => kIsWeb;
  
  /// Gets a directory path that can be used for storing files
  /// Returns null if no suitable directory is found
  static Future<String?> getWritableDirectoryPath() async {
    if (kIsWeb) {
      return null; // Web doesn't have direct file system access
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      print('Error getting application documents directory: $e');
      
      try {
        final dir = await getTemporaryDirectory();
        return dir.path;
      } catch (e) {
        print('Error getting temporary directory: $e');
        return null;
      }
    }
  }
  
  /// Saves a file to the device's file system if possible
  /// Returns the path to the saved file, or null if saving failed
  static Future<String?> saveFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      downloadFileForWeb(bytes, fileName);
      return null;
    } else {
      final dirPath = await getWritableDirectoryPath();
      if (dirPath == null) {
        return null;
      }
      
      final filePath = '$dirPath/$fileName';
      final file = File(filePath);
      
      try {
        await file.writeAsBytes(bytes);
        return filePath;
      } catch (e) {
        print('Error saving file: $e');
        return null;
      }
    }
  }
  
  /// Initiates a file download in web browsers
  static void downloadFileForWeb(Uint8List bytes, String fileName) {
    if (!kIsWeb) return;
    
    // Create a blob from bytes
    final blob = html.Blob([bytes]);
    
    // Create a URL for this blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create an anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // Add to the DOM
    html.document.body!.children.add(anchor);
    
    // Trigger the download
    anchor.click();
    
    // Clean up
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
