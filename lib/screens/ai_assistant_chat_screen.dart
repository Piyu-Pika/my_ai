import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';

class AIAssistantChatScreen extends StatefulWidget {
  const AIAssistantChatScreen({Key? key}) : super(key: key);

  @override
  _AIAssistantChatScreenState createState() => _AIAssistantChatScreenState();
}

class _AIAssistantChatScreenState extends State<AIAssistantChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final gemini = Gemini.instance;
  Map<String, List<ChatMessage>> _chatrooms = {};
  String _currentChatroom = 'default';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatrooms();
  }

  Future<void> _loadChatrooms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? chatroomsJson = prefs.getString('chatrooms');
    if (chatroomsJson != null) {
      final Map<String, dynamic> decodedChatrooms = jsonDecode(chatroomsJson);
      setState(() {
        _chatrooms = decodedChatrooms.map((key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((msg) => ChatMessage.fromJson(msg))
                  .toList(),
            ));
      });
    } else {
      _createNewChatroom('default');
    }
  }

  Future<void> _saveChatrooms() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> chatroomsToSave =
        _chatrooms.map((key, value) => MapEntry(
              key,
              value.map((msg) => msg.toJson()).toList(),
            ));
    final String chatroomsJson = jsonEncode(chatroomsToSave);
    await prefs.setString('chatrooms', chatroomsJson);
  }

  void _createNewChatroom(String name) {
    setState(() {
      _chatrooms[name] = [
        ChatMessage(
          text: "Hello! I'm your AI assistant. How can I help you today?",
          isUser: false,
        )
      ];
      _currentChatroom = name;
    });
    _saveChatrooms();
  }

  void _switchChatroom(String name) {
    setState(() {
      _currentChatroom = name;
    });
    _scrollToBottom();
  }

  void _deleteChatroom(String name) {
    setState(() {
      _chatrooms.remove(name);
      if (_currentChatroom == name) {
        _currentChatroom = _chatrooms.keys.first;
      }
    });
    _saveChatrooms();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final userMessage = _textController.text;
    setState(() {
      _chatrooms[_currentChatroom]!.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });

    _scrollToBottom();
    _saveChatrooms();

    String prompt = '''
    Previous conversation:
    ${_chatrooms[_currentChatroom]!.map((msg) => "${msg.isUser ? 'User' : 'AI'}: ${msg.text}").join('\n')}
    
    User: $userMessage
    
    Please continue the conversation based on the context above. Respond as an AI assistant.
    ''';

    try {
      final response = await gemini.text(prompt);
      setState(() {
        _chatrooms[_currentChatroom]!.add(ChatMessage(
          text: response?.content?.parts?.last.text ??
              'Sorry, I could not process that.',
          isUser: false,
        ));
        _isLoading = false;
      });
      _saveChatrooms();
    } catch (e) {
      setState(() {
        _chatrooms[_currentChatroom]!.add(ChatMessage(
          text: 'An error occurred. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant - $_currentChatroom'),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'new') {
                _showNewChatroomDialog();
              } else if (result == 'switch') {
                _showSwitchChatroomDialog();
              } else if (result == 'delete') {
                _showDeleteChatroomDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'new',
                child: Text('New Chatroom'),
              ),
              const PopupMenuItem<String>(
                value: 'switch',
                child: Text('Switch Chatroom'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Chatroom'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chatrooms[_currentChatroom]?.length ?? 0,
                itemBuilder: (context, index) {
                  return _chatrooms[_currentChatroom]![index];
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.white,
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
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
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatroomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newChatroomName = '';
        return AlertDialog(
          title: const Text('Create New Chatroom'),
          content: TextField(
            onChanged: (value) {
              newChatroomName = value;
            },
            decoration: const InputDecoration(hintText: "Enter chatroom name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (newChatroomName.isNotEmpty) {
                  _createNewChatroom(newChatroomName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSwitchChatroomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Chatroom'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _chatrooms.length,
              itemBuilder: (BuildContext context, int index) {
                String chatroomName = _chatrooms.keys.elementAt(index);
                return ListTile(
                  title: Text(chatroomName),
                  onTap: () {
                    _switchChatroom(chatroomName);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteChatroomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chatroom'),
          content: const Text(
              'Are you sure you want to delete this chatroom and all its messages?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteChatroom(_currentChatroom);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// ChatMessage class remains the same
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
      : super(key: key);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userBubbleColor = isDarkMode ? Colors.blue[700] : Colors.blue[100];
    final aiBubbleColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.assistant, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      text,
                      style: TextStyle(color: textColor),
                    )
                  : MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: textColor),
                        h1: TextStyle(color: textColor),
                        h2: TextStyle(color: textColor),
                        h3: TextStyle(color: textColor),
                        h4: TextStyle(color: textColor),
                        h5: TextStyle(color: textColor),
                        h6: TextStyle(color: textColor),
                        em: TextStyle(color: textColor),
                        strong: TextStyle(color: textColor),
                        code: TextStyle(
                            color: textColor,
                            backgroundColor: Colors.grey[800]),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
