import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_database.dart';

class DataRepository {
  // Permite definir la URL al compilar (--dart-define=API_URL=...) o usar localhost por defecto
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Respaldo en memoria para entorno Web si el backend remoto no está disponible
  static final List<Map<String, dynamic>> _webFallbackBoard = [
    {
      'id': 1,
      'pictogram_id': 1,
      'position_x': 0,
      'position_y': 0,
      'palabra': 'Yo',
      'parte_de_la_palabra': 'pronombre',
      'is_core': true,
      'image_url': 'https://api.arasaac.org/v1/pictograms/31807',
      'category_id': null,
    },
    {
      'id': 2,
      'pictogram_id': 2,
      'position_x': 0,
      'position_y': 1,
      'palabra': 'Quiero',
      'parte_de_la_palabra': 'verbo',
      'is_core': true,
      'image_url': 'https://api.arasaac.org/v1/pictograms/5441',
      'category_id': null,
    },
    {
      'id': 3,
      'pictogram_id': 3,
      'position_x': 0,
      'position_y': 2,
      'palabra': 'Mamá',
      'parte_de_la_palabra': 'sustantivo',
      'is_core': true,
      'image_url': 'https://api.arasaac.org/v1/pictograms/2458',
      'category_id': null,
    },
    {
      'id': 4,
      'pictogram_id': 4,
      'position_x': 1,
      'position_y': 0,
      'palabra': 'Comida',
      'parte_de_la_palabra': 'sustantivo',
      'is_core': false,
      'image_url': 'https://api.arasaac.org/v1/pictograms/2443',
      'category_id': 1,
    },
  ];

  static final Map<int, List<Map<String, dynamic>>> _webFallbackCategories = {
    1: [
      {
        'id': 4,
        'palabra': 'Comida',
        'is_core': false,
        'image_url': 'https://api.arasaac.org/v1/pictograms/2443',
        'category_id': 1,
      },
      {
        'id': 5,
        'palabra': 'Agua',
        'is_core': false,
        'image_url': 'https://api.arasaac.org/v1/pictograms/2248',
        'category_id': 1,
      },
      {
        'id': 6,
        'palabra': 'Manzana',
        'is_core': false,
        'image_url': 'https://api.arasaac.org/v1/pictograms/2462',
        'category_id': 1,
      },
    ],
  };

  /// Obtiene los ítems del tablero principal (Offline-First en móvil, API con fallback en Web)
  Future<List<Map<String, dynamic>>> getBoardItems() async {
    if (!kIsWeb) {
      return await LocalDatabase.instance.getBoardItems();
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/board'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> rawList = json.decode(utf8.decode(response.bodyBytes));
        // Aplanamos el objeto 'pictogram' anidado de FastAPI para que coincida con SQLite
        return rawList.map<Map<String, dynamic>>((item) {
          final pic = item['pictogram'] as Map<String, dynamic>? ?? {};
          return {
            'id': item['id'],
            'pictogram_id': pic['id'],
            'position_x': item['position_x'],
            'position_y': item['position_y'],
            'is_hidden': item['is_hidden'],
            'palabra': pic['palabra'],
            'parte_de_la_palabra': pic['parte_de_la_palabra'],
            'is_core': pic['is_core'],
            'image_url': pic['image_url'],
            'category_id': pic['category_id'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Usando respaldo local en Web (API no disponible): $e');
    }
    return _webFallbackBoard;
  }

  /// Obtiene los pictogramas de una categoría/carpeta específica
  Future<List<Map<String, dynamic>>> getCategoryPictograms(int categoryId) async {
    if (!kIsWeb) {
      return await LocalDatabase.instance.getCategoryPictograms(categoryId);
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories/$categoryId/pictograms'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> rawList = json.decode(utf8.decode(response.bodyBytes));
        return rawList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Usando respaldo de categoría en Web: $e');
    }
    return _webFallbackCategories[categoryId] ?? [];
  }

  /// Sincroniza la base de datos local con el servidor FastAPI cuando hay internet
  Future<bool> syncWithServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sync'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (!kIsWeb) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes));
          await LocalDatabase.instance.syncFromBackend(data);
        }
        return true;
      }
    } catch (e) {
      debugPrint('No se pudo sincronizar con el servidor: $e');
    }
    return false;
  }
}