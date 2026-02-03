import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../ui/glass_card.dart';
import '../ui/badge_widget.dart';

class _Note {
  final String id;
  final String text;
  final String time;
  final String status;

  _Note({
    required this.id,
    required this.text,
    required this.time,
    required this.status,
  });
}

final _mockNotes = [
  _Note(id: '1', text: 'Buy groceries and plan dinner for Friday night at that new Italian place', time: '2h ago', status: 'parsed'),
  _Note(id: '2', text: 'Weekend hiking trip ideas for Marin county', time: '1d ago', status: 'draft'),
  _Note(id: '3', text: 'Anniversary gift ideas', time: '3d ago', status: 'planned'),
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Set<String> _selectedIds = {};
  bool _isMultiSelect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isMultiSelect)
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.slate800),
                      ),
                    ),
                  if (!_isMultiSelect)
                    const Text(
                      '📝 My Notes',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.slate800),
                    ),
                  if (_isMultiSelect)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.auto_awesome, color: AppTheme.indigo500, size: 20)),
                        IconButton(
                          onPressed: () => setState(() {
                            _isMultiSelect = false;
                            _selectedIds.clear();
                          }),
                          icon: const Icon(Icons.close, size: 20, color: AppTheme.slate600),
                        ),
                      ],
                    ),
                  if (!_isMultiSelect)
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                            ),
                            child: const Text('Filter Notes'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.filter_list, size: 20, color: AppTheme.slate600),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.slate400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _mockNotes.length,
                  itemBuilder: (context, index) {
                    final note = _mockNotes[index];
                    final selected = _selectedIds.contains(note.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: EdgeInsets.fromLTRB(_isMultiSelect ? 48 : 16, 16, 16, 16),
                        onTap: _isMultiSelect
                            ? () => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(note.id);
                                    if (_selectedIds.isEmpty) _isMultiSelect = false;
                                  } else {
                                    _selectedIds.add(note.id);
                                  }
                                })
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isMultiSelect)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.indigo500 : Colors.white,
                                    border: Border.all(color: selected ? AppTheme.indigo500 : AppTheme.slate200),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.text,
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.slate700, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: AppTheme.slate500),
                                      const SizedBox(width: 6),
                                      Text(note.time, style: const TextStyle(fontSize: 12, color: AppTheme.slate500)),
                                      const Spacer(),
                                      if (note.status == 'parsed')
                                        const BadgeWidget(
                                          color: BadgeColor.green,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [Icon(Icons.auto_awesome, size: 10), SizedBox(width: 4), Text('Analyzed')],
                                          ),
                                        ),
                                      if (note.status == 'draft') const BadgeWidget(color: BadgeColor.gray, child: Text('Draft')),
                                      if (note.status == 'planned') const BadgeWidget(color: BadgeColor.blue, child: Text('Planned')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.indigo500,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
