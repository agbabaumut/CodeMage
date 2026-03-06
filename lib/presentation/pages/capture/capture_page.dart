import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../controllers/capture_controller.dart';
import 'widgets/camera_overlay_painter.dart';

class CapturePage extends GetView<CaptureController> {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.hasPermission.value &&
            !controller.isCameraInitialized.value) {
          return _buildPermissionView(context);
        }

        if (!controller.isCameraInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.burrowingOwl),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: CameraPreview(controller.cameraController!),
            ),

            Obx(() {
              if (!controller.isLiveDetectionEnabled.value) {
                return const SizedBox.shrink();
              }

              return CustomPaint(
                painter: CameraOverlayPainter(
                  faces: controller.detectedFaces.toList(),
                  recognizedText: controller.detectedText.value,
                  imageSize: controller.imageSize,
                  canvasSize: MediaQuery.of(context).size,
                  isFrontCamera: controller.isFrontCamera.value,
                ),
                size: Size.infinite,
              );
            }),

            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.close,
                    onTap: () => Get.back(),
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          _CircleButton(
                            icon: Icons.burst_mode_rounded,
                            onTap: controller.pickMultipleFromGallery,
                          ),
                          const SizedBox(height: 6),
                          const _BatchTooltip(),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Obx(() => _CircleButton(
                            icon: controller.isLiveDetectionEnabled.value
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            onTap: controller.toggleLiveDetection,
                          )),
                      const SizedBox(width: 12),
                      Obx(() => _CircleButton(
                            icon: _flashIcon(controller.flashMode.value),
                            onTap: controller.toggleFlash,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            Obx(() {
              if (controller.detectionLabel.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: controller.detectedFaces.isNotEmpty
                          ? const Color(0xFF69F0AE).withValues(alpha: 0.2)
                          : const Color(0xFF42A5F5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: controller.detectedFaces.isNotEmpty
                            ? const Color(0xFF69F0AE).withValues(alpha: 0.5)
                            : const Color(0xFF42A5F5).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      controller.detectionLabel.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: controller.detectedFaces.isNotEmpty
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                ),
              );
            }),

            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CircleButton(
                    icon: Icons.photo_library_rounded,
                    onTap: controller.pickFromGallery,
                    size: 52,
                  ),

                  Obx(() => GestureDetector(
                        onTap: controller.isCapturing.value
                            ? null
                            : controller.captureImage,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.isCapturing.value
                                  ? AppColors.textMuted
                                  : Colors.white,
                            ),
                          ),
                        ),
                      )),

                  _CircleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: controller.switchCamera,
                    size: 52,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPermissionView(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 16,
            child: _CircleButton(
              icon: Icons.close,
              onTap: () => Get.back(),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 48,
                      color: AppColors.burrowingOwl,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Camera Access Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.permissionPermanentlyDenied.value
                        ? 'Camera permission was denied. Please enable it in Settings to use the camera.'
                        : 'CodeMage needs camera access to capture images for face detection and document scanning.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.retryPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burrowingOwl,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        controller.permissionPermanentlyDenied.value
                            ? 'Open Settings'
                            : 'Grant Permission',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: controller.pickFromGallery,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.greatGreyOwl.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Pick from Gallery Instead',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _flashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.torch:
        return Icons.flashlight_on_rounded;
    }
  }
}

class _BatchTooltip extends StatefulWidget {
  const _BatchTooltip();

  @override
  State<_BatchTooltip> createState() => _BatchTooltipState();
}

class _BatchTooltipState extends State<_BatchTooltip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Batch select',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
