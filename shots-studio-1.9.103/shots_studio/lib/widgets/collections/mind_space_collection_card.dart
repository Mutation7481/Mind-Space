import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class MindSpaceCollectionCard extends StatelessWidget {
  final Collection collection;
  final List<Screenshot> screenshots;
  final VoidCallback onTap;

  const MindSpaceCollectionCard({
    super.key,
    required this.collection,
    required this.screenshots,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Find up to 1 preview screenshot for this collection
    final matchingScreenshots = screenshots.where(
      (s) => collection.screenshotIds.contains(s.id) && !s.isDeleted,
    ).toList();

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.screenshotCount} memories',
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Inner preview box
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    color: const Color(0xFF222225),
                    child: matchingScreenshots.isNotEmpty
                        ? _buildPreviewImage(matchingScreenshots.first)
                        : const Center(
                            child: Icon(
                              Icons.psychology_outlined,
                              size: 32,
                              color: Color(0xFF3E3E42),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage(Screenshot screenshot) {
    if (screenshot.path != null && screenshot.path!.isNotEmpty) {
      return Image.file(
        File(screenshot.path!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.psychology_outlined, size: 28, color: Color(0xFF3E3E42)),
        ),
      );
    } else if (screenshot.bytes != null) {
      return Image.memory(
        screenshot.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.psychology_outlined, size: 28, color: Color(0xFF3E3E42)),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.psychology_outlined, size: 28, color: Color(0xFF3E3E42)),
    );
  }
}

class MindSpaceCreateCollectionCard extends StatelessWidget {
  final VoidCallback onTap;

  const MindSpaceCreateCollectionCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF242428),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF757575),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
