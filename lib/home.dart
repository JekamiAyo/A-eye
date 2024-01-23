import 'package:a_eye/ocr_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:toast/toast.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'bndbox.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'camera.dart';
import 'models.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SpeechToText speechToText = SpeechToText();
  String textSpeech = "";
  FlutterTts flutterTts = FlutterTts();
  List<dynamic> _recognitions = [];
  final List<dynamic> ans = [];
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";
  double screenH = 0;
  double screenW = 0;
  late int previewH;
  late int previewW;
  double left = 0;
  double top = 0;
  double mid = 0;
  double woo = 0;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    speechToText.stop();
  }

  void initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    FocusScope.of(context).unfocus();
    await speechToText.listen(onResult: onSpeechToTextResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    FocusScope.of(context).unfocus();
    await speechToText.stop();
  }

  void onSpeechToTextResult(SpeechRecognitionResult result) {
    setState(() {
      textSpeech = result.recognizedWords;
    });
    print(textSpeech);
  }

  void speak(String text) {
    flutterTts.setPitch(1.2);
    flutterTts.speak(text);
    flutterTts.setSpeechRate(0.6);
  }

  @override
  void initState() {
    ToastContext().init(context);
    super.initState();
    // initSpeechToText();
    speak(
        "Welcome to a eye, ready for your service. Select either Text Recognition or Object Detection. Kindly meet someone who's not visually impaired to help with navigation");
  }

  loadModel() async {
    speak("Your object detection has been started using SSD Mobilenet Model");
    String res;
    switch (_model) {
      case yolo:
        res = (await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        ))!;
        break;

      case mobilenet:
        res = (await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt"))!;
        break;

      case posenet:
        res = (await Tflite.loadModel(
            model: "assets/posenet_mv1_075_float_from_checkpoints.tflite"))!;
        break;

      default:
        res = (await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt"))!;
    }
    if (kDebugMode) {
      print(res);
    }
  }

  onSelect(model) {
    setState(() {
      _model = model;
      //Toast.show("You are using $_model model for object detection !!!",  duration: 1, gravity:  0);
    });
    loadModel();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;

      try1();
    });
  }

  try1() {
    Size screen = MediaQuery.of(context).size;
    screenW = screen.width;
    screenH = screen.height;
    previewH = math.max(_imageHeight, _imageWidth);
    previewW = math.min(_imageHeight, _imageWidth);
    //print(_recognitions);
    // _recognitions == null
    _recognitions.isEmpty
        ? []
        : _recognitions.map((re) {
            var _x = re["rect"]["x"];
            var _w = re["rect"]["w"];
            var _y = re["rect"]["y"];
            var _h = re["rect"]["h"];
            var scaleW, scaleH, x, y, w, h;
            if (kDebugMode) {
              print(_x);
            }
            if (kDebugMode) {
              print(_y);
            }

            if (screenH / screenW > previewH / previewW) {
              scaleW = screenH / previewH * previewW;
              scaleH = screenH;
              if (kDebugMode) {
                print(scaleH);
              }
              if (kDebugMode) {
                print(scaleW);
              }
              var difW = (scaleW - screenW) / scaleW;
              x = (_x - difW / 2) * scaleW;
              w = _w * scaleW;
              if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
              y = _y * scaleH;
              h = _h * scaleH;
              if (kDebugMode) {
                print(x);
              }
              if (kDebugMode) {
                print(y);
              }
            } else {
              scaleH = screenW / previewW * previewH;
              scaleW = screenW;
              var difH = (scaleH - screenH) / scaleH;
              x = _x * scaleW;
              w = _w * scaleW;
              y = (_y - difH / 2) * scaleH;
              h = _h * scaleH;
              if (kDebugMode) {
                print(x);
              }
              if (kDebugMode) {
                print(y);
              }
              if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
              if (kDebugMode) {
                print(x);
              }
              if (kDebugMode) {
                print(y);
              }
            }

            left = math.max(0, x);
            top = math.max(0, y);

            // print(left);
            // print(w);
            woo = math.min(left + w, 480);
            mid = (left + w) / 2;
            if (re["confidenceInClass"] > 0.5) {
              speak("There is a ${re["detectedClass"]} ahead");
              flutterTts.setSilence(3);
              if (mid >= 165) {
                speak("There is a ${re["detectedClass"]} on your right side");
                flutterTts.setSilence(3);
              } else {
                speak("There is a ${re["detectedClass"]} on your left side");
                flutterTts.setSilence(3);
              }
              Toast.show("There is a ${re["detectedClass"]} ahead!!!",
                  duration: 1, gravity: 0);
            }
          }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _model == ""
          ? null
          : AppBar(
              title: const Text('OBJECT DETECTION'),
              centerTitle: true,
              leading: IconButton(
                onPressed: () {
                  setState(() {
                    _model = "";
                    flutterTts.stop();
                  });
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
      body: _model == ""
          ? Center(
              child: ListView(
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.55),
                          BlendMode.darken,
                        ),
                        fit: BoxFit.cover,
                        image: const AssetImage(
                          'assets/unsplash_FSwYHC5ymxE.png',
                        ),
                      ),
                    ),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(
                          height: 200,
                        ),
                        const Text(
                          "A-EYE",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 30.0,
                            fontFamily: "Raleway",
                          ),
                        ),
                        const SizedBox(
                          height: 200,
                        ),
                        GestureDetector(
                          onTap: () {
                            onSelect(ssd);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(18)),
                            width: 200,
                            padding: const EdgeInsets.all(15),
                            child: const Center(
                              child: Text(
                                "O - D",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Raleway",
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OCRScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(18)),
                            width: 200,
                            padding: const EdgeInsets.all(15),
                            child: const Center(
                              child: Text(
                                "O - C - R",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Raleway",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Camera(
                  widget.cameras,
                  _model,
                  setRecognitions,
                ),
                BndBox(
                  // _recognitions == null ? [] : _recognitions,
                  _recognitions,
                  math.max(_imageHeight, _imageWidth),
                  math.min(_imageHeight, _imageWidth),
                  screen.height,
                  screen.width,
                  _model,
                ),
              ],
            ),
    );
  }
}
