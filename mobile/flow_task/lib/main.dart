import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'screens/auth_screen.dart';
import 'screens/task_list_screen.dart';
import 'services/auth_service.dart' as auth_service;
import 'services/task_service.dart';

void main() {
  runApp(const FlowTaskApp());
}

class FlowTaskApp extends StatefulWidget {
  const FlowTaskApp({super.key});

  @override
  State<FlowTaskApp> createState() => _FlowTaskAppState();
}

class _FlowTaskAppState extends State<FlowTaskApp> {
  final api = ApiClient();

  late final auth = auth_service.AuthService(api);
  late final tasks = TaskService(api);

  bool? signedIn;
bool darkMode = false;

  @override
void initState() {
  super.initState();
  restoreApp();
}

Future<void> restoreApp() async {
  final prefs = await SharedPreferences.getInstance();
  final isSignedIn = await auth.restore();

  if (!mounted) return;

  setState(() {
    signedIn = isSignedIn;
    darkMode = prefs.getBool('darkMode') ?? false;
  });
}

Future<void> toggleTheme() async {
  final newValue = !darkMode;

  setState(() {
    darkMode = newValue;
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('darkMode', newValue);
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlowTask',
      theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
),

darkTheme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
),

themeMode: darkMode
    ? ThemeMode.dark
    : ThemeMode.light,
      home: signedIn == null
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : signedIn!
              ? TaskListScreen(
                  tasks: tasks,
                  userName: auth.userName ?? 'Usuário',
                  isDarkMode: darkMode,
onThemeToggle: toggleTheme,
                  onLogout: () async {
                    await auth.logout();

                    if (mounted) {
                      setState(() {
                        signedIn = false;
                      });
                    }
                  },
                )
              : AuthScreen(
                  auth: auth,
                  onAuthenticated: () {
                    setState(() {
                      signedIn = true;
                    });
                  },
                ),
    );
  }
}