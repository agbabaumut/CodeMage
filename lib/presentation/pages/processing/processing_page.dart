import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/processing_result.dart';
import '../../../domain/entities/processing_type.dart';
import '../../controllers/processing_controller.dart';

class ProcessingPage extends GetView<ProcessingController> {
  const ProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.currentStatus.value == ProcessingStatus.error) {
            return _buildErrorState();
          }

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.bgElevated,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(controller.imagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final type = controller.detectedType.value;
                        if (type == null) {
                          return const Text(
                            'Analyzing image...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          );
                        }
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                type.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                      Expanded(
                        child: Obx(() => ListView.builder(
                              itemCount: controller.processingSteps.length,
                              itemBuilder: (context, index) {
                                final step = controller.processingSteps[index];
                                return _ProcessingStepTile(step: step);
                              },
                            )),
                      ),

                      const SizedBox(height: 12),
                      Obx(() => Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: controller.overallProgress.value,
                                  minHeight: 6,
                                  backgroundColor: AppColors.greatGreyOwl
                                      .withValues(alpha: 0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.burrowingOwl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(controller.overallProgress.value * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (controller.currentStatus.value !=
                                      ProcessingStatus.error &&
                                  controller.currentStatus.value !=
                                      ProcessingStatus.complete)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: TextButton.icon(
                                    onPressed:
                                        controller.continueInBackground,
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Continue in Background',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: controller.goBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.greatGreyOwl),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStepTile extends StatelessWidget {
  final ProcessingStep step;

  const _ProcessingStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _buildStepIcon(),
          const SizedBox(width: 12),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14,
              fontWeight: step.status == ProcessingStepStatus.inProgress
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: step.status == ProcessingStepStatus.completed
                  ? AppColors.success
                  : step.status == ProcessingStepStatus.inProgress
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon() {
    switch (step.status) {
      case ProcessingStepStatus.completed:
        return const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.success,
        );
      case ProcessingStepStatus.inProgress:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.burrowingOwl),
          ),
        );
      case ProcessingStepStatus.failed:
        return const Icon(
          Icons.error_rounded,
          size: 20,
          color: AppColors.error,
        );
      case ProcessingStepStatus.pending:
        return Icon(
          Icons.circle_outlined,
          size: 20,
          color: AppColors.textMuted.withValues(alpha: 0.5),
        );
    }
  }
}
