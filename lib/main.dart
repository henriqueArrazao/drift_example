import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'database/schema.dart';

late final AppDatabase db;
late final Stream<List<TodoData>> todosStream;

void main() async {
  db = AppDatabase();
  todosStream = db.watchAllTodos();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Page(),
    );
  }
}

class Page extends StatefulWidget {
  const Page({Key? key}) : super(key: key);

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  bool hasBackup = true;
  late final String backupPath;

  @override
  void initState() {
    super.initState();
    AppDatabase.databaseDirectory()
        .then((value) => backupPath = p.join(value.path, 'backup.sqlite'))
        .then((value) => setState(() => hasBackup = File(value).existsSync()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To do list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                await db.customStatement('VACUUM INTO ?', [backupPath]);
                setState(() => hasBackup = File(backupPath).existsSync());
              } catch (e) {
                print('Failed to backup: $e');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: hasBackup
                ? () async {
                    final file = File(backupPath);

                    final directory = await AppDatabase.databaseDirectory();
                    await file
                        .rename(p.join(directory.path, AppDatabase.fileName));

                    db.markTablesUpdated(db.allTables);
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await db
                  .into(db.todo)
                  .insert(TodoCompanion.insert(name: 'New todo'));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TodoData>>(
        stream: todosStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty)
              return Center(child: Text('No todos yet'));
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final todo = snapshot.data![index];
                return ListTile(
                  title: Text(todo.name),
                  subtitle: Text(todo.createdAt.toString()),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
