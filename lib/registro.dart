import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RegistroVista extends StatefulWidget {
  @override
  _RegistroVistaState createState() => _RegistroVistaState();
}

class _RegistroVistaState extends State<RegistroVista> {
  File? _imagen;
  final picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  bool _requisitoriado = false;

  String _mensaje = "";
  bool _enviando = false;

  Future<void> _tomarFoto() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    File originalImage = File(pickedFile.path);
    File resizedImage = await _optimizarImagen(originalImage);

    setState(() {
      _imagen = resizedImage;
    });
  }

  Future<File> _optimizarImagen(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, width: 800);
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final resizedPath = path.join(tempDir.path, "resized_$timestamp.jpg");
    final resizedFile = File(resizedPath)..writeAsBytesSync(img.encodeJpg(image, quality: 85));
    return resizedFile;
  }

  Future<void> _enviarDatos() async {
    if (_imagen == null) {
      setState(() => _mensaje = "Por favor toma una foto.");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _enviando = true;
      _mensaje = "";
    });

    final uri = Uri.parse("https://mainly-brave-caribou.ngrok-free.app/registrar");

    var request = http.MultipartRequest('POST', uri);
    request.fields['id_estudiante'] = _idController.text.trim();
    request.fields['nombres'] = _nombresController.text.trim();
    request.fields['apellidos'] = _apellidosController.text.trim();
    request.fields['correo'] = _correoController.text.trim();
    request.fields['requisitoriado'] = _requisitoriado ? "true" : "false";
    request.files.add(await http.MultipartFile.fromPath('imagen', _imagen!.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);
        setState(() {
          _mensaje = data["mensaje"] ?? "Registro exitoso.";
        });
      } else {
        setState(() {
          _mensaje = "Error del servidor";
        });
      }
    } catch (e) {
      setState(() {
        _mensaje = "Error al conectar";
      });
    } finally {
      setState(() {
        _enviando = false;
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _imagen != null
              ? Image.file(_imagen!, height: 200)
              : Container(
            height: 200,
            color: Colors.grey[300],
            child: Center(child: Text("No hay foto tomada")),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: Icon(Icons.camera_alt),
            label: Text("Tomar foto"),
          ),
          SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(labelText: "ID Estudiante"),
                  validator: (value) => value == null || value.isEmpty ? "Ingrese ID" : null,
                ),
                TextFormField(
                  controller: _nombresController,
                  decoration: InputDecoration(labelText: "Nombres"),
                  validator: (value) => value == null || value.isEmpty ? "Ingrese nombres" : null,
                ),
                TextFormField(
                  controller: _apellidosController,
                  decoration: InputDecoration(labelText: "Apellidos"),
                  validator: (value) => value == null || value.isEmpty ? "Ingrese apellidos" : null,
                ),
                TextFormField(
                  controller: _correoController,
                  decoration: InputDecoration(labelText: "Correo"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingrese correo";
                    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
                    if (!emailRegex.hasMatch(value)) return "Correo inválido";
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _requisitoriado,
                      onChanged: (val) {
                        setState(() {
                          _requisitoriado = val ?? false;
                        });
                      },
                    ),
                    Text("Requisitoriado")
                  ],
                ),
                SizedBox(height: 20),
                _enviando
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _enviarDatos,
                  child: Text("Enviar"),
                ),
                SizedBox(height: 20),
                Text(_mensaje, textAlign: TextAlign.center),
              ],
            ),
          )
        ],
      ),
    );
  }
}
