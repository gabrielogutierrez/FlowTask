import '../core/api_client.dart';
import '../models/task_item.dart';
class TaskService {
  TaskService(this.api); final ApiClient api;
  Future<List<TaskItem>> list({String search=''}) async { final data=await api.get('/tasks?search=${Uri.encodeQueryComponent(search)}') as List; return data.map((x)=>TaskItem.fromJson(x as Map<String,dynamic>)).toList(); }
  Future<void> create(String title) async => api.post('/tasks',{'title':title,'description':null,'category':'Geral','priority':'Medium','dueDate':null});
  Future<void> toggle(int id) async => api.patch('/tasks/$id/toggle');
  Future<void> remove(int id) async => api.delete('/tasks/$id');
}