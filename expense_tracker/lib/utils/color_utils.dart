import 'package:flutter/material.dart';

class ColorUtils {
  // Convert hex string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  // Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
  
  // Get a list of predefined colors for categories
  static List<Color> getCategoryColors() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
  }
  
  // Get a contrasting text color (white or black) based on background color
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate the perceptive luminance (perceived brightness)
    // This formula gives a value between 0 and 255
    final luminance = (0.299 * backgroundColor.red + 
                       0.587 * backgroundColor.green + 
                       0.114 * backgroundColor.blue) / 255;
    
    // Return black for bright colors and white for dark colors
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
