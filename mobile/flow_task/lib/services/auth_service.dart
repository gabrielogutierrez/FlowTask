import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
class AuthService {
  AuthService(this.api); final ApiClient api;
  Future<bool> restore() async { api.token=(await SharedPreferences.getInstance()).getString('token'); return api.token!=null; }
  Future<void> login(String email,String password) async { final data=await api.post('/auth/login',{'email':email,'password':password}) as Map<String,dynamic>; await _save(data['token'] as String); }
  Future<void> register(String name,String email,String password) async { final data=await api.post('/auth/register',{'name':name,'email':email,'password':password}) as Map<String,dynamic>; await _save(data['token'] as String); }
  Future<void> _save(String token) async { api.token=token; await (await SharedPreferences.getInstance()).setString('token',token); }
  Future<void> logout() async { api.token=null; await (await SharedPreferences.getInstance()).remove('token'); }
}