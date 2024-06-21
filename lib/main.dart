import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:liveness_detection/liveness_model.dart';

List<CameraDescription> cameras = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CameraController controller;
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  ValueNotifier<Liveness> liveness = ValueNotifier(Liveness());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = CameraController(cameras.last, ResolutionPreset.max);
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback(
      (timeStamp) async {
        await controller.initialize();
        setState(() {});
        controller.startImageStream(
          (image) async {
            int rotationCompensation =
                _orientations[controller.value.deviceOrientation] ?? 0;
            final format = InputImageFormatValue.fromRawValue(image.format.raw);
            final sensorOrientation = cameras.last.sensorOrientation;
            if (cameras.last.lensDirection == CameraLensDirection.front) {
              // front-facing
              rotationCompensation =
                  (sensorOrientation + rotationCompensation) % 360;
            } else {
              // back-facing
              rotationCompensation =
                  (sensorOrientation - rotationCompensation + 360) % 360;
            }
            var rotation =
                InputImageRotationValue.fromRawValue(rotationCompensation);
            var inputImage = InputImage.fromBytes(
              bytes: Uint8List.fromList(
                image.planes.fold(
                    <int>[],
                    (List<int> previousValue, element) =>
                        previousValue..addAll(element.bytes)),
              ),
              metadata: InputImageMetadata(
                size: Size(
                  image.width.toDouble(),
                  image.height.toDouble(),
                ),
                rotation: rotation!,
                format: format!,
                bytesPerRow: image.planes[1].bytesPerRow,
              ),
            );
            var faceDetector = FaceDetector(
              options: FaceDetectorOptions(
                performanceMode: FaceDetectorMode.accurate,
                enableClassification: true,
              ),
            );
            var faces = await faceDetector.processImage(inputImage);
            liveness.value = Liveness();
            for (var row in faces) {
              print("VERTICAL => ${row.headEulerAngleX}");
              print("HORIZONTAL => ${row.headEulerAngleY}");
              liveness.value = Liveness(
                // horizontal: row.headEulerAngleX != null ? row.headEulerAngleX  : null,
                horizontal: row.headEulerAngleY != null
                    ? row.headEulerAngleY! < 20 && row.headEulerAngleY! > -20
                        ? Horizontal.standBy
                        : row.headEulerAngleY! >= -20
                            ? Horizontal.left
                            : Horizontal.right
                    : null,
                vertical: row.headEulerAngleX != null
                    ? row.headEulerAngleX! < 15 && row.headEulerAngleX! > -8
                        ? Vertical.standBy
                        : row.headEulerAngleX! >= -8
                            ? Vertical.top
                            : Vertical.bottom
                    : null,
                smile: (row.smilingProbability ?? 0) > 0.09,
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 4,
              child: CameraPreview(controller),
            ),
            ValueListenableBuilder(
              valueListenable: liveness,
              builder: (context, val, _) {
                return Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(liveness.value.horizontal != null
                          ? (liveness.value.horizontal?.name ?? "")
                          : "-"),
                      Text(liveness.value.vertical != null
                          ? (liveness.value.vertical?.name ?? "")
                          : "-"),
                      Text(
                        liveness.value.smile != null
                            ? liveness.value.smile!
                                ? "Tersenyum"
                                : "Tidak senyum"
                            : "-",
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
