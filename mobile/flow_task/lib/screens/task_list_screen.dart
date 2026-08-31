import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';

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
    load();
  }

  Future<void> load([String? search]) async {
    if (search != null) {
      currentSearch = search;
    }

    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final results = await Future.wait([
          widget.tasks.list(
            search: currentSearch,
            completed: completedFilter,
          ),
          widget.tasks.list(),
      ]);

      items = results[0];
      allItems = results[1];
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> add() async {
    String title = '';
    String description = '';
    String category = 'Geral';
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova tarefa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ex.: Estudar Flutter',
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                      onChanged: (value) {
                        title = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Detalhes da tarefa...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.folder_outlined),
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
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(Icons.flag_outlined),
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
                      contentPadding: EdgeInsets.zero,
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
                          firstDate: DateTime.now(),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
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
                      },
                    );
                  },
                  child: const Text('Adicionar'),
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
    );

    await load();
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
  Widget _statCard(
    BuildContext context, {
      required IconData icon,
      required String label,
      required int value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
        .colorScheme
        .surface
        .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context)
            .colorScheme
            .primary,
          ),

          const SizedBox(height: 7),

          Text(
            '$value',
            style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
            .textTheme
            .bodySmall,
          ),
        ],
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar tarefa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        prefixIcon: Icon(Icons.task_alt),
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
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      onChanged: (value) {
                        description = value.trim();
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.folder_outlined),
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
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(Icons.flag_outlined),
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
                      contentPadding: EdgeInsets.zero,
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
                          firstDate: DateTime.now(),
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
                FilledButton(
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
                      },
                    );
                  },
                  child: const Text('Salvar'),
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
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${greeting()}, ${widget.userName} 👋',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'Minhas tarefas',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
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
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: RefreshIndicator(
        onRefresh: () => load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 110,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                    borderRadius: BorderRadius.circular(24),
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
                                  'Seu progresso',
                                  style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalTasks == 0
                                  ? 'Crie sua primeira tarefa ✨'
                                  : pendingTasks == 0
                                  ? 'Tudo concluído! ✨'
                                  : '$pendingTasks '
                                  '${pendingTasks == 1 ? 'tarefa pendente' : 'tarefas pendentes'}',
                                  style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                              .colorScheme
                              .surface,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$progressPercent%',
                              style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.65),
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 17,
                                      ),
                                      SizedBox(width: 6),
                                      Text('Pendentes'),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$pendingTasks',
                                    style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.65),
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 17,
                                      ),
                                      SizedBox(width: 6),
                                      Text('Concluídas'),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$completedTasks',
                                    style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.today_outlined,
                              label: 'Hoje',
                              value: todayTasks,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.warning_amber_rounded,
                              label: 'Atrasadas',
                              value: overdueTasks,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.priority_high,
                              label: 'Alta',
                              value: highPriorityTasks,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  10,
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
                      ChoiceChip(
                        label: const Text('Todas'),
                        avatar: const Icon(
                          Icons.list_alt,
                          size: 18,
                        ),
                        selected: completedFilter == null,
                        onSelected: (_) {
                          setState(() {
                              completedFilter = null;
                          });

                          load();
                        },
                      ),

                      const SizedBox(width: 8),

                      ChoiceChip(
                        label: const Text('Pendentes'),
                        avatar: const Icon(
                          Icons.schedule,
                          size: 18,
                        ),
                        selected: completedFilter == false,
                        onSelected: (_) {
                          setState(() {
                              completedFilter = false;
                          });

                          load();
                        },
                      ),

                      const SizedBox(width: 8),

                      ChoiceChip(
                        label: const Text('Concluídas'),
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        selected: completedFilter == true,
                        onSelected: (_) {
                          setState(() {
                              completedFilter = true;
                          });

                          load();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              if (completedFilter == null &&
                currentSearch.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Para hoje',
                          style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (todayItems.isNotEmpty)
                      Text(
                        '${todayItems.length} '
                        '${todayItems.length == 1 ? 'tarefa' : 'tarefas'}',
                        style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                          .colorScheme
                          .primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (todayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    6,
                    16,
                    14,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context)
                          .colorScheme
                          .primary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Nada programado para hoje.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (todayItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    14,
                  ),
                  child: Column(
                    children: todayItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: priorityColor(item.priority)
                              .withValues(alpha: 0.35),
                            ),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: item.isCompleted,
                              onChanged: (_) async {
                                await widget.tasks.toggle(item.id);
                                await load();
                              },
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  priorityIcon(item.priority),
                                  size: 16,
                                  color: priorityColor(item.priority),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  priorityLabel(item.priority),
                                  style: TextStyle(
                                    color: priorityColor(item.priority),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () => edit(item),
                          ),
                        );
                    }).toList(),
                  ),
                ),
              ],
              if (loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visibleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Tudo em dia! Adicione uma tarefa.',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];

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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) async {
                      await widget.tasks.remove(item.id);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      color: item.isCompleted
                      ? Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withValues(alpha: 0.55)
                      : Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => edit(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: item.isCompleted,
                                onChanged: (_) async {
                                  await widget.tasks.toggle(item.id);
                                  await load();
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
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
                                    if (item.description != null &&
                                      item.description!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Chip(
                                          avatar: const Icon(
                                            Icons.folder_outlined,
                                            size: 17,
                                          ),
                                          label: Text(item.category),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Chip(
                                          avatar: Icon(
                                            priorityIcon(item.priority),
                                            size: 17,
                                            color: priorityColor(item.priority),
                                          ),
                                          label: Text(
                                            priorityLabel(item.priority),
                                            style: TextStyle(
                                              color: priorityColor(item.priority),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          backgroundColor: priorityBackground(
                                            context,
                                            item.priority,
                                          ),
                                          side: BorderSide(
                                            color: priorityColor(item.priority)
                                            .withValues(alpha: 0.35),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        if (item.dueDate != null)
                                        Chip(
                                          avatar: Icon(
                                            isOverdue(item)
                                            ? Icons.warning_amber_rounded
                                            : Icons.calendar_today_outlined,
                                            size: 16,
                                            color: isOverdue(item)
                                            ? Colors.red
                                            : null,
                                          ),
                                          label: Text(
                                            isOverdue(item)
                                            ? 'Atrasada • ${formatDate(item.dueDate!)}'
                                            : formatDate(item.dueDate!),
                                            style: TextStyle(
                                              color: isOverdue(item)
                                              ? Colors.red
                                              : null,
                                              fontWeight: isOverdue(item)
                                              ? FontWeight.w600
                                              : null,
                                            ),
                                          ),
                                          backgroundColor: isOverdue(item)
                                          ? Colors.red.shade50
                                          : null,
                                          side: isOverdue(item)
                                          ? BorderSide(
                                            color: Colors.red.withValues(
                                              alpha: 0.35,
                                            ),
                                          )
                                          : null,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
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
    );
  }
}
