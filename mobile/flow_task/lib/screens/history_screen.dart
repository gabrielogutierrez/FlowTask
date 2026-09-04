import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.tasks,
  });

  final TaskService tasks;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  StreamSubscription<List<TaskItem>>? _subscription;

  List<TaskItem> _completedTasks = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _subscription = widget.tasks.watch().listen(
      (tasks) {
        if (!mounted) return;

        final completed = tasks
            .where((task) => task.isCompleted)
            .toList();

        completed.sort((a, b) {
          final aDate = a.completedAt;
          final bDate = b.completedAt;

          if (aDate == null && bDate == null) {
            return a.title.toLowerCase().compareTo(
                  b.title.toLowerCase(),
                );
          }

          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });

        setState(() {
          _completedTasks = completed;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<TaskItem> get _visibleTasks {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _completedTasks;
    }

    return _completedTasks.where((task) {
      final text =
          '${task.title} ${task.description ?? ''} ${task.category}'
              .toLowerCase();

      return text.contains(query);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} às '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'trabalho':
        return Icons.work_outline_rounded;
      case 'estudos':
        return Icons.school_outlined;
      case 'pessoal':
        return Icons.person_outline_rounded;
      default:
        return Icons.folder_outlined;
    }
  }

  Color _categoryColor(
    BuildContext context,
    String category,
  ) {
    final colors = Theme.of(context).colorScheme;

    switch (category.toLowerCase()) {
      case 'trabalho':
        return colors.primary;
      case 'estudos':
        return colors.tertiary;
      case 'pessoal':
        return colors.secondary;
      default:
        return colors.onSurfaceVariant;
    }
  }

  Future<void> _restoreTask(TaskItem task) async {
    await widget.tasks.toggle(task.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${task.title}" voltou para pendentes.',
        ),
      ),
    );
  }

  Future<void> _deleteTask(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir tarefa?'),
          content: Text(
            'A tarefa "${task.title}" será removida definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.tasks.remove(task.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarefa excluída.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visibleTasks = _visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              10,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primaryContainer,
                    colors.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_completedTasks.length} '
                          '${_completedTasks.length == 1 ? 'tarefa concluída' : 'tarefas concluídas'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Seu arquivo de pequenas vitórias ✨',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              2,
              16,
              12,
            ),
            child: SearchBar(
              hintText: 'Buscar no histórico',
              leading: const Icon(Icons.search_rounded),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : visibleTasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _completedTasks.isEmpty
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_off_rounded,
                                  color: colors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _completedTasks.isEmpty
                                    ? 'Seu histórico ainda está vazio'
                                    : 'Nada encontrado',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _completedTasks.isEmpty
                                    ? 'Quando você concluir tarefas, elas aparecem aqui.'
                                    : 'Tente buscar por outro título ou categoria.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          30,
                        ),
                        itemCount: visibleTasks.length,
                        itemBuilder: (context, index) {
                          final task = visibleTasks[index];
                          final accent = _categoryColor(
                            context,
                            task.category,
                          );

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: colors.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: 0.11,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _categoryIcon(task.category),
                                      color: accent,
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            height: 1.18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.task_alt_rounded,
                                              size: 14,
                                              color: colors.primary,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                task.completedAt == null
                                                    ? 'Concluída antes deste histórico'
                                                    : 'Concluída em ${_formatDateTime(task.completedAt!)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (task.description != null &&
                                            task.description!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            task.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                              color:
                                                  colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 9),
                                        Wrap(
                                          spacing: 7,
                                          runSpacing: 7,
                                          children: [
                                            _HistoryChip(
                                              icon: Icons.check_rounded,
                                              text: 'Concluída',
                                              color: colors.primary,
                                            ),
                                            _HistoryChip(
                                              icon: _categoryIcon(
                                                task.category,
                                              ),
                                              text: task.category,
                                              color: accent,
                                            ),
                                            if (task.dueDate != null)
                                              _HistoryChip(
                                                icon: Icons
                                                    .calendar_today_outlined,
                                                text: _formatDate(
                                                  task.dueDate!,
                                                ),
                                                color:
                                                    colors.onSurfaceVariant,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    tooltip: 'Opções',
                                    onSelected: (value) {
                                      if (value == 'restore') {
                                        _restoreTask(task);
                                      } else if (value == 'delete') {
                                        _deleteTask(task);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      return const [
                                        PopupMenuItem(
                                          value: 'restore',
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.zero,
                                            leading: Icon(
                                              Icons.undo_rounded,
                                            ),
                                            title: Text(
                                              'Voltar para pendentes',
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.zero,
                                            leading: Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                            title: Text(
                                              'Excluir',
                                            ),
                                          ),
                                        ),
                                      ];
                                    },
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
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
