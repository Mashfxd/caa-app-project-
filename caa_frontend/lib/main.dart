import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comunicador CAA',
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
  // Variables del tablero principal
  List<dynamic> _boardItems = [];
  int _gridRows = 4;
  int _gridCols = 5;
  bool _isLoading = true;

  // Variables de navegación de carpetas
  bool _isInsideCategory = false;
  String _currentCategoryName = "";
  List<dynamic> _categoryPictograms = [];

  // Variables de la barra de mensajes y TTS
  final List<String> _currentSentence = [];
  late FlutterTts flutterTts;
  bool _isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadBoard();
  }

  // --- 1. INICIALIZAR MOTOR DE VOZ ---
  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    try {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setSpeechRate(0.45); // Habla pausada
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint("Error al inicializar TTS: $e");
    }
  }

  // --- 2. CARGAR TABLERO PRINCIPAL DESDE EL BACKEND ---
  Future<void> _loadBoard() async {
    try {
      // Ajusta la IP si estás en un emulador de Android (10.0.2.2 en lugar de 127.0.0.1)
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/1/board'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _boardItems = data['board'];
          _gridRows = data['grid_rows'];
          _gridCols = data['grid_cols'];
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar el tablero');
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 3. CARGAR CATEGORÍA (CARPETA) DESDE EL BACKEND ---
  Future<void> _openCategory(int categoryId, String categoryName) async {
    setState(() => _isLoading = true);
    try {
      // ⚠️ ASEGÚRATE DE USAR 10.0.2.2 SI ESTÁS EN EMULADOR ANDROID
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/categories/$categoryId/pictograms'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isInsideCategory = true;
          _currentCategoryName = data['nombre'];
          _categoryPictograms = data['pictograms'];
          _isLoading = false;
        });
      } else {
        throw Exception("Servidor respondió con código: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al cargar la categoría: $e");
      setState(() => _isLoading = false);
      
      // Muestra el error en la pantalla de la app para diagnosticar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión con la carpeta: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- 4. REGRESAR AL TABLERO PRINCIPAL ---
  void _goBackToMainBoard() {
    setState(() {
      _isInsideCategory = false;
      _currentCategoryName = "";
      _categoryPictograms = [];
    });
  }

  // --- 5. REPRODUCIR AUDIO INSTANTÁNEO ---
  Future<void> _speakWord(String palabra) async {
    if (_isTtsInitialized) {
      await flutterTts.speak(palabra);
    }
  }

  // --- 6. LEER TODA LA FRASE ACUMULADA ---
  Future<void> _speakSentence() async {
    if (_currentSentence.isNotEmpty && _isTtsInitialized) {
      String phrase = _currentSentence.join(" ");
      await flutterTts.speak(phrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Comunicación', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _isInsideCategory ? _openCategory(0, "") : _loadBoard(); // Recargar
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMessageBar(),
                
                // Mostrar barra de navegación si estamos dentro de una carpeta
                if (_isInsideCategory) _buildCategoryHeader(),

                Expanded(
                  child: _isInsideCategory 
                    ? _buildCategoryGrid() // Grid interno de la carpeta
                    : _buildStaticGrid(),  // Grid principal (Core)
                ),
              ],
            ),
    );
  }

  // --- WIDGET: BARRA DE MENSAJES (SUPERIOR) ---
  Widget _buildMessageBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _currentSentence.join(" "),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.backspace, color: Colors.orange, size: 30),
            onPressed: () {
              if (_currentSentence.isNotEmpty) {
                setState(() => _currentSentence.removeLast());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
            onPressed: () {
              setState(() => _currentSentence.clear());
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _speakSentence,
            icon: const Icon(Icons.volume_up, size: 28),
            label: const Text("Hablar", style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: CABECERA DE CARPETA (BOTÓN REGRESAR) ---
  Widget _buildCategoryHeader() {
    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Carpeta: $_currentCategoryName",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700, 
              foregroundColor: Colors.white
            ),
            onPressed: _goBackToMainBoard,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Regresar al Tablero"),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: GRID PRINCIPAL (CORE) ---
  Widget _buildStaticGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cellWidth = constraints.maxWidth / _gridCols;
        double cellHeight = constraints.maxHeight / _gridRows;

        return Stack(
          children: List.generate(_gridRows * _gridCols, (index) {
            int x = index % _gridCols;
            int y = index ~/ _gridCols;

            var matchingItems = _boardItems.where((item) => item['position_x'] == x && item['position_y'] == y).toList();

            if (matchingItems.isEmpty || matchingItems.first['is_hidden']) {
              return Positioned(
                left: x * cellWidth,
                top: y * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                ),
              );
            }

            var item = matchingItems.first;
            bool isFolder = item['category_id'] != null; // <--- ¡Ahora sí la usamos aquí!

            return Positioned(
              left: x * cellWidth,
              top: y * cellHeight,
              width: cellWidth,
              height: cellHeight,
              child: GestureDetector(
                onTap: () async {
  // Imprimimos todo el mapa del item en la consola de depuración de Flutter
  print("--- DATOS DEL BOTÓN PRESIONADO ---");
  print(item);
  print("category_id actual: ${item['category_id']}");

  await _speakWord(item['palabra']);

  if (item['category_id'] != null) {
    _openCategory(item['category_id'], item['palabra']);
  } else {
    setState(() => _currentSentence.add(item['palabra']));
  }
},
                child: _buildPictogramCard(item, isFolder),
              ),
            );
          }),
        );
      },
    );
  }

  // --- WIDGET: GRID INTERNO DE LA CARPETA (FRINGE) ---
  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // Puedes ajustar según el tamaño de pantalla
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _categoryPictograms.length,
        itemBuilder: (context, index) {
          var item = _categoryPictograms[index];
          return GestureDetector(
            onTap: () async {
              await _speakWord(item['palabra']);
              setState(() => _currentSentence.add(item['palabra']));
            },
            child: _buildPictogramCard(item, false),
          );
        },
      ),
    );
  }

  // --- WIDGET: TARJETA DEL PICTOGRAMA (REUTILIZABLE) ---
  Widget _buildPictogramCard(Map<String, dynamic> item, bool isFolder) {
  return Container(
    margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: isFolder 
          ? Colors.orange.shade50 
          : (item['is_core'] == true ? Colors.amber.shade50 : Colors.blue.shade50),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isFolder 
            ? Colors.orange.shade500 
            : (item['is_core'] == true ? Colors.amber.shade500 : Colors.blue.shade300),
        width: 2,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isFolder)
          Icon(Icons.folder, color: Colors.orange.shade700, size: 20),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            // --- AQUÍ OCURRECIA LA MAGIA HÍBRIDA ---
            child: CachedNetworkImage(
              imageUrl: item['image_url'] ?? '',
              fit: BoxFit.contain,
              // Mientras descarga por primera vez con internet, muestra un pequeño indicador
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              // Si no hay internet y la imagen nunca se había descargado, muestra un icono de respaldo
              errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            item['palabra'] ?? '',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: isFolder ? Colors.orange.shade900 : Colors.black87
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
}