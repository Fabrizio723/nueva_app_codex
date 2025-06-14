import 'package:flutter/material.dart';

class DetalleFalloPage extends StatefulWidget {
  final String falloTexto;

  DetalleFalloPage({required this.falloTexto});

  @override
  _DetalleFalloPageState createState() => _DetalleFalloPageState();
}

class _DetalleFalloPageState extends State<DetalleFalloPage> {
  bool mostrarResumen = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          setState(() {
            mostrarResumen = true;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.falloTexto)),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            mostrarResumen ? "Resumen corto generado." : widget.falloTexto,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
