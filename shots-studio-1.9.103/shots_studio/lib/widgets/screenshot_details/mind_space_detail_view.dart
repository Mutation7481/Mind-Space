import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/services/haptic_service.dart';

class MindSpaceDetailView extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final TextEditingController notesController;
  final FocusNode notesFocusNode;
  final bool isProcessingAI;
  final VoidCallback onOpenFullScreen;
  final VoidCallback onTriggerAI;
  final VoidCallback onNotesSaved;

  const MindSpaceDetailView({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.notesController,
    required this.notesFocusNode,
    this.isProcessingAI = false,
    required this.onOpenFullScreen,
    required this.onTriggerAI,
    required this.onNotesSaved,
  });

  @override
  State<MindSpaceDetailView> createState() => _MindSpaceDetailViewState();
}

class _MindSpaceDetailViewState extends State<MindSpaceDetailView> {
  int? _thumbFeedback; // 1 for up, -1 for down

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, h:mm a').format(dateTime).toLowerCase();
  }

  String _getCollectionName() {
    if (widget.screenshot.collectionIds.isNotEmpty) {
      final matched = widget.allCollections.where(
        (c) => widget.screenshot.collectionIds.contains(c.id),
      );
      if (matched.isNotEmpty && matched.first.name != null) {
        return matched.first.name!;
      }
    }
    return 'Mind Space';
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.screenshot.title != null && widget.screenshot.title!.trim().isNotEmpty)
        ? widget.screenshot.title!.trim()
        : 'How do I use Mind Space?';

    final description = (widget.screenshot.description != null && widget.screenshot.description!.trim().isNotEmpty)
        ? widget.screenshot.description!.trim()
        : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Screenshot displayed on top
          _buildScreenshotTopPreview(),
          const SizedBox(height: 20),

          // 2. Large Bold Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),

          // 3. Sub-header: Colorful icon + Collection + Timestamp
          Row(
            children: [
              _buildMindSpaceIcon(size: 18),
              const SizedBox(width: 8),
              Text(
                _getCollectionName(),
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDateTime(widget.screenshot.addedOn),
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 4. AI summary section
          Row(
            children: [
              _buildAIFlowerIcon(),
              const SizedBox(width: 10),
              const Text(
                'AI summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (widget.isProcessingAI) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // AI Summary Content
          if (widget.isProcessingAI)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF4285F4), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analyzing memory and generating summary with bullet points...',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else if (description.isNotEmpty)
            _buildFormattedSummary(description)
          else
            _buildEmptySummaryPrompt(),

          const SizedBox(height: 16),

          // Thumbs Feedback
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _thumbFeedback == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 20,
                  color: _thumbFeedback == 1 ? Colors.white : const Color(0xFF757575),
                ),
                onPressed: () {
                  HapticService.lightImpact();
                  setState(() {
                    _thumbFeedback = _thumbFeedback == 1 ? null : 1;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  _thumbFeedback == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 20,
                  color: _thumbFeedback == -1 ? Colors.white : const Color(0xFF757575),
                ),
                onPressed: () {
                  HapticService.lightImpact();
                  setState(() {
                    _thumbFeedback = _thumbFeedback == -1 ? null : -1;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF262629), height: 1),
          const SizedBox(height: 24),

          // 5. Remarks section
          const Text(
            'Remarks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Note input field card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF757575),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.notesController,
                    focusNode: widget.notesFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Add a note to this memory',
                      hintStyle: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (text) {
                      widget.screenshot.notes = text;
                    },
                    onEditingComplete: () {
                      widget.onNotesSaved();
                      widget.notesFocusNode.unfocus();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Footer Notice
          const Center(
            child: Text(
              'Generated by AI. For reference only.',
              style: TextStyle(
                color: Color(0xFF636366),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotTopPreview() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onOpenFullScreen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 260),
          color: const Color(0xFF161618),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildImage(),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.screenshot.path != null && widget.screenshot.path!.isNotEmpty) {
      return Image.file(
        File(widget.screenshot.path!),
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    } else if (widget.screenshot.bytes != null) {
      return Image.memory(
        widget.screenshot.bytes!,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      color: const Color(0xFF1A1A1D),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF6E6E73), size: 40),
      ),
    );
  }

  Widget _buildFormattedSummary(String text) {
    // Split text into paragraphs
    final paragraphs = text.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final trimmed = para.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();

        // Check if paragraph looks like a heading (short, no punctuation at end)
        final isHeading = trimmed.length < 40 &&
            !trimmed.startsWith('•') &&
            !trimmed.startsWith('-') &&
            !trimmed.endsWith('.');

        if (isHeading) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          );
        }

        // Regular paragraph or bullet points
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            trimmed,
            style: const TextStyle(
              color: Color(0xFFD1D1D6),
              fontSize: 15,
              height: 1.45,
              letterSpacing: 0.1,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptySummaryPrompt() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTriggerAI,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            _buildAIFlowerIcon(),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to generate AI Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Summarize text, key points and to-dos from this screenshot',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF757575),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFlowerIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFEA4335),
            Color(0xFFFBBC05),
            Color(0xFF34A853),
            Color(0xFF4285F4),
            Color(0xFFA142F4),
            Color(0xFFEA4335),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF101012),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMindSpaceIcon({double size = 18}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
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
            color: Color(0xFF101012),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.psychology,
            size: size - 7,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
