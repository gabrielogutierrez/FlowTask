import 'package:flutter_test/flutter_test.dart';
import 'package:flow_task/models/task_item.dart';
void main(){test('converte JSON da API',(){final item=TaskItem.fromJson({'id':1,'title':'Estudar','category':'Carreira','priority':'High','isCompleted':false,'description':null,'dueDate':null});expect(item.priority,TaskPriority.high);expect(item.title,'Estudar');});}