import 'package:flutter/material.dart';
import 'detalle_fallo_page.dart';

class BusquedaPage extends StatelessWidget {
  final List<Map<String, String>> fallos;

  BusquedaPage({required this.fallos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resultados de Búsqueda")),
      body: ListView.builder(
        itemCount: fallos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(fallos[index]["title"]!),
            subtitle: Text(fallos[index]["court"]!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleFalloPage(
                    falloTexto: fallos[index]["title"]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
