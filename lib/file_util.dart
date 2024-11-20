// TEMP CLASS, NOT GONNA BE IN PROD

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileUtil {
  static saveFile(String jsonData) async {
    try {
      // Get the application directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sketch.json');

      await file.writeAsString(jsonData);
      print('File saved');
    } catch (e) {
      print('Error saving file: $e');
    }
  }

  static Future<String> readFile() async {
    try {
      // Get the application directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sketch.json');

      // Check if the file exists
      if (await file.exists()) {
        // Read the string from the file
        return await file.readAsString();
      } else {
        print('File does not exist');
        return '';
      }
    } catch (e) {
      print('Error reading file: $e');
      return '';
    }
  }
}
