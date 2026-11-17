import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:evalet/ui/common/colors.dart';

class CameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;

  const CameraPreviewWidget({
    super.key,
    required this.isCameraInitialized,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    if (isCameraInitialized && cameraController != null) {
      final size = MediaQuery.of(context).size;
      final orientation = MediaQuery.of(context).orientation;

      // Calculate aspect ratio based on orientation
      double aspectRatio;
      if (orientation == Orientation.portrait) {
        aspectRatio = size.width / size.height;
      } else {
        aspectRatio = size.height / size.width;
      }

      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CameraPreview(cameraController!),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }
  }
}
