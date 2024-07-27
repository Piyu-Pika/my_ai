import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_ai/main.dart';
import 'package:provider/provider.dart';

class MyAiScreen extends StatefulWidget {
  const MyAiScreen({Key? key}) : super(key: key);

  @override
  State<MyAiScreen> createState() => _MyAiScreenState();
}

class _MyAiScreenState extends State<MyAiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;
  String _conversationHistory = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final userMessage = _textController.text;
    setState(() {
      _conversationHistory += '\n\nYou: $userMessage';
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await gemini.text(
        '$_conversationHistory\n\nAI: ',
      );
      final aiResponse = response?.content?.parts?.last.text ?? 'No response';
      setState(() {
        _conversationHistory += '\n\nAI: $aiResponse';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _conversationHistory +=
            '\n\nAI: Sorry, an error occurred. Please try again.';
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My AI'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Markdown(
              controller: _scrollController,
              data: _conversationHistory,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium,
                h1: Theme.of(context).textTheme.headlineMedium,
                h2: Theme.of(context).textTheme.titleLarge,
                h3: Theme.of(context).textTheme.titleMedium,
                code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// This is assuming ThemeProvider is defined in main.dart
// If it's not, you should add it here or in a separate file
// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.system;

//   ThemeMode get themeMode => _themeMode;

//   void toggleTheme() {
//     _themeMode =
//         _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
//     notifyListeners();
//   }
// }
