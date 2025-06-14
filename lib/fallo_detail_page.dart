Future<void> consultarIA() async {
  setState(() {
    cargando = true;
    error = "";
    resumen = "";
  });

  final rawText = widget.fallo["content"]?.toString().trim() ?? "";
  final prompt = """
Resumí el siguiente fallo judicial dividiendo el texto en tres partes, claras y separadas por títulos en mayúscula:

HECHOS:
(indicar brevemente qué ocurrió y qué se reclama)

FUNDAMENTOS:
(indicar los principales fundamentos jurídicos del tribunal)

DECISIÓN:
(indicar qué resolvió el tribunal)

Texto del fallo:
$rawText
""";

  try {
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $openAIAPIKey",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    final jsonData = jsonDecode(response.body);
    final choices = jsonData["choices"];

    if (choices != null && choices.isNotEmpty) {
      final contenido = choices[0]["message"]["content"].toString().trim();
      if (contenido.isNotEmpty) {
        setState(() {
          resumen = contenido;
        });
      } else {
        setState(() {
          error = "⚠️ La IA no devolvió texto.";
        });
      }
    } else {
      setState(() {
        error = "⚠️ No se pudo generar resumen.";
      });
    }
  } catch (e) {
    setState(() {
      error = "⚠️ Error de conexión o formato: ${e.toString()}";
    });
  } finally {
    setState(() {
      cargando = false;
    });
  }
}
