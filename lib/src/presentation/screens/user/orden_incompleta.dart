import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/articulo.dart';

class OrderDraftState {
  static bool hasDraft = false; // indica si hay una orden sin terminar
  static User? draftUser;
  static List<ArticuloItem> draftArticulos = [];
}
