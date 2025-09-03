import 'package:flutter/material.dart';
import 'package:writer_encourager/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

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

  void _goToSavedWritings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SavedWritingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Saved Writings',
            onPressed: _goToSavedWritings,
          ),
        ],
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

class SavedWritingsScreen extends StatefulWidget {
  const SavedWritingsScreen({Key? key}) : super(key: key);

  @override
  State<SavedWritingsScreen> createState() => _SavedWritingsScreenState();
}

class _SavedWritingsScreenState extends State<SavedWritingsScreen> {
  late Future<List<Map<String, dynamic>>> _writingsFuture;

  @override
  void initState() {
    super.initState();
    _writingsFuture = DatabaseHelper().getWritings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Writings'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _writingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No writings saved yet.'));
          }
          final writings = snapshot.data!;
          return ListView.builder(
            itemCount: writings.length,
            itemBuilder: (context, index) {
              final writing = writings[index];
              return ListTile(
                title: Text(writing['content'] ?? ''),
                subtitle: Text(writing['createdAt'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'txt') {
                      await _downloadAsTxt(writing['content'], writing['createdAt']);
                    } else if (value == 'pdf') {
                      await _downloadAsPdf(writing['content'], writing['createdAt']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'txt',
                      child: Text('Download as .txt'),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Text('Download as .pdf'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadAsTxt(String? content, String? createdAt) async {
    if (content == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final safeDate = (createdAt ?? DateTime.now().toIso8601String()).replaceAll(':', '-');
    final file = File('${directory.path}/writing_$safeDate.txt');
    await file.writeAsString(content);
    _showDownloadDialog(file.path);
  }

  Future<void> _downloadAsPdf(String? content, String? createdAt) async {
    if (content == null) return;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text(content),
        ),
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final safeDate = (createdAt ?? DateTime.now().toIso8601String()).replaceAll(':', '-');
    final file = File('${directory.path}/writing_$safeDate.pdf');
    await file.writeAsBytes(await pdf.save());
    _showDownloadDialog(file.path);
  }

  void _showDownloadDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Saved'),
        content: Text('File saved to:\n$filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
