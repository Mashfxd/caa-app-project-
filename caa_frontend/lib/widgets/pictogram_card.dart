import 'package:flutter/material.dart';

class PictogramCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isFolder;
  final VoidCallback onTap;

  const PictogramCard({
    super.key,
    required this.item,
    required this.isFolder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Soporta tanto booleanos de la API (true/false) como enteros de SQLite (1/0)
    final bool isCore = item['is_core'] == true || item['is_core'] == 1;
    final String imageSource = item['image_url'] ?? item['image_path'] ?? '';
    final String palabra = item['palabra'] ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isFolder
              ? Colors.orange.shade50
              : (isCore ? Colors.amber.shade50 : Colors.blue.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFolder
                ? Colors.orange.shade500
                : (isCore ? Colors.amber.shade500 : Colors.blue.shade300),
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
                child: _buildImage(imageSource),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
              child: Text(
                palabra,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFolder ? Colors.orange.shade900 : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String source) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      );
    } else if (source.isNotEmpty) {
      return Image.asset(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      );
    }
    return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
  }
}