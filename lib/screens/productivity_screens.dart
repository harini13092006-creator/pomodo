import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class PomodoNavigation extends StatefulWidget {
  const PomodoNavigation({super.key});
  @override State<PomodoNavigation> createState() => _PomodoNavigationState();
}
class _PomodoNavigationState extends State<PomodoNavigation> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [const HomeScreen(), const StatisticsScreen(), const TasksScreen(), const AchievementsScreen(), const SettingsScreen()];
    return Scaffold(body: IndexedStack(index: index, children: pages), bottomNavigationBar: NavigationBar(
      selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Awards'),
        NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: 'Settings')],
    ));
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});
  @override Widget build(BuildContext context) {
    final storage = context.read<StorageService>(); final sessions = storage.getFocusSessions();
    final now = DateTime.now(); final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final week = sessions.where((s) { final d = DateTime.tryParse('${s['date']}'); return d != null && !d.isBefore(weekStart); }).toList();
    final todayKey = StorageService.formatDate(now);
    final today = sessions.where((s) => (s['date'] as String? ?? '').startsWith(todayKey)).toList();
    final weeklyMinutes = week.fold<int>(0, (sum, s) => sum + ((s['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60);
    final counts = List<int>.generate(7, (i) => week.where((s) { final d = DateTime.tryParse('${s['date']}'); return d != null && d.weekday == i + 1; }).length);
    return _Page(title: 'Your progress', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _Metric(label: 'Today', value: '${today.length} sessions', icon: Icons.today)), const SizedBox(width: 12), Expanded(child: _Metric(label: 'Focus time', value: '${today.fold<int>(0,(a,s)=>a+((s['durationSeconds'] as num?)?.toInt()??0)) ~/ 60} min', icon: Icons.timer_outlined))]),
      const SizedBox(height: 14), _Metric(label: 'This week', value: '${weeklyMinutes ~/ 60}h ${weeklyMinutes % 60}m · ${week.length} sessions', icon: Icons.date_range),
      const SizedBox(height: 22), Text('Sessions this week', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 14),
      SizedBox(height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (i) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${counts[i]}', style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 6), Container(width: 24, height: (counts[i] * 22.0).clamp(6, 100), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 7), Text(['M','T','W','T','F','S','S'][i])])))),
      const SizedBox(height: 20), Text('Recent focus sessions', style: Theme.of(context).textTheme.titleLarge),
      if (sessions.isEmpty) const _Empty(icon: Icons.spa_outlined, text: 'Complete a focus session to start your history.') else ...sessions.reversed.take(8).map((s) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text('${((s['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60} minute focus'), subtitle: Text((s['date'] as String? ?? '').replaceFirst('T',' · ').split('.').first))),
    ]));
  }
}

class TasksScreen extends StatefulWidget { const TasksScreen({super.key}); @override State<TasksScreen> createState()=>_TasksScreenState(); }
class _TasksScreenState extends State<TasksScreen> {
  Future<void> _edit([Map<String,dynamic>? task]) async {
    final c=TextEditingController(text: task?['title'] as String? ?? '');
    final title=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(task==null?'New task':'Edit task'),content:TextField(controller:c, autofocus:true, maxLength:100, decoration:const InputDecoration(hintText:'What would you like to focus on?'), onSubmitted:(v)=>Navigator.pop(ctx,v.trim())),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Save'))]));
    if(title==null||title.isEmpty)return; final s=context.read<StorageService>(); final items=s.getTasks();
    if(task==null){items.add({'id':DateTime.now().microsecondsSinceEpoch.toString(),'title':title,'done':false,'priority':'Normal','focusMinutes':0});}else{final i=items.indexWhere((e)=>e['id']==task['id']);if(i>=0)items[i]['title']=title;}
    await s.saveTasks(items); if(mounted)setState((){});
  }
  Future<void> _change(Map<String,dynamic> task, {bool? done, bool remove=false}) async {final s=context.read<StorageService>();final items=s.getTasks();final i=items.indexWhere((e)=>e['id']==task['id']);if(i<0)return;if(remove)items.removeAt(i);else if(done!=null)items[i]['done']=done;await s.saveTasks(items);if(mounted)setState((){});}
  @override Widget build(BuildContext context) {final tasks=context.watch<StorageService>().getTasks();final pending=tasks.where((t)=>t['done']!=true).toList();final done=tasks.where((t)=>t['done']==true).toList();return _Page(title:'Tasks', action:IconButton(onPressed:()=>_edit(),icon:const Icon(Icons.add)), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${done.length} of ${tasks.length} completed',style:Theme.of(context).textTheme.bodyLarge),const SizedBox(height:12),if(tasks.isNotEmpty)LinearProgressIndicator(value:done.length/tasks.length,minHeight:7,borderRadius:BorderRadius.circular(6)),const SizedBox(height:16),Text('To do',style:Theme.of(context).textTheme.titleLarge),if(pending.isEmpty)const _Empty(icon:Icons.checklist,text:'Add a task and make room for focused work.'),...pending.map((t)=>_TaskTile(task:t,onToggle:()=>_change(t,done:true),onEdit:()=>_edit(t),onDelete:()=>_change(t,remove:true))),if(done.isNotEmpty)...[const SizedBox(height:16),Text('Completed',style:Theme.of(context).textTheme.titleLarge),...done.map((t)=>_TaskTile(task:t,onToggle:()=>_change(t,done:false),onEdit:()=>_edit(t),onDelete:()=>_change(t,remove:true)))]]));}
}
class _TaskTile extends StatelessWidget {final Map<String,dynamic> task;final VoidCallback onToggle,onEdit,onDelete;const _TaskTile({required this.task,required this.onToggle,required this.onEdit,required this.onDelete});@override Widget build(BuildContext context)=>Card(child:ListTile(leading:Checkbox(value:task['done']==true,onChanged:(_)=>onToggle()),title:Text(task['title'] as String? ?? '',style:TextStyle(decoration:task['done']==true?TextDecoration.lineThrough:null)),subtitle:Text('${task['priority']??'Normal'} priority · ${task['focusMinutes']??0} focus min'),trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?onEdit():onDelete(),itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])));}

class AchievementsScreen extends StatelessWidget {const AchievementsScreen({super.key});@override Widget build(BuildContext context){final s=context.watch<StorageService>();final sessions=s.getFocusSessions();final tasks=s.getTasks();final dates=sessions.map((x)=>DateTime.tryParse('${x['date']}')).whereType<DateTime>().map(StorageService.formatDate).toSet();var streak=0;var day=DateTime.now();if(!dates.contains(StorageService.formatDate(day)))day=day.subtract(const Duration(days:1));while(dates.contains(StorageService.formatDate(day))){streak++;day=day.subtract(const Duration(days:1));}final badges=<({String name,String desc,bool unlocked,IconData icon})>[(name:'First Focus',desc:'Complete your first focus session',unlocked:sessions.isNotEmpty,icon:Icons.spa),(name:'Consistency',desc:'Complete 3 sessions in one day',unlocked:s.getHistoricalSessionCounts().values.any((n)=>n>=3),icon:Icons.repeat),(name:'Focus Master',desc:'Complete 10 focus sessions',unlocked:sessions.length>=10,icon:Icons.bolt),(name:'Productivity Champion',desc:'Complete 50 focus sessions',unlocked:sessions.length>=50,icon:Icons.emoji_events),(name:'Weekly Hero',desc:'Focus on 7 consecutive days',unlocked:streak>=7,icon:Icons.local_fire_department),(name:'Goal Achiever',desc:'Complete a daily goal',unlocked:s.getHistoricalSessionCounts().values.any((n)=>n>=s.getDailyGoal()),icon:Icons.flag)];return _Page(title:'Achievements',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Card(child:ListTile(leading:const Icon(Icons.local_fire_department,color:Colors.deepOrange,size:32),title:Text('$streak day streak'),subtitle:Text(streak>0?'Beautiful consistency. Keep it growing!':'Complete a focus session to begin your streak.'))),const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.local_florist,color:Colors.green,size:32),title:const Text('Focus Garden'),subtitle:Text('${sessions.length} sessions nurturing your garden'),trailing:Text(sessions.length>=10?'🌳':sessions.length>=4?'🌱':'🌰',style:const TextStyle(fontSize:36)))),const SizedBox(height:18),Text('Milestones',style:Theme.of(context).textTheme.titleLarge),...badges.map((b)=>Card(child:ListTile(leading:Icon(b.icon,color:b.unlocked?Theme.of(context).colorScheme.primary:Colors.grey),title:Text(b.name),subtitle:Text(b.desc),trailing:Icon(b.unlocked?Icons.check_circle:Icons.lock_outline,color:b.unlocked?Colors.green:Colors.grey))))]));}}

class _Page extends StatelessWidget {final String title;final Widget child;final Widget? action;const _Page({required this.title,required this.child,this.action});@override Widget build(BuildContext context)=>SafeArea(child:CustomScrollView(slivers:[SliverAppBar(pinned:true,title:Text(title),actions:action==null?null:[action!]),SliverPadding(padding:const EdgeInsets.fromLTRB(18,8,18,24),sliver:SliverToBoxAdapter(child:child))]));}
class _Metric extends StatelessWidget {final String label,value;final IconData icon;const _Metric({required this.label,required this.value,required this.icon});@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(context).colorScheme.primary),const SizedBox(height:10),Text(value,style:Theme.of(context).textTheme.titleMedium),Text(label,style:Theme.of(context).textTheme.bodySmall)])));}
class _Empty extends StatelessWidget {final IconData icon;final String text;const _Empty({required this.icon,required this.text});@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:24),child:Center(child:Column(children:[Icon(icon,size:34,color:Theme.of(context).colorScheme.primary),const SizedBox(height:8),Text(text,textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodyMedium)])));}
