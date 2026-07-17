import 'package:flutter/material.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';


class ProductDetailViewScreen extends StatelessWidget {
  final ArticuloItem articulo;
  final Product product;

  const ProductDetailViewScreen({
    super.key,
    required this.articulo,
    required this.product,
  });

  // ✅ MÉTODO PARA CALCULAR PRECIO CON IMPUESTOS CORRECTAMENTE
  // En este sistema, product.listPrice ya incluye el ITBIS (si aplica)
  double get _precioConImpuesto {
    return product.listPrice;
  }

  // ✅ MÉTODO PARA SABER SI TIENE IMPUESTOS
  bool get _tieneImpuestos {
    return (product.taxesIds != null && product.taxesIds!.isNotEmpty) ||
           (product.supplierTaxesIds != null && product.supplierTaxesIds!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Producto"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: product.typeColor.withOpacity(0.1),
              child: Icon(
                _getProductIcon(product.type),
                color: product.typeColor,
                size: 80,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articulo.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: product.typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      product.typeDisplay,
                      style: TextStyle(
                        color: product.typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Información del producto
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  
                  // ✅ SECCIÓN DE PRECIOS MEJORADA
                  _buildPricingSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPricingSection() {
    // ✅ IMPORTANTE: product.listPrice en Odoo ya incluye el impuesto en esta configuración
    final tieneImpuestos = _tieneImpuestos;
    
    // ✅ El precio final es el listPrice directamente
    final precioFinal = product.listPrice;
    
    // ✅ Extraer el precio base y el monto del impuesto
    final precioBase = tieneImpuestos ? precioFinal / 1.18 : precioFinal;
    final montoImpuesto = tieneImpuestos ? precioFinal - precioBase : 0.0;

    print('💰 ProductDetailViewScreen - Calculando precios:');
    print('   Precio base Odoo: \$${precioBase.toStringAsFixed(2)}');
    print('   Precio artículo: \$${articulo.precio.toStringAsFixed(2)}');
    print('   Tiene impuestos: $tieneImpuestos');
    print('   Precio final calculado: \$${precioFinal.toStringAsFixed(2)}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                "Información de Precios",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Desglose de precios - SIEMPRE muestra precio base de Odoo
          _buildPriceRow(
            label: "Precio base:",
            value: "\$${precioBase.toStringAsFixed(2)}",
            description: "Precio sin impuestos",
          ),
          
          if (tieneImpuestos) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Impuesto ITBIS (18%):",
              value: "\$${montoImpuesto.toStringAsFixed(2)}",
              description: "Aplicado sobre el precio base",
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Precio final:",
              value: "\$${precioFinal.toStringAsFixed(2)}",
              description: "Incluye 18% ITBIS",
              valueColor: Colors.green,
              isBold: true,
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Impuestos:",
              value: "Exento",
              description: "Producto no sujeto a impuestos",
              valueColor: Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              label: "Precio final:",
              value: "\$${precioBase.toStringAsFixed(2)}",
              description: "Mismo precio base (sin impuestos)",
              valueColor: Colors.green,
              isBold: true,
            ),
          ],
          
          // ✅ SECCIÓN ADICIONAL: Precio del artículo (si es diferente)
          if (articulo.precio != precioFinal)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        "Nota:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Este artículo fue escaneado con precio de \$${articulo.precio.toStringAsFixed(2)}.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                  if (articulo.tieneImpuestos != null)
                    Text(
                      "Estado impuestos artículo: ${articulo.tieneImpuestos! ? 'Con ITBIS' : 'Sin ITBIS'}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          
          // Información adicional sobre impuestos
          if (tieneImpuestos)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Este producto incluye ITBIS del 18%",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ✅ WIDGET PARA FILA DE PRECIO
  Widget _buildPriceRow({
    required String label,
    required String value,
    String? description,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                color: valueColor ?? Colors.green,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Información del Producto",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (product.defaultCode != null && product.defaultCode!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.code,
            label: "Código de Producto",
            value: product.defaultCode!,
          ),

        _buildInfoRow(
          icon: Icons.category,
          label: "Categoría",
          value: product.categoryName ?? 'Sin categoría',
        ),
        
        if (product.description != null && product.description!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.description,
            label: "Descripción",
            value: product.description!,
            multiline: true,
          ),
        
        _buildInfoRow(
          icon: product.isSellable ? Icons.check_circle : Icons.block,
          label: "Estado",
          value: product.isSellable ? "Disponible para venta" : "No vendible",
          valueColor: product.isSellable ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: multiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type) {
      case 'consu': return Icons.shopping_bag;
      case 'service': return Icons.design_services;
      case 'product': return Icons.inventory;
      default: return Icons.shopping_bag;
    }
  }
}
