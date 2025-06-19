import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ReconocimientoVista extends StatefulWidget {
  @override
  _ReconocimientoVistaState createState() => _ReconocimientoVistaState();
}

class _ReconocimientoVistaState extends State<ReconocimientoVista> {
  String resultado = "Selecciona una imagen para identificar.";
  File? imagen;

  Future<void> seleccionarYEnviarImagen({required ImageSource origen}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: origen);

    if (pickedFile == null) return;

    File originalImage = File(pickedFile.path);
    File resizedImage = await _optimizarImagen(originalImage);

    setState(() {
      imagen = resizedImage;
      resultado = "Procesando imagen...";
    });

    final uri = Uri.parse("https://mainly-brave-caribou.ngrok-free.app/reconocer");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('imagen', resizedImage.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);

        if (data["status"] == "identificado") {
          bool requisitoriado = data["requisitoriado"] == true;

          setState(() {
            resultado = "Estudiante: ${data["nombres"]} ${data["apellidos"]}\n"
                "ID: ${data["id_estudiante"]}\n"
                "Correo: ${data["correo"]}\n"
                "Requisitoriado: ${requisitoriado ? 'Sí' : 'No'}";
          });

          if (requisitoriado) {
            _mostrarAlertaRequisitoriado(context, data);
          }
        } else {
          setState(() => resultado = "No identificado.");
        }
      } else {
        setState(() => resultado = "Error del servidor");
      }
    } catch (e) {
      setState(() => resultado = "Error al conectar");
    }
  }

  Future<void> _mostrarAlertaRequisitoriado(BuildContext context, Map data) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("¡Alerta!"),
        content: Text("El estudiante ${data["nombres"]} ${data["apellidos"]} está requisitoriado."),
        actions: [
          TextButton(
            child: Text("Cerrar"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            imagen != null
                ? Image.file(imagen!, height: 200)
                : Container(height: 200, color: Colors.grey[300]),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.photo),
              label: Text("Seleccionar desde galería"),
              onPressed: () => seleccionarYEnviarImagen(origen: ImageSource.gallery),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Tomar foto con cámara"),
              onPressed: () => seleccionarYEnviarImagen(origen: ImageSource.camera),
            ),
            SizedBox(height: 20),
            Text(resultado, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
