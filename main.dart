import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create an instance of FlutterLocalNotificationsPlugin
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize settings for Android and iOS
  var initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (String? payload) async {
    // Handle notification selection
  });
  
  runApp(const MyDementiaApp());
}

class MyDementiaApp extends StatelessWidget {
  const MyDementiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      theme: ThemeData(
        primaryColor: Colors.lightBlue, // Set your primary color
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dementia App'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryTile(
                  context,
                  'Exercise',
                  Icons.directions_run,
                  Colors.green,
                  () {
                    // Navigate to Exercise screen or perform action
                  },
                ),
                _buildCategoryTile(
                  context,
                  'To-Do List',
                  Icons.checklist,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyToDoListPage()),
                    );
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryTile(
                  context,
                  'Meditation',
                  Icons.spa,
                  Colors.purple,
                  () {
                    // Navigate to Meditation screen or perform action
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryTile(
                  context,
                  'Music Player',
                  Icons.music_note,
                  Colors.orange,
                  () {
                    // Navigate to Music Player screen or perform action
                  },
                ),
                _buildCategoryTile(
                  context,
                  'Games',
                  Icons.videogame_asset,
                  Colors.red,
                  () {
                    // Navigate to Games screen or perform action
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150, // Set the width
        height: 150, // Set the height
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  String taskName;
  bool isCompleted;
  Recurrence recurrence;
  DateTime? reminderTime;

  Task({
    required this.taskName,
    this.isCompleted = false,
    this.recurrence = Recurrence.none,
    this.reminderTime,
  });
}

class MyToDoListPage extends StatefulWidget {
  const MyToDoListPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyToDoListPageState createState() => _MyToDoListPageState();
}

enum Recurrence { none, daily, weekly, once }

class _MyToDoListPageState extends State<MyToDoListPage> {
  List<Task> tasks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Checkbox(
              value: tasks[index].isCompleted,
              onChanged: (value) async {
                setState(() {
                  tasks[index].isCompleted = value!;
                });

                // Cancel the associated notification when the task is completed
                if (value!) {
                  await _cancelTaskNotification(index);
                }
              },
            ),
            title: Text(
              tasks[index].taskName,
              style: TextStyle(
                decoration: tasks[index].isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getRecurrenceString(tasks[index].recurrence)),
                if (tasks[index].reminderTime != null)
                  Text(
                    'Reminder: ${_formatTime(tasks[index].reminderTime!)}',
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTask(context, index),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Handle menu button tap
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _addTask(BuildContext context) async {
    TextEditingController taskController = TextEditingController();
    Recurrence selectedRecurrence = Recurrence.none;
    DateTime? selectedReminderTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedRecurrence,
              onChanged: (value) {
                setState(() {
                  selectedRecurrence = value as Recurrence;
                });
              },
              items: Recurrence.values.map((recurrence) {
                return DropdownMenuItem(
                  value: recurrence,
                  child: Text(_getRecurrenceString(recurrence)),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Recurrence'),
            ),
            const SizedBox(height: 10),
            DateTimePicker(
              onChanged: (DateTime dateTime) {
                selectedReminderTime = dateTime;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasks.add(Task(
                  taskName: taskController.text,
                  recurrence: selectedRecurrence,
                  reminderTime: selectedReminderTime,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
      // Get the instance of FlutterLocalNotificationsPlugin
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create a notification details object
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    '1',
    'Task Reminder',
    importance: Importance.max,
    priority: Priority.high,
  );
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

  // Schedule the notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Task Reminder',
    'It is time to complete your task.',
    selectedReminderTime,
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
  Navigator.pop(context);
  } 

  Future<void> _editTask(BuildContext context, int index) async {
    TextEditingController taskController =
        TextEditingController(text: tasks[index].taskName);
    Recurrence selectedRecurrence = tasks[index].recurrence;
    DateTime? selectedReminderTime = tasks[index].reminderTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedRecurrence,
              onChanged: (value) {
                setState(() {
                  selectedRecurrence = value as Recurrence;
                });
              },
              items: Recurrence.values.map((recurrence) {
                return DropdownMenuItem(
                  value: recurrence,
                  child: Text(_getRecurrenceString(recurrence)),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Recurrence'),
            ),
            const SizedBox(height: 10),
            DateTimePicker(
              initialDateTime: selectedReminderTime,
              onChanged: (DateTime dateTime) {
                selectedReminderTime = dateTime;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasks[index].taskName = taskController.text;
                tasks[index].recurrence = selectedRecurrence;
                tasks[index].reminderTime = selectedReminderTime;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

  await flutterLocalNotificationsPlugin.zonedSchedule(
      index,
      'Task Reminder',
      'It is time to complete your task!',
      selectedReminderTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    Navigator.pop(context);
  }
}

  String _getRecurrenceString(Recurrence recurrence) {
    switch (recurrence) {
      case Recurrence.none:
        return 'None';
      case Recurrence.daily:
        return 'Daily';
      case Recurrence.weekly:
        return 'Weekly';
      case Recurrence.once:
        return 'Once';
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  Future<void> _cancelTaskNotification(int taskIndex) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Cancel the notification associated with the task index
  await flutterLocalNotificationsPlugin.cancel(taskIndex);
  }

}

class DateTimePicker extends StatefulWidget {
  final ValueChanged<DateTime> onChanged;
  final DateTime? initialDateTime;

  const DateTimePicker({
    Key? key,
    required this.onChanged,
    this.initialDateTime,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DateTimePickerState createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: const Text("Date & Time"),
            subtitle: Text(_selectedDateTime.toString()),
            onTap: () => _selectDateTime(context),
          ),
        ),
      ],
    );
  }

Future<void> _selectDateTime(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDateTime,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (picked != null) {
    // ignore: use_build_context_synchronously
    TimeOfDay? timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (timePicked != null) {
      DateTime combined = DateTime(
        picked.year,
        picked.month,
        picked.day,
        timePicked.hour,
        timePicked.minute,
      );

      setState(() {
        _selectedDateTime = combined;
      });

      widget.onChanged(combined);
    }
  }
}
}