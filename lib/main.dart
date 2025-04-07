import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import generated file for Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Automatically generated when running flutterfire configure
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return TaskListScreen();
        }
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      print("Login failed: $e");
    }
  }

  Future<void> _register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      print("Registration failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
            ),
            ElevatedButton(
              onPressed: _register,
              child: Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _taskController = TextEditingController();

  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'name': _taskController.text,
        'completed': false,
        'createdAt': Timestamp.now(),
      });
      _taskController.clear();
    }
  }

  Future<void> _toggleTask(DocumentSnapshot task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'completed': !task['completed'],
    });
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task List"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: "Enter Task"),
            ),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: Text("Add Task"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No tasks available"));
                }

                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task['name']),
                      trailing: Checkbox(
                        value: task['completed'],
                        onChanged: (_) => _toggleTask(task),
                      ),
                      onLongPress: () => _deleteTask(task.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
