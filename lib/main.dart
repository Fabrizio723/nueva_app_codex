import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:diacritic/diacritic.dart'; // para eliminar tildes
import 'dart:io'; // para guardar archivos (solo funciona en escritorio)
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> allCases = [];
  List<Map<String, String>> filteredCases = [];

  @override
  void initState() {
    super.initState();
    loadFallos();
  }

  Future<void> loadFallos() async {
    try {
      final String data = await rootBundle.loadString('assets/fallos.json');
      final List<dynamic> jsonResult = json.decode(data);
      setState(() {
        allCases = jsonResult.map<Map<String, String>>((e) => {
              "title": e["nombre_fallo"] ?? "",
              "court": e["organismo"] ?? "",
              "content": e["content"] ?? "",
            }).toList();
      });
    } catch (e) {
      print("❌ Error al cargar fallos.json: $e");
    }
  }

  String normalizar(String texto) {
    return removeDiacritics(texto.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ''));
  }

  void search(String query) {
    String normalQuery = normalizar(query);
    setState(() {
      filteredCases = allCases.where((fallo) {
        final titulo = normalizar(fallo["title"] ?? "");
        final contenido = normalizar(fallo["content"] ?? "");
        return titulo.contains(normalQuery) || contenido.contains(normalQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: 160),
            Center(
              child: TextField(
                controller: _controller,
                onSubmitted: search,
                decoration: InputDecoration(
                  hintText: '¿Qué fallo quiere buscar?',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCases.length,
                itemBuilder: (context, index) {
                  final fallo = filteredCases[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fallo["title"] ?? "Sin título",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(fallo["court"] ?? "Tribunal desconocido"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FalloDetailPage(fallo: fallo),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            elevation: 3,
            child: Icon(Icons.menu, color: Colors.grey[700]),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class FalloDetailPage extends StatelessWidget {
  final Map<String, String> fallo;
  FalloDetailPage({required this.fallo});

  final List<String> abreviaturas = [
    "expte.", "art.", "lct.", "csjn.", "dto.", "ley.", "dr.", "dra.", "sra.", "sr.", "etc."
  ];

  String corregirSaltos(String texto) {
    for (String abrev in abreviaturas) {
      texto = texto.replaceAll('$abrev\n\n', '$abrev ');
    }
    return texto;
  }

  Future<void> guardarFalloComoTxt(String titulo, String contenido) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedTitle = titulo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${directory.path}/$sanitizedTitle.txt';
      final file = File(filePath);
      await file.writeAsString(contenido);
      print('✅ Fallo guardado como archivo: $filePath');
    } catch (e) {
      print("❌ Error al guardar el archivo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawContent = fallo["content"] ?? "";
    final content = corregirSaltos(rawContent);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(fallo["title"] ?? "Fallo"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => guardarFalloComoTxt(fallo["title"] ?? "fallo", rawContent),
            tooltip: "Descargar fallo",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: procesarContenido(content),
          ),
        ),
      ),
    );
  }

  List<Widget> procesarContenido(String content) {
    List<String> parrafos = content.split('\n\n');
    return parrafos.map((parrafo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          '     ${parrafo.trim()}',
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
      );
    }).toList();
  }
}
