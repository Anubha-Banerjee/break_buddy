import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_sequence.dart';

class SequenceEditorDialog extends StatefulWidget {
  final ActivitySequence sequence;
  final List<Activity> availableActivities;
  final Function(List<Activity>) onSave;

  const SequenceEditorDialog({
    Key? key,
    required this.sequence,
    required this.availableActivities,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SequenceEditorDialog> createState() => _SequenceEditorDialogState();
}

class _SequenceEditorDialogState extends State<SequenceEditorDialog> {
  late List<Activity> selectedActivities;
  late List<Activity> availableActivities;

  @override
  void initState() {
    super.initState();
    selectedActivities = List.from(widget.sequence.activities);
    // Filter out sequence activities from the available list
    availableActivities = widget.availableActivities
        .where((a) => !a.id.startsWith('seq_'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit ${widget.sequence.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Available activities on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Activities',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ListView.builder(
                              itemCount: availableActivities.length,
                              itemBuilder: (context, index) {
                                final activity = availableActivities[index];
                                final isSelected = selectedActivities.any(
                                  (a) => a.id == activity.id,
                                );
                                return ListTile(
                                  leading: Icon(activity.icon),
                                  title: Text(activity.name),
                                  tileColor: isSelected
                                      ? Colors.blue[100]
                                      : Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedActivities.removeWhere(
                                          (a) => a.id == activity.id,
                                        );
                                      } else {
                                        selectedActivities.add(
                                          activity.copyWith(count: 1),
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Selected activities on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Activities',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: selectedActivities.isEmpty
                                ? Center(
                                    child: Text(
                                      'No activities selected',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : ReorderableListView(
                                    onReorder: (oldIndex, newIndex) {
                                      setState(() {
                                        if (oldIndex < newIndex) {
                                          newIndex -= 1;
                                        }
                                        final item = selectedActivities
                                            .removeAt(oldIndex);
                                        selectedActivities.insert(
                                            newIndex, item);
                                      });
                                    },
                                    children: [
                                      for (int i = 0;
                                          i < selectedActivities.length;
                                          i++)
                                        ListTile(
                                          key: ValueKey(
                                            selectedActivities[i].id,
                                          ),
                                          leading: Icon(
                                            Icons.drag_handle,
                                            color: Colors.grey,
                                          ),
                                          title: Text(
                                            selectedActivities[i].name,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  setState(() {
                                                    if (selectedActivities[i].count > 1) {
                                                      selectedActivities[i] =
                                                          selectedActivities[i]
                                                              .copyWith(
                                                            count:
                                                                selectedActivities[
                                                                            i]
                                                                        .count -
                                                                    1,
                                                          );
                                                    } else {
                                                      // Remove activity if count is 1
                                                      selectedActivities.removeAt(i);
                                                    }
                                                  });
                                                },
                                                iconSize: 18,
                                              ),
                                              Container(
                                                width: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${selectedActivities[i].count}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  setState(() {
                                                    selectedActivities[i] =
                                                        selectedActivities[i]
                                                            .copyWith(
                                                          count:
                                                              selectedActivities[
                                                                          i]
                                                                      .count +
                                                                  1,
                                                        );
                                                  });
                                                },
                                                iconSize: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: selectedActivities.isEmpty
                      ? null
                      : () {
                          widget.onSave(selectedActivities);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
