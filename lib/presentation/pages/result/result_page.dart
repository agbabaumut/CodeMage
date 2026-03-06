import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../controllers/result_controller.dart';

class ResultPage extends GetView<ResultController> {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isFaceResult
              ? AppStrings.faceResult
              : AppStrings.documentResult,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: controller.done,
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                final box = ctx.findRenderObject() as RenderBox;
                final rect = box.localToGlobal(Offset.zero) & box.size;
                controller.shareResult(rect);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: controller.isFaceResult
                ? _buildFaceResult()
                : _buildDocumentResult(),
          ),

          _buildMetadataCard(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (controller.isDocumentResult && controller.result.pdfPath != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.openPdf,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.greatGreyOwl),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text(AppStrings.openPdf),
                    ),
                  ),
                if (controller.isDocumentResult) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.done,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(AppStrings.done),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceResult() {
    return _BeforeAfterSlider(
      beforePath: controller.result.originalPath,
      afterPath: controller.result.processedPath,
    );
  }

  Widget _buildDocumentResult() {
    return DefaultTabController(
      length: controller.hasExtractedText ? 2 : 1,
      child: Column(
        children: [
          if (controller.hasExtractedText)
            TabBar(
              indicatorColor: AppColors.burrowingOwl,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Result'),
                Tab(text: 'Extracted Text'),
              ],
            ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(controller.result.processedPath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (controller.hasExtractedText)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              onPressed: controller.copyTextToClipboard,
                              tooltip: 'Copy text',
                            ),
                          ],
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.greatGreyOwl.withValues(alpha: 0.3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                controller.result.extractedText ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: AppColors.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _MetadataChip(
            icon: Icons.category_rounded,
            label: controller.result.type.displayName,
          ),
          _MetadataChip(
            icon: Icons.timer_rounded,
            label: FileUtils.formatDuration(controller.result.processingDurationMs),
          ),
          _MetadataChip(
            icon: Icons.storage_rounded,
            label: FileUtils.formatFileSize(controller.result.fileSizeBytes),
          ),
          if (controller.isFaceResult)
            _MetadataChip(
              icon: Icons.face_rounded,
              label: '${controller.result.faceCount} face(s)',
            ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.tawnyOwl),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BeforeAfterSlider extends StatefulWidget {
  final String beforePath;
  final String afterPath;

  const _BeforeAfterSlider({
    required this.beforePath,
    required this.afterPath,
  });

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _dividerPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dividerPosition =
                  (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.05, 0.95);
            });
          },
          child: Stack(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Image.file(
                  File(widget.afterPath),
                  fit: BoxFit.contain,
                ),
              ),

              ClipRect(
                clipper: _LeftClipper(_dividerPosition * constraints.maxWidth),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Image.file(
                    File(widget.beforePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Positioned(
                left: _dividerPosition * constraints.maxWidth - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white,
                ),
              ),

              Positioned(
                left: _dividerPosition * constraints.maxWidth - 20,
                top: constraints.maxHeight / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.bgPrimary,
                    size: 22,
                  ),
                ),
              ),

              Positioned(
                left: 12,
                top: 12,
                child: _label(AppStrings.before),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _label(AppStrings.after),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double width;

  _LeftClipper(this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.width != width;
}
