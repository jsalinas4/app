import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EstudiantesVista extends StatefulWidget {
  @override
  _EstudiantesVistaState createState() => _EstudiantesVistaState();
}

class _EstudiantesVistaState extends State<EstudiantesVista> {
  List<dynamic> estudiantes = [];
  List<dynamic> estudiantesFiltrados = [];
  bool cargando = true;
  String mensaje = '';
  String busqueda = '';
  bool filtrarRequisitoriado = false;

  final TextEditingController _busquedaController = TextEditingController();

  final String baseUrl = "https://mainly-brave-caribou.ngrok-free.app";

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(_aplicarFiltros);
    _cargarEstudiantes();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final response = await http.get(Uri.parse("$baseUrl/estudiantes"));
      if (response.statusCode == 200) {
        estudiantes = json.decode(response.body);
        _aplicarFiltros();
      } else {
        setState(() {
          mensaje = "Error al obtener estudiantes";
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        mensaje = "Error de conexión";
        cargando = false;
      });
    }
  }

  void _aplicarFiltros() {
    final query = _busquedaController.text.toLowerCase();

    setState(() {
      estudiantesFiltrados = estudiantes.where((est) {
        final matchBusqueda = est['id_estudiante'].toString().toLowerCase().contains(query) ||
            est['nombres'].toString().toLowerCase().contains(query) ||
            est['apellidos'].toString().toLowerCase().contains(query);

        final matchRequisitoriado = !filtrarRequisitoriado || est['requisitoriado'] == true;

        return matchBusqueda && matchRequisitoriado;
      }).toList();
      cargando = false;
    });
  }

  Future<void> _eliminarEstudiante(String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar estudiante"),
        content: Text("¿Estás seguro de eliminar al estudiante con ID $id?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Eliminar")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(Uri.parse("$baseUrl/estudiantes/$id"));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Estudiante eliminado")));
        _cargarEstudiantes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se pudo eliminar")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error")));
    }
  }

  void _editarEstudiante(Map<String, dynamic> estudiante) {
    TextEditingController nombresController = TextEditingController(text: estudiante["nombres"]);
    TextEditingController apellidosController = TextEditingController(text: estudiante["apellidos"]);
    TextEditingController correoController = TextEditingController(text: estudiante["correo"]);
    bool requisitoriado = estudiante["requisitoriado"] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Editar Estudiante"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: nombresController, decoration: InputDecoration(labelText: "Nombres")),
                    TextField(controller: apellidosController, decoration: InputDecoration(labelText: "Apellidos")),
                    TextField(controller: correoController, decoration: InputDecoration(labelText: "Correo")),
                    CheckboxListTile(
                      title: Text("Requisitoriado"),
                      value: requisitoriado,
                      onChanged: (val) {
                        setStateDialog(() {
                          requisitoriado = val ?? false;
                        });
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
                TextButton(
                  onPressed: () async {
                    final updateData = {
                      "nombres": nombresController.text,
                      "apellidos": apellidosController.text,
                      "correo": correoController.text,
                      "requisitoriado": requisitoriado,
                    };

                    try {
                      final res = await http.put(
                        Uri.parse("$baseUrl/estudiantes/${estudiante['id_estudiante']}"),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode(updateData),
                      );

                      if (res.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Estudiante actualizado")));
                        Navigator.pop(context);
                        _cargarEstudiantes();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar")));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (cargando) return Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Buscar por ID, nombre o apellido',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),

          // Filtro por requisitoriado
          Row(
            children: [
              Checkbox(
                value: filtrarRequisitoriado,
                onChanged: (bool? valor) {
                  setState(() {
                    filtrarRequisitoriado = valor ?? false;
                    _aplicarFiltros();
                  });
                },
              ),
              Text("Mostrar solo requisitoriados")
            ],
          ),
          SizedBox(height: 10),

          // Lista
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarEstudiantes,
              child: estudiantesFiltrados.isEmpty
                  ? Center(child: Text(mensaje.isNotEmpty ? mensaje : "No hay estudiantes registrados"))
                  : ListView.builder(
                itemCount: estudiantesFiltrados.length,
                itemBuilder: (context, index) {
                  final est = estudiantesFiltrados[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ListTile(
                      title: Text("${est['nombres']} ${est['apellidos']}"),
                      subtitle: Text("ID: ${est['id_estudiante']}\nCorreo: ${est['correo']}\nRequisitoriado: ${est['requisitoriado']}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit), onPressed: () => _editarEstudiante(est)),
                          IconButton(icon: Icon(Icons.delete), onPressed: () => _eliminarEstudiante(est['id_estudiante'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
