import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart' as _launchURL;

void main() => runApp(MaterialApp(
      home: Home(),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _newLocationController = TextEditingController();
  List _locationList = [];
  int _lastRemovedPos;
  Map<String, dynamic> _lastRemoved;
  Position position;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _locationList = json.decode(data);
      });
    });
  }

  void _addLocation() {
    setState(() {
      _getCurrentLocation();
      Map<String, dynamic> newLocation = Map();
      newLocation['title'] = _newLocationController.text;
      _newLocationController.text = "";
      newLocation['latitude'] =
          position != null ? position.latitude.toString() : "Unknown";
      newLocation['longitude'] =
          position != null ? position.longitude.toString() : "Unknown";
      _locationList.add(newLocation);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _locationList.sort((a, b) {
        return a['title'].toLowerCase().compareTo(b['title'].toLowerCase());
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Histórico de localização"),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 1, 17),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Nova Localização",
                      labelStyle: TextStyle(color: Colors.lightGreen),
                    ),
                    controller: _newLocationController,
                  ),
                ),
                RaisedButton(
                  color: Colors.lightGreen,
                  child: Text("Salvar"),
                  textColor: Colors.white,
                  onPressed: () {
                    _addLocation();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 10),
                itemCount: _locationList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.redAccent,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Card(
            child: ListTile(
                leading: Icon(Icons.map),
                title: Text('${_locationList[index]['title']}'),
                subtitle: Text('Longitude: ${_locationList[index]['longitude']}\nLatitude: ${_locationList[index]['latitude']}'),
                onLongPress: (){
                  _launchURL.launch("google.navigation:q=${_locationList[index]['latitude']},${_locationList[index]['longitude']}");
                },
                isThreeLine: true,
            ),
          ),
        ],
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_locationList[index]);
          _lastRemovedPos = index;
          _locationList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Localização ${_lastRemoved['title']} removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _locationList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  void _getCurrentLocation() async {
    position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return null;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/gps.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_locationList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
