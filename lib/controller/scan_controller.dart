import 'dart:html';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite/tflite.dart';


class ScanContrloller extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFlite();
  }
  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  
  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x, y, w, h = 0.0;

  var label = "";
  initCamera() async{
    if(await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max
      );
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if(cameraCount%10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }

  }
  

  initTFlite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false
      );
  }

  objectDetector(CameraImage image) async {
    
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4
    );

    if(detector==null) {
      // if(detector.first['confidenceInClass']  * 100 > 45) {
      //   label = detector.first['label'].toString();

      // }
      // ignore: unused_local_variable
      var ourDetectedobject = detector?.first;
      if (ourDetectedobject['confidenceInClass'] * 100 > 45) {
        label = detector?.first['detectedClass'];
        h = ourDetectedobject['rect']['h'];
        w = ourDetectedobject['rect']['w'];
        x = ourDetectedobject['rect']['x'];
        y = ourDetectedobject['rect']['y'];

        

      }
      update();
      //print("Result is $detector");
    }
  }
}