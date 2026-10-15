import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/data_repository.dart';
import '../widgets/pictogram_card.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final DataRepository _repository = DataRepository();
  final FlutterTts _flutterTts = FlutterTts();

  List<Map<String, dynamic>> _boardItems = [];
  List<Map<String, dynamic>> _categoryPictograms = [];
  final List<Map<String, dynamic>> _sentence = [];

  bool _isLoading = true;
  bool _isInsideCategory = false;
  String _currentCategoryName = '';

  static const int _rows = 3;
  static const int _cols = 4;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadBoard();
  }

 Future<void> _initTts() async {
    try {
      // 1. Buscar dinámicamente cualquier voz en español disponible en el dispositivo/navegador
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        if (languages.contains("es-PE")) {
          await _flutterTts.setLanguage("es-PE");
        } else if (languages.contains("es-MX")) {
          await _flutterTts.setLanguage("es-MX");
        } else if (languages.contains("es-ES")) {
          await _flutterTts.setLanguage("es-ES");
        } else {
          // Busca cualquier variante que empiece con 'es'
          final esLang = languages.firstWhere(
            (lang) => lang.toString().toLowerCase().startsWith('es'),
            orElse: () => "es-ES",
          );
          await _flutterTts.setLanguage(esLang.toString());
        }
      } else {
        await _flutterTts.setLanguage("es-ES");
      }

      // 2. Ajustar velocidad: En Web 0.85 es natural; 0.5 a veces silencia palabras cortas en Chrome
      await _flutterTts.setSpeechRate(0.85);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // 3. Evitar que las palabras se bloqueen entre sí
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint("Error configurando TTS: $e");
    }
  }

  Future<void> _speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    try {
      // Detener cualquier locución previa en curso evita que Chrome ignore el nuevo toque
      await _flutterTts.stop();
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint("Error al reproducir voz: $e");
    }
  }

  Future<void> _loadBoard() async {
    setState(() => _isLoading = true);
    final items = await _repository.getBoardItems();
    setState(() {
      _boardItems = items;
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando catálogo con el servidor...')),
    );
    final ok = await _repository.syncWithServer();
    await _loadBoard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '¡Sincronización exitosa! Vocabulario actualizado.'
            : 'Modo Offline activo: usando datos locales.'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
  }

  Future<void> _openCategory(int categoryId, String categoryName) async {
    final pictograms = await _repository.getCategoryPictograms(categoryId);
    setState(() {
      _isInsideCategory = true;
      _currentCategoryName = categoryName;
      _categoryPictograms = pictograms;
    });
  }

  void _onPictogramTap(Map<String, dynamic> item, {required bool isFolder}) {
    if (isFolder && !_isInsideCategory && item['category_id'] != null) {
      _speak(item['palabra'] ?? '');
      _openCategory(item['category_id'] as int, item['palabra'] ?? 'Carpeta');
      return;
    }

    setState(() {
      _sentence.add(item);
    });
    _speak(item['palabra'] ?? '');
  }

  void _speakFullSentence() {
    if (_sentence.isEmpty) return;
    final fullText = _sentence.map((e) => e['palabra']).join(' ');
    _speak(fullText);
  }

  Map<String, dynamic>? _findItemAt(int row, int col) {
    for (final item in _boardItems) {
      if (item['position_x'] == row && item['position_y'] == col) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        title: Text(
          _isInsideCategory
              ? 'Carpeta: $_currentCategoryName'
              : 'Comunicador CAA (Híbrido)',
        ),
        leading: _isInsideCategory
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _isInsideCategory = false),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Sincronizar con servidor',
            icon: const Icon(Icons.sync),
            onPressed: _syncNow,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSentenceBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isInsideCategory
                        ? _buildCategoryGrid()
                        : _buildStaticMotorGrid(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSentenceBar() {
    return Container(
      height: 90,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _sentence.isEmpty
                ? const Text(
                    'Toca los pictogramas para formar una frase...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sentence.length,
                    itemBuilder: (context, index) {
                      final wordItem = _sentence[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          wordItem['palabra'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          IconButton(
            tooltip: 'Reproducir frase',
            icon: const Icon(Icons.volume_up, size: 32, color: Colors.green),
            onPressed: _speakFullSentence,
          ),
          IconButton(
            tooltip: 'Borrar último',
            icon: const Icon(Icons.backspace, size: 28, color: Colors.orange),
            onPressed: () {
              if (_sentence.isNotEmpty) {
                setState(() => _sentence.removeLast());
              }
            },
          ),
          IconButton(
            tooltip: 'Limpiar todo',
            icon: const Icon(Icons.delete, size: 28, color: Colors.red),
            onPressed: () => setState(() => _sentence.clear()),
          ),
        ],
      ),
    );
  }

  /// Cuadrícula estática estricta para respetar la planificación motora del niño
  Widget _buildStaticMotorGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols,
        childAspectRatio: 1.1,
      ),
      itemCount: _rows * _cols,
      itemBuilder: (context, index) {
        final int row = index ~/ _cols;
        final int col = index % _cols;
        final item = _findItemAt(row, col);

        if (item == null) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
          );
        }

        final bool isFolder = item['category_id'] != null;
        return PictogramCard(
          item: item,
          isFolder: isFolder,
          onTap: () => _onPictogramTap(item, isFolder: isFolder),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols,
        childAspectRatio: 1.1,
      ),
      itemCount: _categoryPictograms.length,
      itemBuilder: (context, index) {
        final item = _categoryPictograms[index];
        return PictogramCard(
          item: item,
          isFolder: false,
          onTap: () => _onPictogramTap(item, isFolder: false),
        );
      },
    );
  }
}