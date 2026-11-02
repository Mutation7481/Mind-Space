import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class MindSpaceMemoryCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MindSpaceMemoryCard({
    super.key,
    required this.screenshot,
    required this.onTap,
    this.onLongPress,
  });

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    final timeStr = DateFormat('h:mm a').format(dateTime).toLowerCase();
    if (isToday) {
      return 'Today $timeStr';
    } else {
      return '${DateFormat('d/M/yyyy').format(dateTime)}, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (screenshot.title != null && screenshot.title!.trim().isNotEmpty)
        ? screenshot.title!.trim()
        : 'How do I use Mind Space?';
    
    final description = (screenshot.description != null && screenshot.description!.trim().isNotEmpty)
        ? screenshot.description!.trim()
        : 'Mind Space is your ultimate memory manager. It records, summarizes and organizes content...';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Title, Description, Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMindSpaceIcon(size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(screenshot.addedOn),
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Right: Image Thumbnail Preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 85,
                    height: 110,
                    color: const Color(0xFF242426),
                    child: _buildImageThumbnail(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail() {
    if (screenshot.path != null && screenshot.path!.isNotEmpty) {
      final file = File(screenshot.path!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (screenshot.bytes != null) {
      return Image.memory(
        screenshot.bytes!,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: Color(0xFF555555),
        size: 28,
      ),
    );
  }

  Widget _buildMindSpaceIcon({double size = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: size - 4,
          height: size - 4,
          decoration: const BoxDecoration(
            color: Color(0xFF161618),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: size - 7,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
