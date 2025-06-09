import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(MaterialApp(
    home: ReconocimientoFacialApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class ReconocimientoFacialApp extends StatefulWidget {
  @override
  _ReconocimientoFacialAppState createState() => _ReconocimientoFacialAppState();
}

class _ReconocimientoFacialAppState extends State<ReconocimientoFacialApp> {
  String resultado = "Selecciona una imagen para identificar.";
  File? imagen;

  Future<void> seleccionarYEnviarImagen() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File originalImage = File(pickedFile.path);
    File resizedImage = await _optimizarImagen(originalImage);

    setState(() {
      imagen = resizedImage;
      resultado = "Procesando imagen...";
    });

    final uri = Uri.parse("https://mainly-brave-caribou.ngrok-free.app/reconocer"); // cambia esto
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('imagen', resizedImage.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);
        setState(() {
          resultado = data["status"] == "identificado"
              ? "Estudiante: ${data["nombres"]} ${data["apellidos"]}\nID: ${data["id_estudiante"]}\nCorreo: ${data["correo"]}\nRequisitoriado: ${data["requisitoriado"]}"
              : "No identificado.";
        });
      } else {
        setState(() => resultado = "Error del servidor: $respStr");
      }
    } catch (e) {
      setState(() => resultado = "Error al conectar: $e");
    }
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
    print(timestamp);
    final resizedPath = path.join(tempDir.path, "resized_$timestamp.jpg");
    final resizedFile = File(resizedPath)..writeAsBytesSync(img.encodeJpg(image, quality: 85));
    return resizedFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reconocimiento Facial")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              imagen != null
                  ? Image.file(imagen!, height: 200)
                  : Container(height: 200, color: Colors.grey[300]),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: seleccionarYEnviarImagen,
                child: Text("Seleccionar imagen y enviar"),
              ),
              SizedBox(height: 20),
              Text(resultado, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
