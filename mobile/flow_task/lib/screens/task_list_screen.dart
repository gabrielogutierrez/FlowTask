import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';
import 'settings_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
      super.key,
      required this.tasks,
      required this.userName,
      required this.isDarkMode,
      required this.onThemeToggle,
      required this.onLogout,
  });

  final TaskService tasks;
  final String userName;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bom dia';
    }

    if (hour < 18) {
      return 'Boa tarde';
    }

    return 'Boa noite';
  }
  List<TaskItem> items = [];
List<TaskItem> allItems = [];

bool loading = true;

StreamSubscription<List<TaskItem>>? _tasksSubscription;
Timer? _celebrationTimer;
final ScrollController _scrollController = ScrollController();
bool _showCelebration = false;
bool _fabExtended = true;
bool _showCompletedTasks = true;
DateTime _selectedDate = DateTime.now();
bool _showAllDates = false;
int? _previousPendingTasks;

String currentSearch = '';
bool? completedFilter;
  List<TaskItem> get todayItems {
    final now = DateTime.now();

    return allItems.where((item) {
        if (item.isCompleted || item.dueDate == null) {
          return false;
        }

        final date = item.dueDate!;

        return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    }).toList();
  }
  List<TaskItem> get visibleItems {
    if (completedFilter == null &&
      currentSearch.isEmpty &&
      todayItems.isNotEmpty) {
      final todayIds = todayItems.map((item) => item.id).toSet();

      return items
      .where((item) => !todayIds.contains(item.id))
      .toList();
    }

    return items;
  }
  int get todayTasks {
    final now = DateTime.now();

    return allItems.where((item) {
        if (item.isCompleted || item.dueDate == null) {
          return false;
        }

        final date = item.dueDate!;

        return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    }).length;
  }

  int get overdueTasks {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return allItems.where((item) {
        if (item.isCompleted || item.dueDate == null) {
          return false;
        }

        final due = DateTime(
          item.dueDate!.year,
          item.dueDate!.month,
          item.dueDate!.day,
        );

        return due.isBefore(today);
    }).length;
  }

  int get highPriorityTasks {
    return allItems.where((item) {
        return !item.isCompleted &&
        item.priority == TaskPriority.high;
    }).length;
  }

  int get totalTasks => allItems.length;

  int get completedTasks =>
  allItems.where((item) => item.isCompleted).length;

  int get pendingTasks =>
  totalTasks - completedTasks;

  double get progress =>
  totalTasks == 0
  ? 0
  : completedTasks / totalTasks;

  int get progressPercent =>
  (progress * 100).round();

 @override
void initState() {
  super.initState();

  _scrollController.addListener(_handleScroll);
  _loadTaskPreferences();

  _tasksSubscription = widget.tasks.watch().listen(
    (tasks) {
      if (!mounted) return;

      final newPendingTasks =
          tasks.where((task) => !task.isCompleted).length;

      final shouldCelebrate =
          _previousPendingTasks != null &&
          _previousPendingTasks! > 0 &&
          newPendingTasks == 0;

      _previousPendingTasks = newPendingTasks;

      setState(() {
        allItems = List<TaskItem>.from(tasks);
        sortTasks(allItems);
        _applyFilters();
        loading = false;

        if (shouldCelebrate) {
          _showCelebration = true;
        }
      });

      if (shouldCelebrate) {
        _celebrationTimer?.cancel();
        _celebrationTimer = Timer(
          const Duration(milliseconds: 1300),
          () {
            if (!mounted) return;

            setState(() {
              _showCelebration = false;
            });
          },
        );
      }
    },
    onError: (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    },
  );
}

  void _handleScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final offset = _scrollController.offset;

    if (offset > 70 && _fabExtended) {
      setState(() {
        _fabExtended = false;
      });
    } else if (offset < 24 && !_fabExtended) {
      setState(() {
        _fabExtended = true;
      });
    }
  }

  Future<void> _loadTaskPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final showCompleted = prefs.getBool('showCompletedTasks') ?? true;

    if (!mounted) return;

    setState(() {
      _showCompletedTasks = showCompleted;
      _applyFilters();
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          userName: widget.userName,
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
          onLogout: widget.onLogout,
          tasks: widget.tasks,
        ),
      ),
    );

    if (mounted) {
      await _loadTaskPreferences();
    }
  }

  void sortTasks(List<TaskItem> tasks) {
  final now = DateTime.now();
  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  int group(TaskItem task) {
    if (task.isCompleted) {
      return 4;
    }

    if (task.dueDate == null) {
      return 3;
    }

    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    if (due.isBefore(today)) {
      return 0;
    }

    if (due.isAtSameMomentAs(today)) {
      return 1;
    }

    return 2;
  }

  int priorityValue(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }

  tasks.sort((a, b) {
    final groupComparison =
        group(a).compareTo(group(b));

    if (groupComparison != 0) {
      return groupComparison;
    }

    if (a.dueDate != null && b.dueDate != null) {
      final dateComparison =
          a.dueDate!.compareTo(b.dueDate!);

      if (dateComparison != 0) {
        return dateComparison;
      }
    }

    return priorityValue(a.priority)
        .compareTo(priorityValue(b.priority));
  });
}
  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _weekdayShort(DateTime date) {
    const names = [
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SÁB',
      'DOM',
    ];

    return names[date.weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return names[month - 1];
  }

  String _selectedDateTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return 'Hoje';
    }

    if (selected == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    }

    return '${_selectedDate.day} de ${_monthName(_selectedDate.month)}';
  }

  List<DateTime> get _plannerDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(
      7,
      (index) => today.add(Duration(days: index)),
    );
  }

  List<TaskItem> get plannerVisibleItems {
    final base = visibleItems;

    if (_showAllDates ||
        currentSearch.trim().isNotEmpty ||
        completedFilter != null) {
      return base;
    }

    return base.where((task) {
      final due = task.dueDate;

      if (due == null) {
        return false;
      }

      return _sameDay(due, _selectedDate);
    }).toList();
  }

  int get selectedDatePendingCount {
    return allItems.where((task) {
      final due = task.dueDate;

      return !task.isCompleted &&
          due != null &&
          _sameDay(due, _selectedDate);
    }).length;
  }

  void _applyFilters() {
    var filtered = List<TaskItem>.from(allItems);

    final normalizedSearch = currentSearch.trim().toLowerCase();

    if (normalizedSearch.isNotEmpty) {
      filtered = filtered.where((task) {
        final text =
            '${task.title} ${task.description ?? ''} ${task.category}'
                .toLowerCase();

        return text.contains(normalizedSearch);
      }).toList();
    }

    if (completedFilter != null) {
      filtered = filtered
          .where((task) => task.isCompleted == completedFilter)
          .toList();
    } else if (!_showCompletedTasks) {
      filtered = filtered
          .where((task) => !task.isCompleted)
          .toList();
    }

    sortTasks(filtered);
    items = filtered;
  }

  Future<void> load([String? search]) async {
    if (search != null) {
      currentSearch = search;
    }

    if (!mounted) return;

    setState(() {
      _applyFilters();
      loading = false;
    });
  }

  Future<void> add([DateTime? initialDueDate]) async {
    final prefs = await SharedPreferences.getInstance();

    String title = '';
    String description = '';
    String category = 'Geral';
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate = initialDueDate;
    int reminderHour = prefs.getInt('defaultReminderHour') ?? 9;
    int reminderMinute = prefs.getInt('defaultReminderMinute') ?? 0;

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;
            final theme = Theme.of(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              actionsPadding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.add_task_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova tarefa',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Organize o que precisa ser feito.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ex.: Estudar Flutter',
                        prefixIcon: const Icon(Icons.task_alt_rounded),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        title = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Detalhes da tarefa...',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Geral',
                          child: Text('Geral'),
                        ),
                        DropdownMenuItem(
                          value: 'Trabalho',
                          child: Text('Trabalho'),
                        ),
                        DropdownMenuItem(
                          value: 'Estudos',
                          child: Text('Estudos'),
                        ),
                        DropdownMenuItem(
                          value: 'Pessoal',
                          child: Text('Pessoal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                              category = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<TaskPriority>(
                      initialValue: priority,
                      decoration: InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text('Baixa'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text('Média'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.high,
                          child: Text('Alta'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                              priority = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      tileColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Data de vencimento'),
                      subtitle: Text(
                        dueDate == null
                            ? 'Sem data definida'
                            : '${dueDate!.day.toString().padLeft(2, '0')}/'
                                '${dueDate!.month.toString().padLeft(2, '0')}/'
                                '${dueDate!.year}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );

                        if (selectedDate != null) {
                          setDialogState(() {
                            dueDate = selectedDate;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      enabled: dueDate != null,
                      tileColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: const Icon(Icons.alarm_outlined),
                      title: const Text('Horário do lembrete'),
                      subtitle: Text(
                        dueDate == null
                            ? 'Escolha uma data primeiro'
                            : '${reminderHour.toString().padLeft(2, '0')}:'
                                '${reminderMinute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: dueDate == null
                          ? null
                          : () async {
                              final selectedTime = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay(
                                  hour: reminderHour,
                                  minute: reminderMinute,
                                ),
                              );

                              if (selectedTime != null) {
                                setDialogState(() {
                                  reminderHour = selectedTime.hour;
                                  reminderMinute = selectedTime.minute;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar'),
                  onPressed: () {
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Digite um título para a tarefa.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'title': title,
                        'description':
                        description.isEmpty ? null : description,
                        'category': category,
                        'priority': priority,
                        'dueDate': dueDate,
                        'reminderHour': reminderHour,
                        'reminderMinute': reminderMinute,
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await widget.tasks.create(
      title: result['title'] as String,
      description: result['description'] as String?,
      category: result['category'] as String,
      priority: result['priority'] as TaskPriority,
      dueDate: result['dueDate'] as DateTime?,
      reminderHour: result['reminderHour'] as int,
      reminderMinute: result['reminderMinute'] as int,
    );
  }

  Color priorityColor(TaskPriority priority) {
    switch (priority) {
    case TaskPriority.low:
      return Colors.green;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.high:
      return Colors.red;
    }
  }

  Color priorityBackground(
    BuildContext context,
    TaskPriority priority,
  ) {
    final color = priorityColor(priority);

    return color.withValues(
      alpha: Theme.of(context).brightness ==
      Brightness.dark
      ? 0.18
      : 0.09,
    );
  }
  bool isOverdue(TaskItem item) {
    if (item.dueDate == null || item.isCompleted) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final due = DateTime(
      item.dueDate!.year,
      item.dueDate!.month,
      item.dueDate!.day,
    );

    return due.isBefore(today);
  }
  String priorityLabel(TaskPriority priority) {
    switch (priority) {
    case TaskPriority.low:
      return 'Baixa';
    case TaskPriority.medium:
      return 'Média';
    case TaskPriority.high:
      return 'Alta';
    }
  }

  IconData priorityIcon(TaskPriority priority) {
    switch (priority) {
    case TaskPriority.low:
      return Icons.keyboard_arrow_down;
    case TaskPriority.medium:
      return Icons.remove;
    case TaskPriority.high:
      return Icons.priority_high;
    }
  }

  IconData categoryIcon(String category) {
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

  Color categoryColor(BuildContext context, String category) {
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
  Widget _celebrationOverlay(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget sparkle({
      required Alignment alignment,
      required IconData icon,
      required double size,
      required double angle,
    }) {
      return Align(
        alignment: alignment,
        child: Transform.rotate(
          angle: angle,
          child: Icon(
            icon,
            size: size,
            color: colors.primary,
          ),
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        reverseDuration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.78,
                end: 1,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
        child: !_showCelebration
            ? const SizedBox.shrink(
                key: ValueKey('celebration-hidden'),
              )
            : SizedBox.expand(
                key: const ValueKey('celebration-visible'),
                child: Stack(
                  children: [
                    sparkle(
                      alignment: const Alignment(-0.78, -0.82),
                      icon: Icons.auto_awesome_rounded,
                      size: 26,
                      angle: -0.20,
                    ),
                    sparkle(
                      alignment: const Alignment(0.76, -0.74),
                      icon: Icons.star_rounded,
                      size: 22,
                      angle: 0.18,
                    ),
                    sparkle(
                      alignment: const Alignment(-0.90, -0.38),
                      icon: Icons.star_rounded,
                      size: 16,
                      angle: 0.30,
                    ),
                    sparkle(
                      alignment: const Alignment(0.88, -0.28),
                      icon: Icons.auto_awesome_rounded,
                      size: 24,
                      angle: -0.15,
                    ),
                    sparkle(
                      alignment: const Alignment(-0.70, 0.12),
                      icon: Icons.circle,
                      size: 10,
                      angle: 0,
                    ),
                    sparkle(
                      alignment: const Alignment(0.70, 0.06),
                      icon: Icons.circle,
                      size: 9,
                      angle: 0,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _filterButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.35)
                  : colors.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.09),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color: selected
                          ? colors.primary
                          : colors.onSurface,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';
  }
  Future<void> edit(TaskItem item) async {
    String title = item.title;
    String description = item.description ?? '';
    String category = item.category;
    TaskPriority priority = item.priority;
    DateTime? dueDate = item.dueDate;
    int reminderHour = item.reminderHour;
    int reminderMinute = item.reminderMinute;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;
            final theme = Theme.of(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              actionsPadding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar tarefa',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atualize os detalhes da sua tarefa.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: title,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        prefixIcon: const Icon(Icons.task_alt_rounded),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                            title = value.trim();
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: description,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Geral',
                          child: Text('Geral'),
                        ),
                        DropdownMenuItem(
                          value: 'Trabalho',
                          child: Text('Trabalho'),
                        ),
                        DropdownMenuItem(
                          value: 'Estudos',
                          child: Text('Estudos'),
                        ),
                        DropdownMenuItem(
                          value: 'Pessoal',
                          child: Text('Pessoal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                              category = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<TaskPriority>(
                      initialValue: priority,
                      decoration: InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text('Baixa'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text('Média'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.high,
                          child: Text('Alta'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                              priority = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      tileColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      title: const Text('Data de vencimento'),
                      subtitle: Text(
                        dueDate == null
                            ? 'Sem data definida'
                            : formatDate(dueDate!),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );

                        if (selectedDate != null) {
                          setDialogState(() {
                            dueDate = selectedDate;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      enabled: dueDate != null,
                      tileColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: const Icon(Icons.alarm_outlined),
                      title: const Text('Horário do lembrete'),
                      subtitle: Text(
                        dueDate == null
                            ? 'Escolha uma data primeiro'
                            : '${reminderHour.toString().padLeft(2, '0')}:'
                                '${reminderMinute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: dueDate == null
                          ? null
                          : () async {
                              final selectedTime = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay(
                                  hour: reminderHour,
                                  minute: reminderMinute,
                                ),
                              );

                              if (selectedTime != null) {
                                setDialogState(() {
                                  reminderHour = selectedTime.hour;
                                  reminderMinute = selectedTime.minute;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salvar'),
                  onPressed: title.isEmpty
                  ? null
                  : () {
                    Navigator.pop(
                      dialogContext,
                      {
                        'title': title,
                        'description':
                        description.isEmpty ? null : description,
                        'category': category,
                        'priority': priority,
                        'dueDate': dueDate,
                        'reminderHour': reminderHour,
                        'reminderMinute': reminderMinute,
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await widget.tasks.update(
      id: item.id,
      title: result['title'] as String,
      description: result['description'] as String?,
      category: result['category'] as String,
      priority: result['priority'] as TaskPriority,
      dueDate: result['dueDate'] as DateTime?,
      reminderHour: result['reminderHour'] as int,
      reminderMinute: result['reminderMinute'] as int,
    );
  }

@override
void dispose() {
  _celebrationTimer?.cancel();
  _tasksSubscription?.cancel();
  _scrollController
    ..removeListener(_handleScroll)
    ..dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'FlowTask',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
          ),
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: widget.isDarkMode
                ? 'Modo claro'
                : 'Modo escuro',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: plannerVisibleItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => add(),
              isExtended: _fabExtended,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nova tarefa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tooltip: 'Nova tarefa',
            ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => load(),
            child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 180,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    13,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primaryContainer,
                        colors.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(
                        alpha: 0.42,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${greeting()}, ${widget.userName} 👋',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedDatePendingCount == 0
                                      ? 'Nenhuma tarefa pendente para ${_selectedDateTitle().toLowerCase()}.'
                                      : '$selectedDatePendingCount '
                                          '${selectedDatePendingCount == 1 ? 'tarefa pendente' : 'tarefas pendentes'} para ${_selectedDateTitle().toLowerCase()}.',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(
                                alpha: 0.82,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$progressPercent%',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor:
                              colors.surface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Planejamento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() {
                          _showAllDates = !_showAllDates;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showAllDates
                                  ? Icons.calendar_view_day_rounded
                                  : Icons.view_agenda_outlined,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showAllDates ? 'Por dia' : 'Todas',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 88,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _plannerDays.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final day = _plannerDays[index];
                    final selected =
                        !_showAllDates &&
                        _sameDay(day, _selectedDate);

                    final dayCount = allItems.where((task) {
                      final due = task.dueDate;

                      return !task.isCompleted &&
                          due != null &&
                          _sameDay(due, day);
                    }).length;

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                          _showAllDates = false;
                          completedFilter = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 220,
                        ),
                        width: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            width: _sameDay(
                                      day,
                                      DateTime.now(),
                                    ) &&
                                    !selected
                                ? 1.6
                                : 1,
                            color: selected
                                ? colors.primary
                                : _sameDay(
                                      day,
                                      DateTime.now(),
                                    )
                                    ? colors.primary.withValues(alpha: 0.55)
                                    : colors.outlineVariant,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayShort(day),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${day.day}',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dayCount > 0
                                    ? (selected
                                        ? colors.onPrimary
                                        : colors.primary)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selectedDatePendingCount > 0
                        ? colors.primaryContainer.withValues(alpha: 0.38)
                        : colors.surfaceContainerHighest
                            .withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _showAllDates
                              ? Icons.view_agenda_rounded
                              : Icons.calendar_today_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _showAllDates
                                  ? 'Todas as tarefas'
                                  : _selectedDateTitle(),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _showAllDates
                                  ? '${plannerVisibleItems.length} tarefas no total'
                                  : plannerVisibleItems.isEmpty
                                      ? 'Nenhuma tarefa para este dia'
                                      : '${plannerVisibleItems.length} '
                                          '${plannerVisibleItems.length == 1 ? 'tarefa planejada' : 'tarefas planejadas'}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_showAllDates)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            selectedDatePendingCount == 0
                                ? 'Sem pendências'
                                : '$selectedDatePendingCount '
                                    '${selectedDatePendingCount == 1 ? 'pendente' : 'pendentes'}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  7,
                ),
                child: SearchBar(
                  hintText: 'Buscar tarefas',
                  leading: const Icon(Icons.search),
                  onSubmitted: load,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterButton(
                        context,
                        label: 'Todas',
                        icon: Icons.dashboard_outlined,
                        selected: completedFilter == null,
                        onTap: () {
                          setState(() {
                            completedFilter = null;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _filterButton(
                        context,
                        label: 'Pendentes',
                        icon: Icons.schedule_rounded,
                        selected: completedFilter == false,
                        onTap: () {
                          setState(() {
                            completedFilter = false;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _filterButton(
                        context,
                        label: 'Concluídas',
                        icon: Icons.check_circle_outline_rounded,
                        selected: completedFilter == true,
                        onTap: () {
                          setState(() {
                            completedFilter = true;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              if (loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (plannerVisibleItems.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  34,
                  24,
                  26,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _showAllDates
                              ? Icons.inbox_outlined
                              : Icons.event_available_rounded,
                          size: 34,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showAllDates
                            ? 'Nenhuma tarefa por aqui'
                            : 'Dia livre por aqui ✨',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _showAllDates
                            ? 'Crie uma tarefa e comece a organizar seu planner.'
                            : 'Nada planejado para ${_selectedDateTitle().toLowerCase()}.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {
                          if (_showAllDates) {
                            add();
                          } else {
                            add(_selectedDate);
                          }
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 19,
                        ),
                        label: Text(
                          _showAllDates
                              ? 'Criar tarefa'
                              : 'Adicionar para ${_selectedDateTitle().toLowerCase()}',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plannerVisibleItems.length,
                itemBuilder: (context, index) {
                  final item = plannerVisibleItems[index];

                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.only(right: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) async {
                      await widget.tasks.remove(item.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.28)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withValues(
                                  alpha: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.12
                                      : 0.05,
                                ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => edit(item),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            8,
                            9,
                            8,
                            9,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Checkbox(
                                  key: ValueKey(
                                    'task-check-${item.id}-${item.isCompleted}',
                                  ),
                                  value: item.isCompleted,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (_) async {
                                    await widget.tasks.toggle(item.id);
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: categoryColor(
                                    context,
                                    item.category,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  categoryIcon(item.category),
                                  color: categoryColor(
                                    context,
                                    item.category,
                                  ),
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  decoration: item.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: item.isCompleted
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                      : null,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    if (item.description != null &&
                                        item.description!
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        item.description!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                    if (item.dueDate != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${item.reminderHour.toString().padLeft(2, '0')}:'
                                            '${item.reminderMinute.toString().padLeft(2, '0')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                    ],
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (item.isCompleted)
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            transitionBuilder:
                                                (child, animation) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: ScaleTransition(
                                                  scale: animation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              key: ValueKey(
                                                'completed-${item.id}',
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_rounded,
                                                    size: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Concluída',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: categoryColor(
                                              context,
                                              item.category,
                                            ).withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                categoryIcon(item.category),
                                                size: 15,
                                                color: categoryColor(
                                                  context,
                                                  item.category,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                item.category,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: categoryColor(
                                                        context,
                                                        item.category,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: priorityBackground(
                                              context,
                                              item.priority,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                priorityIcon(item.priority),
                                                size: 15,
                                                color: priorityColor(
                                                  item.priority,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                priorityLabel(item.priority),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: priorityColor(
                                                        item.priority,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (item.dueDate != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOverdue(item)
                                                  ? Colors.red.withValues(
                                                      alpha: 0.09,
                                                    )
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isOverdue(item)
                                                      ? Icons
                                                          .warning_amber_rounded
                                                      : Icons
                                                          .calendar_today_outlined,
                                                  size: 15,
                                                  color: isOverdue(item)
                                                      ? Colors.red
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isOverdue(item)
                                                      ? 'Atrasada • ${formatDate(item.dueDate!)}'
                                                      : formatDate(
                                                          item.dueDate!,
                                                        ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: isOverdue(item)
                                                            ? Colors.red
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (item.dueDate != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.alarm_outlined,
                                                  size: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${item.reminderHour.toString().padLeft(2, '0')}:'
                                                  '${item.reminderMinute.toString().padLeft(2, '0')}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: _celebrationOverlay(context),
          ),
        ],
      ),
    );
  }
}
