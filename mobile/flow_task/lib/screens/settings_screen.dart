import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/task_service.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onLogout,
    required this.tasks,
  });

  final String userName;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final TaskService tasks;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _reminderHour = 9;
  int _reminderMinute = 0;
  String? _profileImagePath;
  bool _showCompletedTasks = true;
  bool _loading = true;

  final ImagePicker _imagePicker = ImagePicker();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _reminderHour = prefs.getInt('defaultReminderHour') ?? 9;
      _reminderMinute = prefs.getInt('defaultReminderMinute') ?? 0;
      _profileImagePath = prefs.getString('profileImagePath');
      _showCompletedTasks = prefs.getBool('showCompletedTasks') ?? true;
      _loading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', image.path);

    if (!mounted) return;

    setState(() {
      _profileImagePath = image.path;
    });
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImagePath');

    if (!mounted) return;

    setState(() {
      _profileImagePath = null;
    });
  }

  Future<void> _showPhotoOptions() async {
    final colors = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher foto da galeria'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickProfileImage();
                  },
                ),
                if (_profileImagePath != null)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                    ),
                    title: Text(
                      'Remover foto',
                      style: TextStyle(
                        color: colors.error,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setShowCompletedTasks(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCompletedTasks', value);

    if (!mounted) return;

    setState(() {
      _showCompletedTasks = value;
    });
  }

  Future<void> _chooseReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderHour,
        minute: _reminderMinute,
      ),
    );

    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('defaultReminderHour', selected.hour);
    await prefs.setInt('defaultReminderMinute', selected.minute);

    if (!mounted) return;

    setState(() {
      _reminderHour = selected.hour;
      _reminderMinute = selected.minute;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Horário padrão do lembrete atualizado.'),
      ),
    );
  }

  String get _formattedReminderTime {
    return '${_reminderHour.toString().padLeft(2, '0')}:'
        '${_reminderMinute.toString().padLeft(2, '0')}';
  }

  String get _initial {
    final name = widget.userName.trim();

    if (name.isEmpty) return 'U';

    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você poderá entrar novamente usando seu e-mail e senha.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.of(context).pop();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final email = _user?.email ?? 'E-mail não disponível';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil e configurações',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                30,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
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
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.outlineVariant,
                                  width: 2,
                                ),
                                image: _profileImagePath != null
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(_profileImagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: _profileImagePath == null
                                  ? Text(
                                      _initial,
                                      style:
                                          theme.textTheme.headlineSmall?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: colors.onPrimary,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        colors.surface.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Conta FlowTask',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showPhotoOptions,
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _profileImagePath == null
                                        ? 'Adicionar foto'
                                        : 'Alterar foto',
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    visualDensity: VisualDensity.compact,
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

                const SizedBox(height: 24),

                Text(
                  'Preferências',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                _SettingsCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        secondary: _SettingsIcon(
                          icon: widget.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                        ),
                        title: const Text(
                          'Modo escuro',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          widget.isDarkMode
                              ? 'Tema escuro ativado'
                              : 'Tema claro ativado',
                        ),
                        value: widget.isDarkMode,
                        onChanged: (_) {
                          widget.onThemeToggle();
                          setState(() {});
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        secondary: const _SettingsIcon(
                          icon: Icons.visibility_outlined,
                        ),
                        title: const Text(
                          'Mostrar tarefas concluídas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _showCompletedTasks
                              ? 'Concluídas aparecem na lista principal'
                              : 'Concluídas ficam ocultas na lista principal',
                        ),
                        value: _showCompletedTasks,
                        onChanged: _setShowCompletedTasks,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        leading: const _SettingsIcon(
                          icon: Icons.alarm_outlined,
                        ),
                        title: const Text(
                          'Horário padrão do lembrete',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Usado ao criar novas tarefas',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formattedReminderTime,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: _chooseReminderTime,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Organização',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                _SettingsCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: const _SettingsIcon(
                      icon: Icons.history_rounded,
                    ),
                    title: const Text(
                      'Histórico de tarefas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Veja, restaure ou exclua tarefas concluídas',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(
                            tasks: widget.tasks,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Conta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                _SettingsCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: _SettingsIcon(
                      icon: Icons.logout_rounded,
                      color: colors.error,
                    ),
                    title: Text(
                      'Sair da conta',
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Encerrar sua sessão neste dispositivo',
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.error,
                    ),
                    onTap: _confirmLogout,
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 28,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'FlowTask',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organize seu dia com leveza ✨',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    this.color,
  });

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = color ?? colors.primary;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }
}
