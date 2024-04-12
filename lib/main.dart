import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:my_ai/screens/home_screen.dart';



void main() {
  Gemini.init(apiKey:'YOUR_API_KEY',);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context){
    return const MaterialApp(
      home:MyAiScreen(),
      debugShowCheckedModeBanner: false,
    );
  }  
}




