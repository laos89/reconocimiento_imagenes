import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

//JSON
Map myMap = Map();
List<Flowers> flores = [];

Future<Map<String, dynamic>> fetchData() async {
  final response = await http.get(
      Uri.parse("https://raw.githubusercontent.com/Azazel17/pokehub/master/flores.json"));
  print(response.statusCode);
  if (response.statusCode == 200) {
    myMap = json.decode(response.body);
    print("si descarga el json");
    print(response.body);
    Iterable i = myMap["Flowers"];
    flores = i.map((m) => Flowers.fromJson(m)).toList();
  } else {
    throw Exception("no se puede descargar");
  }
  throw '';
}

//clase flower
class Flowers {
  String? id;
  String? name;
  String? description;

  Flowers(this.id, this.name, this.description);

  Flowers.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    description = json["description"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List? _outputs;
  File? _image;
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    loadModel().then((value){
      setState(() {
        isLoading = false;
      });
    });
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teachable Machine"),
        centerTitle: true,
      ),
      body: isLoading
          ? Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null ? Container() : Image.file(_image!),
                  const SizedBox(
                    height: 20.0,
                  ),
                  _outputs != null
                      ? Text(
                          "${flores[_outputs![0]["index"]].name}",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 30.0,
                              background: Paint()..color = Colors.white),
                        )
                      : Container()
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: const Icon(Icons.image),
      ),
    );
  }

  //cargar el modelo
  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  //cargar imagen
  pickImage() async {
    final ImagePicker _picker = ImagePicker();
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }
    setState(() {
      isLoading = true;
      _image = File(image.path.toString());
    });
    classifyImage(File(image.path));
  }

//clasificar imagen
  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);
    setState(() {
      isLoading = false;
      _outputs = output!;
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    Tflite.close();
    super.dispose();
  }
}
