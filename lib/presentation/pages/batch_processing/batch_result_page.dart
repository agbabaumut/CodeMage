import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/batch_item.dart';
import '../../../domain/entities/processing_type.dart';
import '../../routes/app_routes.dart';

class BatchResultPage extends StatelessWidget {
  const BatchResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Get.arguments as List<BatchItem>;
    final completedItems =
        items.where((i) => i.status == BatchItemStatus.completed).toList();
    final failedItems =
        items.where((i) => i.status == BatchItemStatus.failed).toList();

    final totalDurationMs = completedItems.fold<int>(
      0,
      (sum, item) => sum + (item.historyEntry?.processingDurationMs ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.batchResults),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Get.offAllNamed(AppRoutes.main),
        ),
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(
            completedCount: completedItems.length,
            failedCount: failedItems.length,
            totalDurationMs: totalDurationMs,
          ),

          // Results grid
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (completedItems.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildResultCard(completedItems[index]),
                        childCount: completedItems.length,
                      ),
                    ),
                  ),
                ],
                if (failedItems.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Failed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildFailedCard(failedItems[index], index),
                        childCount: failedItems.length,
                      ),
                    ),
                  ),
                ],
                const SliverPadding(
                    padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),

          // Done button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.main),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text(AppStrings.done),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int completedCount,
    required int failedCount,
    required int totalDurationMs,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greatGreyOwl.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            value: '$completedCount',
            label: AppStrings.succeeded,
          ),
          if (failedCount > 0)
            _SummaryItem(
              icon: Icons.error_rounded,
              color: AppColors.error,
              value: '$failedCount',
              label: AppStrings.failed,
            ),
          _SummaryItem(
            icon: Icons.timer_rounded,
            color: AppColors.tawnyOwl,
            value: FileUtils.formatDuration(totalDurationMs),
            label: 'Total time',
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BatchItem item) {
    final entry = item.historyEntry!;

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.historyDetail, arguments: entry);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.greatGreyOwl.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(entry.thumbnailPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.bgSecondary,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.type == ProcessingType.face
                            ? 'Face'
                            : 'Document',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    entry.type == ProcessingType.face
                        ? Icons.face_rounded
                        : Icons.description_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.type.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedCard(BatchItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.file(
                File(item.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.bgSecondary,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                if (item.error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.error!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
