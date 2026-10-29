import 'package:flutter/material.dart';

import 'models/task_item.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _setDays(int daysFromToday) {
    final now = DateTime.now();
    setState(() {
      _dueDate = DateTime(now.year, now.month, now.day + daysFromToday);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = 'Give the task a title';
      });
      return;
    }
    Navigator.pop(
      context,
      TaskItem(title: title, priority: _priority, dueDate: _dueDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'What needs doing?',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TaskPriority>(
            segments: const [
              ButtonSegment(value: TaskPriority.low, label: Text('Low')),
              ButtonSegment(value: TaskPriority.medium, label: Text('Medium')),
              ButtonSegment(value: TaskPriority.high, label: Text('High')),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Today'),
                onPressed: () => _setDays(0),
              ),
              ActionChip(
                label: const Text('Tomorrow'),
                onPressed: () => _setDays(1),
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Pick date'),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _dueDate == null
                    ? 'No due date'
                    : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              if (_dueDate != null)
                TextButton(
                  onPressed: () => setState(() => _dueDate = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
