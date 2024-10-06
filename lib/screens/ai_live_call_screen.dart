import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class AILiveCallScreen extends StatefulWidget {
  const AILiveCallScreen({Key? key}) : super(key: key);

  @override
  _AILiveCallScreenState createState() => _AILiveCallScreenState();
}

class _AILiveCallScreenState extends State<AILiveCallScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final Gemini _gemini = Gemini.instance;
  
  bool _isListening = false;
  String _lastWords = '';
  String _aiResponse = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _initializeTextToSpeech();
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (errorNotification) => print('Speech recognition error: $errorNotification'),
    );
    if (!available) {
      // Handle the case where speech recognition is not available
      print('Speech recognition is not available on this device');
    }
  }

  Future<void> _initializeTextToSpeech() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      if (await _speech.initialize()) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
      await _processAIResponse();
    }
  }

  Future<void> _processAIResponse() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _gemini.text(_lastWords);
      _aiResponse = response?.content?.parts?.last.text ?? 'Sorry, I could not process that.';
    } catch (e) {
      _aiResponse = 'An error occurred. Please try again.';
    }

    setState(() {
      _isProcessing = false;
    });

    await _speakAIResponse();
  }

  Future<void> _speakAIResponse() async {
    await _flutterTts.speak(_aiResponse);
    await _flutterTts.awaitSpeakCompletion(true);
    // After speaking, start listening again for continuous conversation
    _listen();
  }

  void _stopCall() {
    setState(() {
      _isListening = false;
      _speech.stop();
      _flutterTts.stop();
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Live Call'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isListening ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? 'Listening...' : 'Tap to start',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              _lastWords,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Text(
                _aiResponse,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _listen,
        child: Icon(_isListening ? Icons.stop : Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: _stopCall,
            child: const Text('End Call'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
