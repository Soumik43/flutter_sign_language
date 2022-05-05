import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class Home extends StatefulWidget {
  final bool isLetters;
  const Home({
    this.isLetters = false,
    Key? key,
  }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String answer = '';
  CameraController? cameraController;
  CameraImage? cameraImage;

  // Load model for 1 - 9
  loadmodel() async {
    widget.isLetters
        ? Tflite.loadModel(
            model: "assets/letters/model_unquant.tflite",
            labels: "assets/letters/labels.txt",
          )
        : Tflite.loadModel(
            model: "assets/model_unquant.tflite",
            labels: 'assets/labels.txt',
          );
  }

  initCamera(bool frontCamera) {
    // print("this is cameras -> ${cameras!}");
    cameraController = CameraController(
      frontCamera ? cameras![1] : cameras![0],
      ResolutionPreset.high,
    );
    cameraController!.initialize().then(
      (value) {
        if (!mounted) {
          return;
        }
        setState(() {
          cameraController!.startImageStream(
            (image) => {
              if (true)
                {
                  cameraImage = image,
                  applymodelonimages(),
                }
            },
          );
        });
      },
    );
  }

  applymodelonimages() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map(
          (plane) {
            return plane.bytes;
          },
        ).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 3,
        threshold: 0.1,
        asynch: true,
      );

      answer = '';

      for (var prediction in predictions!) {
        if (!widget.isLetters) {
          int firstLabel =
              int.parse(prediction['label'].toString().substring(0, 1)) + 1;
          answer += firstLabel.toString().toUpperCase() +
              prediction['label'].toString().substring(1) +
              " " +
              (prediction['confidence'] as double).toStringAsFixed(3) +
              '\n';
        } else {
          answer +=
              prediction['label'].toString().substring(0, 1).toUpperCase() +
                  prediction['label'].toString().substring(1) +
                  " " +
                  (prediction['confidence'] as double).toStringAsFixed(3) +
                  '\n';
        }
      }

      setState(() {
        answer = answer;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera(true);
    loadmodel();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
      ),
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: cameraImage != null
              ? Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.blue,
                      child: Stack(
                        children: [
                          Positioned(
                            child: Center(
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height,
                                width: MediaQuery.of(context).size.width,
                                child: AspectRatio(
                                  aspectRatio:
                                      cameraController!.value.aspectRatio,
                                  child: CameraPreview(
                                    cameraController!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                color: Colors.black87,
                                child: Center(
                                  child: Text(
                                    answer,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        // color: Colors.black,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              cameraController!.description.lensDirection ==
                                      CameraLensDirection.front
                                  ? initCamera(false)
                                  : initCamera(true);
                            });
                          },
                          icon: const Icon(Icons.cameraswitch_rounded),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(),
        ),
      ),
    );
  }
}
