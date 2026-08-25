import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.onLogout,
  });

  final TaskService tasks;
  final VoidCallback onLogout;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<TaskItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load([String search = '']) async {
    setState(() => loading = true);
    try {
      items = await widget.tasks.list(search: search);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova tarefa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: Estudar Flutter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty) {
      await widget.tasks.create(title);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        actions: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Buscar tarefas',
              leading: const Icon(Icons.search),
              onSubmitted: load,
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(
                        child: Text('Tudo em dia! Adicione uma tarefa.'),
                      )
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              background: Container(color: Colors.red),
                              onDismissed: (_) async {
                                await widget.tasks.remove(item.id);
                              },
                              child: CheckboxListTile(
                                value: item.isCompleted,
                                onChanged: (_) async {
                                  await widget.tasks.toggle(item.id);
                                  await load();
                                },
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.category} • ${item.priority.name}',
                                ),
                                secondary: Icon(
                                  item.priority == TaskPriority.high
                                      ? Icons.priority_high
                                      : Icons.flag_outlined,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
