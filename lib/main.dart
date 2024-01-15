import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

// Import the flutter_rating_bar package
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  String _content = 'Content for Home';
  static const data_list = [
    {
      'question':
          'What are the conditions that are required to make a bulb light up?',
      'reference':
          'there is a closed path containing both the bulb and a battery'
    },
    {
      'question':
          'Why do you think the other terminals are being held in a different electrical state than that of the negative terminal?',
      'reference':
          'Terminals 4, 5 and 6 are not connected to the negative battery terminal'
    },
    {
      'question': 'Under what circumstances will a switch affect a bulb?',
      'reference': 'When the switch and the bulb are contained in the same path'
    },
  ];

  // 创建一个文本编辑控制器
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    // 重要：在widget被移除时，需要清理控制器资源
    _controller.dispose();
    super.dispose();
  }

  void _changeText() {
    // 设置文本字段的值
    _controller.text = data_list[_currentIndex]['reference']!;
  }

  void _updateContent(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _content = 'Content for Home';
      } else if (index == 1) {
        _content = 'Content for Business';
      } else if (index == 2) {
        _content = 'Content for School';
      }
    });
  }
  Future<String> yourApiRequestFunction() async {
    final response = await http.post(Uri.parse('http://10.0.2.2:5000/api/predict'),
        headers: {
          'Content-Type': 'application/json', // 如果发送JSON数据
        },
        body: json.encode({
          'reference_answer': data_list[_currentIndex]['reference'],
          'student_answer': _controller.text,
          // 其他参数
        })
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      return json.decode(response.body)['predicted']; // Example of extracting a specific field
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load data');
    }
  }
  void _onButtonPressed(context) {
    showDialog(
      context: context,
      barrierDismissible: true ,
      builder: (BuildContext context) {
        return LoadingDialog(
          apiCall: yourApiRequestFunction(),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('簡答題自動評分'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Section 1 with dynamic content
                cardWithCornerLabel('${data_list[_currentIndex]["question"]}'),
                const SizedBox(height: 8.0),
                // Section 2 with a TextField and a FlatButton
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _controller, // 将控制器关联到TextField
                          decoration: const InputDecoration(
                            labelText: '學生回答',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Space between the TextField and Button
                        // Simple text-based rating button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // This centers the children horizontally
                          mainAxisSize: MainAxisSize.max,
                          // This ensures the Row takes all available horizontal space
                          children: <Widget>[
                            TextButton(
                              onPressed: _changeText, // 按下按钮时调用_changeText方法

                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                // Background color
                                primary: Colors.white,
                                // Text color
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                // Button padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30), // Rounded corners
                                ),
                              ),
                              child:
                                  Text('參考答案', style: TextStyle(fontSize: 16)),
                            ),
                            SizedBox(width: 16),
                            // This adds space between the children
                            Builder(
                              builder: (BuildContext context) {
                                return TextButton(
                                  onPressed: ()=>_onButtonPressed(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    primary: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text('評分', style: TextStyle(fontSize: 16)),
                                );
                              }
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _updateContent,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.one),
              label: 'Question1',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.two),
              label: 'Question2',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.three),
              label: 'Question3',
            ),
          ],
        ),
      ),
    );
  }
}

Widget cardWithCornerLabel(String label) {
  return Stack(
    alignment: Alignment.topLeft,
    children: <Widget>[
      Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            // This adds horizontal padding
            child: Center(child: Text(label)),
          )),
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Text(
            "  簡答問題  ",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ],
  );
}
class LoadingDialog extends StatefulWidget {
  final Future<dynamic> apiCall;

  LoadingDialog({Key? key, required this.apiCall}) : super(key: key);

  @override
  _LoadingDialogState createState() => _LoadingDialogState();
}
class _LoadingDialogState extends State<LoadingDialog> {
  late Future<dynamic> _apiCallFuture;

  @override
  void initState() {
    super.initState();
    _apiCallFuture = widget.apiCall;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<dynamic>(
          future: _apiCallFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: 80,  // Set a fixed width
                height: 80, // Set a fixed height
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasData) {
              return Text('Result: ${snapshot.data}');
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text('Unknown state');
            }
          },
        ),
      ),
    );
  }
}