import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  // Motor de Voz (Text-to-Speech)
  final FlutterTts flutterTts = FlutterTts();

  // Barra de Mensajes (Frase en construcción)
  final List<String> _currentSentence = [];

  // Datos del tablero que vendrán del Backend
  Map<String, dynamic>? boardData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchBoardFromBackend();
  }

  // Inicializar configuración de voz en español
  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.45); // Velocidad moderada ideal para terapia
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  // Función para consumir nuestra API de FastAPI
  Future<void> _fetchBoardFromBackend() async {
    // Nota: Si usas emulador Android, '10.0.2.2' apunta al localhost de tu PC. 
    // Si usas navegador web o dispositivo físico, usa tu IP local (ej. 192.168.X.X)
    const String apiUrl = "http://127.0.0.1:8000/users/1/board"; 

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          boardData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Error al cargar el tablero del servidor.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "No se pudo conectar al servidor Python: $e";
        isLoading = false;
      });
    }
  }

  // Función para agregar palabras a la barra y hablar
  void _onPictogramTapped(String word) {
    setState(() {
      _currentSentence.add(word);
    });
  }

  // Reproducir la frase completa con TTS
  Future<void> _speakSentence() async {
    if (_currentSentence.isEmpty) return;
    String sentenceToPlay = _currentSentence.join(" ");
    await flutterTts.speak(sentenceToPlay);
  }

  // Borrar última palabra
  void _removeLastWord() {
    if (_currentSentence.isNotEmpty) {
      setState(() {
        _currentSentence.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(boardData != null ? "Tablero de: ${boardData!['nombre']}" : "Cargando Tablero..."),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // 1. BARRA DE MENSAJES (Lenguaje Generativo)
          Container(
            height: 80,
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _currentSentence.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Toca los pictogramas para armar una frase...",
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentSentence.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () async {
                                // Permite tocar una palabra específica de la barra para reproducirla sola
                                await flutterTts.speak(_currentSentence[index]);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade300, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _currentSentence[index],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 8),
                // Botón de Borrar Última Palabra
                IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.redAccent, size: 28),
                  onPressed: _removeLastWord,
                  tooltip: "Borrar última palabra",
                ),
                const SizedBox(width: 4),
                // Botón de Reproducción de Voz Principal
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onPressed: _speakSentence,
                  icon: const Icon(Icons.volume_up, size: 24),
                  label: const Text("Hablar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // 2. CUADRÍCULA DE PICTOGRAMAS (Planificación Motora y Grid Estático)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
                    : _buildStaticGrid(),
          ),
        ],
      ),
    );
  }

  // Construcción del Grid estático basado en coordenadas absolutas
  Widget _buildStaticGrid() {
    // Forzamos la conversión a int por seguridad por si llega como String
    int rows = int.parse(boardData!['grid_rows'].toString());
    int cols = int.parse(boardData!['grid_cols'].toString());
    List items = boardData!['board'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          int x = index ~/ cols;
          int y = index % cols;

          // Convertimos también las coordenadas por si vienen como texto
          var matchingItem = items.firstWhere(
            (item) => 
              int.parse(item['position_x'].toString()) == x && 
              int.parse(item['position_y'].toString()) == y,
            orElse: () => null,
          );

          if (matchingItem == null || matchingItem['is_hidden'] == true) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }

          return GestureDetector(
            onTap: () => _onPictogramTapped(matchingItem['palabra']),
            child: Container(
              decoration: BoxDecoration(
                color: matchingItem['is_core'] ? Colors.amber.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: matchingItem['is_core'] ? Colors.amber.shade700 : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 40, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    matchingItem['palabra'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}