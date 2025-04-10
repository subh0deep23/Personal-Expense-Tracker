import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  // Create a recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Define the size
  const size = Size(512, 512);
  
  // Draw the logo
  final paint = Paint()
    ..color = Color(0xFF4CAF50)
    ..style = PaintingStyle.fill;
  
  // Background circle
  canvas.drawCircle(Offset(size.width / 2, size.height / 2), 240, paint);
  
  // Dollar sign
  final dollarPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  final dollarPath = Path();
  dollarPath.moveTo(256, 120);
  dollarPath.cubicTo(242.7, 120, 232, 130.7, 232, 144);
  dollarPath.lineTo(232, 160);
  dollarPath.lineTo(208, 160);
  dollarPath.cubicTo(199.2, 160, 192, 167.2, 192, 176);
  dollarPath.cubicTo(192, 184.8, 199.2, 192, 208, 192);
  dollarPath.lineTo(232, 192);
  dollarPath.lineTo(232, 320);
  dollarPath.lineTo(208, 320);
  dollarPath.cubicTo(199.2, 320, 192, 327.2, 192, 336);
  dollarPath.cubicTo(192, 344.8, 199.2, 352, 208, 352);
  dollarPath.lineTo(232, 352);
  dollarPath.lineTo(232, 368);
  dollarPath.cubicTo(232, 381.3, 242.7, 392, 256, 392);
  dollarPath.cubicTo(269.3, 392, 280, 381.3, 280, 368);
  dollarPath.lineTo(280, 352);
  dollarPath.lineTo(304, 352);
  dollarPath.cubicTo(312.8, 352, 320, 344.8, 320, 336);
  dollarPath.cubicTo(320, 327.2, 312.8, 320, 304, 320);
  dollarPath.lineTo(280, 320);
  dollarPath.lineTo(280, 192);
  dollarPath.lineTo(304, 192);
  dollarPath.cubicTo(312.8, 192, 320, 184.8, 320, 176);
  dollarPath.cubicTo(320, 167.2, 312.8, 160, 304, 160);
  dollarPath.lineTo(280, 160);
  dollarPath.lineTo(280, 144);
  dollarPath.cubicTo(280, 130.7, 269.3, 120, 256, 120);
  dollarPath.close();
  
  canvas.drawPath(dollarPath, dollarPaint);
  
  // Coins
  final coinPaint = Paint()
    ..color = Color(0xFFFFC107)
    ..style = PaintingStyle.fill;
  
  final strokePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  
  canvas.drawCircle(Offset(160, 320), 48, coinPaint);
  canvas.drawCircle(Offset(160, 320), 48, strokePaint);
  
  canvas.drawCircle(Offset(352, 320), 48, coinPaint);
  canvas.drawCircle(Offset(352, 320), 48, strokePaint);
  
  canvas.drawCircle(Offset(256, 368), 48, coinPaint);
  canvas.drawCircle(Offset(256, 368), 48, strokePaint);
  
  // Convert to an image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save the image
  final file = File('assets/logo.png');
  await file.writeAsBytes(buffer);
  
  print('Logo saved to ${file.path}');
}
