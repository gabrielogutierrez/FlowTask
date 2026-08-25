import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiClient {
  ApiClient({this.baseUrl='http://10.0.2.2:5000/api'});
  final String baseUrl; String? token;
  Map<String,String> get headers => {'Content-Type':'application/json', if(token!=null) 'Authorization':'Bearer $token'};
  dynamic decode(http.Response r) { if(r.statusCode>=400) throw Exception(r.body); return r.body.isEmpty ? null : jsonDecode(r.body); }
  Future<dynamic> get(String path) async => decode(await http.get(Uri.parse('$baseUrl$path'),headers:headers));
  Future<dynamic> post(String path,Map<String,dynamic> body) async => decode(await http.post(Uri.parse('$baseUrl$path'),headers:headers,body:jsonEncode(body)));
  Future<dynamic> patch(String path) async => decode(await http.patch(Uri.parse('$baseUrl$path'),headers:headers));
  Future<void> delete(String path) async => decode(await http.delete(Uri.parse('$baseUrl$path'),headers:headers));
}