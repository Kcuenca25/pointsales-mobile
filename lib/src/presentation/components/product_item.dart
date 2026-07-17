import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
class ProductItem extends StatefulWidget {
  final Product product;
  final Function(Product, int) onQuantityChange;
  final Function(Product) onLongPress;
  final bool isSelected;

  const ProductItem({
    required this.product,
    required this.onQuantityChange,
    required this.onLongPress,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  _ProductItemState createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  double get totalPrice => widget.product.price * widget.product.quantity;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => widget.onLongPress(widget.product),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: widget.product.image != null
                    ? Image.network(
                        widget.product.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      widget.product.description ?? 'Sin descripción',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        if (widget.product.quantity > 1) {
                          setState(() {
                            widget.product.quantity--;
                          });
                          widget.onQuantityChange(
                            widget.product, 
                            widget.product.quantity
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 8
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product.quantity.toString(),
                      style: const TextStyle(
                        color: Colors.black, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          widget.product.quantity++;
                        });
                        widget.onQuantityChange(
                          widget.product, 
                          widget.product.quantity
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
