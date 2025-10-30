import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';

class ArticuloSelectGrid extends StatefulWidget {
  final List<ArticuloItem> articulos;
  final void Function(ArticuloItem) onSelect;

  const ArticuloSelectGrid({
    Key? key,
    required this.articulos,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<ArticuloSelectGrid> createState() => _ArticuloSelectGridState();
}

class _ArticuloSelectGridState extends State<ArticuloSelectGrid> {
  int _currentPage = 1;
  final int _itemsPerPage = 12; // artículos por página

  @override
  Widget build(BuildContext context) {
    int totalPages = (widget.articulos.length / _itemsPerPage).ceil();

    // rango de artículos por página
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = (_currentPage * _itemsPerPage).clamp(0, widget.articulos.length);

    List<ArticuloItem> visibleArticulos = widget.articulos.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Grid de artículos
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleArticulos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final articulo = visibleArticulos[index];
              return GestureDetector(
                onTap: () => widget.onSelect(articulo),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(Icons.shopping_bag,
                                size: 48, color: Colors.deepPurple),
                          ),
                        ),
                        Text(
                          articulo.nombre,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          articulo.categoria,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "\$${articulo.precio.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Paginación
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),
              for (int i = 1; i <= totalPages; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage == i
                          ? Colors.deepPurple
                          : Colors.grey[300],
                      foregroundColor:
                          _currentPage == i ? Colors.white : Colors.black,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentPage = i;
                      });
                    },
                    child: Text("$i"),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _currentPage < totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        )
      ],
    );
  }
}
