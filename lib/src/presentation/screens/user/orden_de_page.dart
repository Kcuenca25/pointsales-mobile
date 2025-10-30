//import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:ecomerce_app/src/presentation/screens/user/recent_orders_repository.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Modelo simple de orden (puedes moverlo a models si quieres)
class Order {
  final String id;
  final DateTime date;
  final double total;
  final String status;

  Order({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
  });
}

class OrdenPago extends StatefulWidget {
  final Customer customer; 
  final Function(Customer) onProductListNavigate; 

  const OrdenPago({
    super.key,
    required this.customer,
    required this.onProductListNavigate,
  });

  @override
  State<OrdenPago> createState() => _OrdenPagoState();
}

class _OrdenPagoState extends State<OrdenPago> {
  // 👇 Lista simulada de órdenes (luego la puedes traer de API o DB)
List<Order> orders = [ Order(id: "ORD-001", date: DateTime(2025, 8, 15), total: 150.0, status: "Pendiente"), 
Order(id: "ORD-002", date: DateTime(2025, 8, 10), total: 220.0, status: "Pagada"), 
Order(id: "ORD-003", date: DateTime(2025, 8, 8), total: 89.99, status: "Pendiente"), 
Order(id: "ORD-004", date: DateTime(2025, 8, 5), total: 340.5, status: "Pagada"), 
Order(id: "ORD-005", date: DateTime(2025, 8, 3), total: 120.0, status: "Pendiente"),
Order(id: "ORD-006", date: DateTime(2025, 7, 30), total: 560.75, status: "Pagada"), 
Order(id: "ORD-007", date: DateTime(2025, 7, 28), total: 75.0, status: "Pendiente"), 
Order(id: "ORD-008", date: DateTime(2025, 7, 25), total: 199.99, status: "Pagada"), 
Order(id: "ORD-009", date: DateTime(2025, 7, 20), total: 430.25, status: "Pendiente"), 
Order(id: "ORD-010", date: DateTime(2025, 7, 18), total: 99.5, status: "Pagada"), 
Order(id: "ORD-011", date: DateTime(2025, 7, 15), total: 310.0, status: "Pendiente"), 
Order(id: "ORD-012", date: DateTime(2025, 7, 10), total: 255.75, status: "Pagada"), ];// empieza vacía, se llenará con nuevas órdenes

  String _getFullName() {
    return widget.customer.name; // Customer ya tiene name directo
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Factura / Órdenes de Pago",
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Cliente: ${widget.customer.name}"), // ✅ USAR CUSTOMER
              if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
                pw.Text("Email: ${widget.customer.email}"),
              if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
                pw.Text("Teléfono: ${widget.customer.phone}"),
              pw.SizedBox(height: 20),
              pw.Text("Órdenes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...orders.map((order) => pw.Bullet(
                  text: "ID: ${order.id} | ${order.date.toLocal().toString().split(' ')[0]} "
                      "| Total: \$${order.total} | Estado: ${order.status}")),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              CustomBarRow(
                title: 'Órdenes de compra',
                onBackButtonPressed: () => Navigator.pop(context),
                textColor: Colors.black,
              ),
              const SizedBox(height: 16),

              // 🔹 Cabecera cliente - ACTUALIZADA
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.name, // ✅ USAR CUSTOMER
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
                          Text(widget.customer.email!,
                              style: const TextStyle(color: Colors.grey)),
                        if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
                          Text(widget.customer.phone!,
                              style: const TextStyle(color: Colors.grey)),
                        if (widget.customer.commercialCompanyName != null && 
                            widget.customer.commercialCompanyName!.isNotEmpty)
                          Text(widget.customer.commercialCompanyName!,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold
                              )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Flexible(
                child: orders.isEmpty
                    ? const Center(child: Text("No hay órdenes registradas"))
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.grey,
                          thickness: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_cart_outlined, 
                                    color: Color.fromARGB(255, 108, 108, 109)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Orden #${order.id}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text("Fecha: ${order.date.toLocal().toString().split(' ')[0]}",
                                          style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("\$${order.total}",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: order.status == "Pagada"
                                            ? const Color.fromARGB(255, 155, 214, 150)
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(order.status),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              // 🔹 Botones fijos abajo
              Row(
                children: [
                  Expanded(
  child: CustomElevatedButton(
    text: 'Nueva orden ',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NuevaOrdenPage(
            customer: widget.customer, // ✅ PASAR CUSTOMER
            onOrdenCreada: (Order nuevaOrden, Customer cliente, List<ArticuloItem> articulos) { // ✅ ACTUALIZAR TIPOS
              setState(() {
                orders.insert(0, nuevaOrden);
              });
              addOrder(nuevaOrden);
            },
          ),
        ),
      );
    },
  ),
),
                  
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomElevatedButton(
                      text: 'Generar PDF',
                      onPressed: () => _generatePdf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

@override
void initState() {
  super.initState();
  orders = globalOrders;
}
}
