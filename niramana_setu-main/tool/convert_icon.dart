import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

// THIS SCRIPT NEEDS TO BE RUN WITH `flutter run`
// It will not work with `dart run` because it needs the flutter engine bindings.
// However, `flutter run` needs a `main.dart` file with a `main` function.
// So, we will create a temporary `main.dart` that calls this script.

void main() async {
  final String svgString = await File('assets/app_icon.png').readAsString();
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
  final image = await pictureInfo.picture.toImage(512, 512);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    final pngBytes = byteData.buffer.asUint8List();
    final file = File('assets/app_icon.png');
    await file.writeAsBytes(pngBytes);
    print('SVG converted to PNG successfully!');
  } else {
    print('Error converting SVG to PNG');
  }
}
