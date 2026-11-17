import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/image_validation/validation_result.dart';

abstract class CarCameraState extends Equatable {
  const CarCameraState();

  @override
  List<Object?> get props => [];
}

class CarCameraInitial extends CarCameraState {
  const CarCameraInitial();
}

class CarCameraValidating extends CarCameraState {
  const CarCameraValidating();
}

class CarCameraValidationSuccess extends CarCameraState {
  final ImageValidationResult result;
  final String imagePath;

  const CarCameraValidationSuccess({
    required this.result,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [result, imagePath];
}

class CarCameraValidationError extends CarCameraState {
  final String message;
  final ImageValidationResult result;
  final CameraController cameraController;
  final bool isFlashOn;

  const CarCameraValidationError({
    required this.message,
    required this.result,
    required this.cameraController,
    required this.isFlashOn,
  });

  @override
  List<Object?> get props => [message, result, cameraController, isFlashOn];
}

class CarCameraInitialized extends CarCameraState {
  final CameraController cameraController;
  final bool isFlashOn;

  const CarCameraInitialized({
    required this.cameraController,
    this.isFlashOn = false,
  });

  @override
  List<Object?> get props => [cameraController, isFlashOn];
}

class CarCameraInitializationError extends CarCameraState {
  final String message;

  const CarCameraInitializationError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CarCameraFlashToggled extends CarCameraState {
  final bool isFlashOn;
  final CameraController cameraController;

  const CarCameraFlashToggled({
    required this.isFlashOn,
    required this.cameraController,
  });

  @override
  List<Object?> get props => [isFlashOn, cameraController];
}
