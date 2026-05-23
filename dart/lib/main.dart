import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'widgets/game_hub.dart';
import 'widgets/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.initialize();
  GestureBinding.instance.resamplingEnabled = true;
  
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {

    }
  }

  runApp(
    MaterialApp(
      title: 'Retro Fun Crate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameHub(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(

            gestureSettings: const DeviceGestureSettings(touchSlop: 4.0),
          ),
          child: child!,
        );
      },
    ),
  );
}
