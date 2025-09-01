import 'package:flutter/material.dart';
import 'package:writer_encourager/database_helper.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Writer Encourager',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      home: const MyHomePage(title: 'Writer Encourager Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _streak = 0;
  final TextEditingController _textController = TextEditingController();

  Future<void> _submitAndSave() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await DatabaseHelper().insertWriting(text);
      setState(() {
        _streak++;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved!'),
          content: Text('Your writing has been saved. Streak: $_streak'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Write here',
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitAndSave,
                child: const Text('Submit & Save'),
              ),
              const SizedBox(height: 24),
              Text('Current Streak: $_streak', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
