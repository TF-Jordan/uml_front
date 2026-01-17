import 'package:flutter/material.dart';
import '../constantes/app_colors.dart';
import '../constantes/app_strings.dart';

class UploadZone extends StatelessWidget {
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onFilePicked;

  const UploadZone({
    Key? key,
    required this.isUploading,
    required this.uploadProgress,
    required this.onFilePicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryOrange, width: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.primaryOrange,
          strokeWidth: 2,
          dashWidth: 8,
          dashSpace: 4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
          child: isUploading ? _buildUploadingState() : _buildIdleState(),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          color: AppColors.primaryOrange,
          size: 50,
        ),
        const SizedBox(height: 20),
        const Text(
          AppStrings.dragDropText,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        const Text(AppStrings.orText, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onFilePicked,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            AppStrings.clickToSelect,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primaryOrange),
        const SizedBox(height: 16),
        Text(
          'Téléversement en cours... ${(uploadProgress * 100).toInt()}%',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: uploadProgress,
            backgroundColor: Colors.grey[200],
            color: AppColors.primaryOrange,
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final dashPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(dashPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
