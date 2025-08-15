import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityTile extends StatefulWidget {
  final Activity activity;
  final Function(int) onCountChanged;

  const ActivityTile({
    Key? key,
    required this.activity,
    required this.onCountChanged,
  }) : super(key: key);

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.activity.count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              widget.activity.icon,
              size: 24,
              color: Colors.blue,
            ),
            if (_isHovered) ...[
              const SizedBox(height: 4),
              Text(
                widget.activity.name,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: widget.activity.count > 0
                      ? () => widget.onCountChanged(widget.activity.count - 1)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () =>
                      widget.onCountChanged(widget.activity.count + 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
