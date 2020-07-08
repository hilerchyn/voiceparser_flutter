import 'dart:io' as io;
import 'dart:math';

import 'package:audio_recorder/audio_recorder.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
          title: new Text('Voice Parser (QD-CN)'),
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
  Random random = new Random();
  TextEditingController _controller = new TextEditingController();
  TextEditingController _controllerURL = new TextEditingController()..text='http://127.0.0.1/voiceparser/api';

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
                        child: new Text("Start"),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                        child:new FlatButton(
                          onPressed: _isRecording ? _stop : null,
                          child: new Text("Stop"),
                          color: Colors.red,
                        ),
                    ),
                  ]
              ),
              new TextField(
                controller: _controller,
                decoration: new InputDecoration(
                  hintText: 'Enter a custom path',
                ),
              ),
              new Text("File path of the record: ${_recording.path}"),
              new Text("Format: ${_recording.audioOutputFormat}"),
              new Text("Extension : ${_recording.extension}"),
              new Text(
                  "Audio recording duration : ${_recording.duration.toString()}"),
              Row(
                children: <Widget>[
                  Expanded(
                      child: new TextField(
                        controller: _controllerURL,

                        decoration: new InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Server URL',
                        ),
                      )
                  ),
                  new FlatButton(
                    onPressed: (_isRecording || _recording.path == null) ? null : _parse,
                    padding: EdgeInsets.all(18),
                    child: new Text(
                        "Parse",
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
                Text('解析文件：${_recording.path}'),
                Text('Would you like to approve of this message?'),
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
              onPressed: () {
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