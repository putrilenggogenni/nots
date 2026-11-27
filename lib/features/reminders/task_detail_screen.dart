import 'package:material_ui/material_ui.dart';

import '../tasks/task_model.dart';
import '../tasks/task_repository.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _repo = TaskRepository();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  DateTime? _due;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _notes = TextEditingController(text: widget.task.notes ?? '');
    _due = widget.task.dueAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final base = _due ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(
      () => _due = DateTime(d.year, d.month, d.day, base.hour, base.minute),
    );
  }

  Future<void> _pickTime() async {
    final base = _due ?? DateTime.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (t == null) return;
    setState(
      () => _due = DateTime(base.year, base.month, base.day, t.hour, t.minute),
    );
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMsg)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Judul wajib diisi')));
      return Future.value();
    }
    return _run(
      () => _repo.updateTask(
        widget.task.id,
        title: _title.text.trim(),
        dueAt: _due,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
      'Perubahan disimpan',
    );
  }

  Future<void> _complete() => _run(
    () => _repo.setDone(widget.task.id, !widget.task.isDone),
    widget.task.isDone ? 'Ditandai belum selesai' : 'Ditandai selesai',
  );

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: const Text(
          'Pengingat ini akan dihapus dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _repo.deleteTask(widget.task.id), 'Pengingat dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _due;
    final dateText = d == null
        ? 'Pilih tanggal'
        : '${d.day}/${d.month}/${d.year}';
    final timeText = d == null
        ? 'Pilih jam'
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengingat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.task.courseName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Mata kuliah: ${widget.task.courseName}'),
            ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Judul pengingat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(dateText),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(timeText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.task.rawText != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Teks asli'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(widget.task.rawText!),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Simpan perubahan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _complete,
            child: Text(
              widget.task.isDone ? 'Tandai belum selesai' : 'Selesai',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _delete,
            child: const Text(
              'Hapus pengingat',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
