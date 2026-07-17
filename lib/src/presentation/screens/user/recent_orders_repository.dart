
import 'orden_de_page.dart'; // aquí está definido Order

/// Lista global de órdenes en memoria
List<Order> globalOrders = [];

/// Función para agregar nueva orden
void addOrder(Order order) {
  globalOrders.insert(0, order); // la agregamos al inicio (orden más reciente primero)
}
