import 'package:flutter/material.dart';
import '../models/activity.dart';

class SequenceTile extends StatefulWidget {
  final Activity sequence;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final IconData? firstActivityIcon;
  final String? firstActivityThumbnail;

  const SequenceTile({
    super.key,
    required this.sequence,
    required this.onPlay,
    required this.onDelete,
    required this.onEdit,
    this.firstActivityIcon,
    this.firstActivityThumbnail,
  });

  @override
  State<SequenceTile> createState() => _SequenceTileState();
}

class _SequenceTileState extends State<SequenceTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPlay,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cascading black stacked panes effect - shows multiple activities
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(0.15),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          right: 18,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(0.7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 24,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // First activity thumbnail or icon with black outline
                        if (widget.firstActivityThumbnail != null)
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.asset(
                                widget.firstActivityThumbnail!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.blue[50],
                            ),
                            child: Center(
                              child: Icon(
                                widget.firstActivityIcon ??
                                    Icons.fitness_center,
                                size: 32,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isHovered) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.sequence.name,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_isHovered)
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onEdit,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Sequence'),
                              content: const Text(
                                  'Are you sure you want to delete this sequence? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onDelete();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(Icons.delete,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
