import 'package:flutter/material.dart';
import '../models/activity.dart';

class SequenceTile extends StatefulWidget {
  final Activity sequence;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const SequenceTile({
    super.key,
    required this.sequence,
    required this.onPlay,
    required this.onDelete,
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onPlay,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.sequence.icon,
                      size: 24,
                      color: Colors.blue,
                    ),
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
            if (_isHovered)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  onPressed: () {
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
