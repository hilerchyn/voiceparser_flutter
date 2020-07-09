import 'dart:io' as io;
import 'dart:math';

import 'package:audio_recorder/audio_recorder.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('声音解析(青岛)'),
        ),
        body: new AppBody(),
      ),
    );
  }
}

class AppBody extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  AppBody({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new AppBodyState();
}

class AppBodyState extends State<AppBody> {
  Recording _recording = new Recording();
  bool _isRecording = false;
  String _response = "";
  Random random = new Random();
  TextEditingController _controller = new TextEditingController();
  TextEditingController _controllerURL = new TextEditingController()..text='http://192.168.31.29:5000/voiceparser/api';

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                  children: <Widget>[
                    Expanded(
                      child:new FlatButton(
                        onPressed: _isRecording ? null : _start,
                        child: new Text("开始录音"),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                        child:new FlatButton(
                          onPressed: _isRecording ? _stop : null,
                          child: new Text("结束录音"),
                          color: Colors.red,
                        ),
                    ),
                  ]
              ),
              new TextField(
                controller: _controller,
                decoration: new InputDecoration(
                  hintText: '可输入自定义文件里路径',
                ),
              ),
              new Text("录音文件路径: ${_recording.path}"),
              new Text("文件格式: ${_recording.audioOutputFormat}"),
              new Text("扩展名: ${_recording.extension}"),
              new Text(
                  "声音时长 : ${_recording.duration.toString()}"),
              new Text(
                  "应答信息： $_response",
                  style: TextStyle(color: Colors.red),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                      child: new TextField(
                        controller: _controllerURL,

                        decoration: new InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '解析服务器URL',
                        ),
                      )
                  ),
                  new FlatButton(
                    onPressed: (_isRecording || _recording.path == null) ? null : _parse,
                    padding: EdgeInsets.all(18),
                    child: new Text(
                        "解析",
                        style: TextStyle(fontSize: 20.0)
                    ),
                    color: Colors.green,
                  )
                ],
              ),


            ]),
      ),
    );
  }

  _parse() async{
    return showDialog<void>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('解析提示'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('确定解析：${_recording.path}'),
                Text('该录音吗?${_controllerURL.text}'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('取消'),
              color: Colors.blueGrey,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('确定'),
              color: Colors.red,
              onPressed: () async {


                var url = _controllerURL.text; //'https://www.googleapis.com/books/v1/volumes?q={http}';


                final postUri = Uri.parse(url);
                http.MultipartRequest request = http.MultipartRequest('POST', postUri);

                final filename = _controller.text;

                http.MultipartFile multipartFile = http.MultipartFile(
                    'voice_file',
                    io.File(filename).readAsBytes().asStream(),
                    io.File(filename).lengthSync(),
                    filename: filename.split("/").last
                ); //returns a Future<MultipartFile>

                request.files.add(multipartFile);

                http.StreamedResponse streamedResponse = await request.send();


                // Await the http get response, then decode the json-formatted response.
                //var response = await http.get(url);
                if (streamedResponse.statusCode == 200) {
                  final response = await streamedResponse.stream.bytesToString();
                  var jsonResponse = convert.jsonDecode(response);

                  setState(() {
                    _response = jsonResponse['message'];
                  });

                  //var itemCount = jsonResponse['totalItems'];
                  //print('Number of books about http: $itemCount.');
                } else {
                  print('Request failed with status: ${streamedResponse.statusCode}.');
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _start() async {
    try {
      if (await AudioRecorder.hasPermissions) {
        if (_controller.text != null && _controller.text != "") {
          String path = _controller.text;
          if (!_controller.text.contains('/')) {
            io.Directory appDocDirectory =
            await getApplicationDocumentsDirectory();
            path = appDocDirectory.path + '/' + _controller.text;
          }
          print("Start recording: $path");
          await AudioRecorder.start(
              path: path, audioOutputFormat: AudioOutputFormat.AAC);
        } else {
          await AudioRecorder.start();
        }
        bool isRecording = await AudioRecorder.isRecording;
        setState(() {
          _recording = new Recording(duration: new Duration(), path: "");
          _isRecording = isRecording;
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _stop() async {
    var recording = await AudioRecorder.stop();
    print("Stop recording: ${recording.path}");
    bool isRecording = await AudioRecorder.isRecording;
    File file = widget.localFileSystem.file(recording.path);
    print("  File length: ${await file.length()}");
    setState(() {
      _recording = recording;
      _isRecording = isRecording;
    });
    _controller.text = recording.path;
  }
}