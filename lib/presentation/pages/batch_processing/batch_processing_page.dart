import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/batch_item.dart';
import '../../../domain/entities/processing_type.dart';
import '../../controllers/batch_processing_controller.dart';

class BatchProcessingPage extends GetView<BatchProcessingController> {
  const BatchProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.batchProcessing),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildOverallProgress(),
          Expanded(child: _buildItemList()),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Obx(() {
      final current = controller.currentIndex.value + 1;
      final total = controller.items.length;
      final progress = controller.overallProgress.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border(
            bottom: BorderSide(
              color: AppColors.greatGreyOwl.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.isProcessing.value
                      ? '${AppStrings.processingXofY} $current of $total'
                      : AppStrings.batchComplete,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.burrowingOwl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.greatGreyOwl.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  controller.isProcessing.value
                      ? AppColors.burrowingOwl
                      : AppColors.success,
                ),
              ),
            ),
            if (controller.isProcessing.value) ...[
              const SizedBox(height: 8),
              Obx(() => Text(
                    controller.currentStepDescription.value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  )),
            ],
            if (!controller.isProcessing.value) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _summaryChip(
                    Icons.check_circle_rounded,
                    '${controller.completedCount} ${AppStrings.succeeded}',
                    AppColors.success,
                  ),
                  const SizedBox(width: 16),
                  if (controller.failedCount > 0)
                    _summaryChip(
                      Icons.error_rounded,
                      '${controller.failedCount} ${AppStrings.failed}',
                      AppColors.error,
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemList() {
    return Obx(() => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.items.length,
          itemBuilder: (context, index) {
            return _buildItemTile(index);
          },
        ));
  }

  Widget _buildItemTile(int index) {
    return Obx(() {
      final item = controller.items[index];
      final isCurrentItem =
          controller.isProcessing.value && controller.currentIndex.value == index;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentItem
              ? AppColors.burrowingOwl.withValues(alpha: 0.08)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentItem
                ? AppColors.burrowingOwl.withValues(alpha: 0.3)
                : AppColors.greatGreyOwl.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.file(
                  File(item.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.bgSecondary,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title and status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Image ${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.detectedType != null) ...[
                        const SizedBox(width: 8),
                        _typeBadge(item.detectedType!),
                      ],
                    ],
                  ),
                  if (item.status == BatchItemStatus.processing) ...[
                    const SizedBox(height: 6),
                    Obx(() => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: controller.currentItemProgress.value,
                            minHeight: 4,
                            backgroundColor:
                                AppColors.greatGreyOwl.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.burrowingOwl),
                          ),
                        )),
                  ],
                  if (item.status == BatchItemStatus.failed &&
                      item.error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.error!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status icon
            _statusIcon(item.status),
          ],
        ),
      );
    });
  }

  Widget _typeBadge(ProcessingType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: type == ProcessingType.face
            ? const Color(0xFF69F0AE).withValues(alpha: 0.15)
            : const Color(0xFF42A5F5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type == ProcessingType.face ? 'Face' : 'Document',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: type == ProcessingType.face
              ? const Color(0xFF69F0AE)
              : const Color(0xFF42A5F5),
        ),
      ),
    );
  }

  Widget _statusIcon(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.pending:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.greatGreyOwl.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        );
      case BatchItemStatus.processing:
        return const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.burrowingOwl),
          ),
        );
      case BatchItemStatus.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        );
      case BatchItemStatus.failed:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        );
    }
  }

  Widget _buildBottomActions() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(16),
          child: controller.isProcessing.value
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.goToBackground,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(AppStrings.continueInBackground),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.clearCompleted,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.viewResults,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text(AppStrings.viewResults),
                      ),
                    ),
                  ],
                ),
        ));
  }
}
