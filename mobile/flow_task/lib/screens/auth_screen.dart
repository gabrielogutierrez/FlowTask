import 'package:flutter/material.dart';
import '../services/auth_service.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key,required this.auth,required this.onAuthenticated}); final AuthService auth; final VoidCallback onAuthenticated;
  @override State<AuthScreen> createState()=>_AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final form=GlobalKey<FormState>(), name=TextEditingController(), email=TextEditingController(), password=TextEditingController(); bool register=false,busy=false; String? error;
  Future<void> submit() async { if(!form.currentState!.validate()) return; setState(()=>busy=true); try { if(register) { await widget.auth.register(name.text,email.text,password.text); } else { await widget.auth.login(email.text,password.text); } widget.onAuthenticated(); } catch(_) { setState(()=>error='Não foi possível entrar. Confira os dados.'); } finally { if(mounted) setState(()=>busy=false); } }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.task_alt_rounded,size:72,color:Colors.indigo), const SizedBox(height:16), Text('FlowTask',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight:FontWeight.bold)), const SizedBox(height:28),
    if(register) TextFormField(controller:name,decoration:const InputDecoration(labelText:'Nome',prefixIcon:Icon(Icons.person)),validator:(v)=>(v?.trim().length??0)<2?'Informe seu nome':null),
    if(register) const SizedBox(height:12), TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail',prefixIcon:Icon(Icons.email)),validator:(v)=>!(v?.contains('@')??false)?'E-mail inválido':null),
    const SizedBox(height:12), TextFormField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Senha',prefixIcon:Icon(Icons.lock)),validator:(v)=>(v?.length??0)<6?'Mínimo de 6 caracteres':null),
    if(error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
    const SizedBox(height:20), FilledButton(onPressed:busy?null:submit,child:Padding(padding:const EdgeInsets.all(14),child:Text(busy?'Aguarde...':register?'Criar conta':'Entrar'))),
    TextButton(onPressed:()=>setState(()=>register=!register),child:Text(register?'Já tenho uma conta':'Criar minha conta'))
  ])))))));
}