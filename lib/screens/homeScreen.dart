import 'package:flutter/material.dart';
import 'package:my_ai/screens/ai_assistant_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:my_ai/main.dart'; // Import this to access ThemeProvider

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<ChatMessage>> _chatrooms = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
    }
  }

  void _createNewChatroom() {
    final newRoomName = 'Untitled ${_chatrooms.length + 1}';
    setState(() {
      _chatrooms[newRoomName] = [];
    });
    _saveChatrooms();
    _navigateToChatScreen(newRoomName);
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

  void _navigateToChatScreen(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          roomName: roomName,
          messages: _chatrooms[roomName]!,
          onMessagesUpdated: (updatedMessages) {
            setState(() {
              _chatrooms[roomName] = updatedMessages;
            });
            _saveChatrooms();
          },
        ),
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, String roomName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(roomName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(roomName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String oldName) {
    final TextEditingController _controller =
        TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Chatroom'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                if (_controller.text.isNotEmpty &&
                    _controller.text != oldName) {
                  setState(() {
                    _chatrooms[_controller.text] = _chatrooms[oldName]!;
                    _chatrooms.remove(oldName);
                  });
                  _saveChatrooms();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String roomName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chatroom'),
          content: Text('Are you sure you want to delete "$roomName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  _chatrooms.remove(roomName);
                });
                _saveChatrooms();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Pikachu',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your Conversations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'The chats will be stored locally on your device',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: _chatrooms.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet.\nTap + to start a new chat!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatrooms.length,
                      itemBuilder: (context, index) {
                        final roomName = _chatrooms.keys.elementAt(index);
                        final lastMessage = _chatrooms[roomName]!.isNotEmpty
                            ? _chatrooms[roomName]!.last.text
                            : 'No messages yet';
                        return Dismissible(
                          key: Key(roomName),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              _chatrooms.remove(roomName);
                            });
                            _saveChatrooms();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$roomName deleted')),
                            );
                          },
                          child: ListTile(
                            title: Text(
                              roomName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                roomName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            onTap: () => _navigateToChatScreen(roomName),
                            onLongPress: () =>
                                _showLongPressMenu(context, roomName),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChatroom,
        child: const Icon(Icons.add),
        tooltip: 'Create new chat',
      ),
    );
  }
}
