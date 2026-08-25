import 'package:flutter/material.dart';
import 'core/api_client.dart'; import 'screens/auth_screen.dart'; import 'screens/task_list_screen.dart'; import 'services/auth_service.dart'; import 'services/task_service.dart';
void main()=>runApp(const FlowTaskApp());
class FlowTaskApp extends StatefulWidget { const FlowTaskApp({super.key}); @override State<FlowTaskApp> createState()=>_FlowTaskAppState(); }
class _FlowTaskAppState extends State<FlowTaskApp> {
  final api=ApiClient(); late final auth=AuthService(api); late final tasks=TaskService(api); bool? signedIn;
  @override void initState(){super.initState();auth.restore().then((v)=>setState(()=>signedIn=v));}
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'FlowTask',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:Colors.indigo),useMaterial3:true,inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),home:signedIn==null?const Scaffold(body:Center(child:CircularProgressIndicator())):signedIn!?TaskListScreen(tasks:tasks,onLogout:()async{await auth.logout();setState(()=>signedIn=false);}):AuthScreen(auth:auth,onAuthenticated:()=>setState(()=>signedIn=true)));
}