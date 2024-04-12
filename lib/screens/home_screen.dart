import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';


class MyAiScreen extends StatefulWidget{
  const MyAiScreen({super.key});

  @override
  State<MyAiScreen> createState() => _MyAiScreenState();
}

class _MyAiScreenState extends State<MyAiScreen> {
  final _text1controller=TextEditingController();
  late  String prompt='';
  final gemini = Gemini.instance;
  late  String result='results';

  @override
  Widget build(BuildContext context) {

    String toug ='search';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('MyAI'),centerTitle: true,
        ),
        body:
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(child: Center(
                    child:SingleChildScrollView(child: Text(result,)),),
                ),
                TextField(
              controller: _text1controller,
              decoration: InputDecoration(
                hintText: 'what you want to ask',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {_text1controller.clear();},icon: const Icon(Icons.clear)
                  ),
                  prefixIcon: const Icon(Icons.search),
            )
          ),
          MaterialButton(onPressed: (){
            setState(() {
              toug='searching';
              prompt=_text1controller.text;
              gemini.text(prompt)
              .then((value) =>result=( value?.content?.parts?.last.text )!);///;
              
              }
              );
      
          },
          color: Colors.blue,
          elevation: 2,
          hoverColor: Colors.blueGrey,
          
          child :Text(toug))
          
          ],
          ),
          ),)
            ));
  }
}

