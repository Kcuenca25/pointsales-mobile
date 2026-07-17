// lib/src/models/purchase_order_state.dart
enum PurchaseOrderState {
  draft('draft', 'Pendiente'),
  sent('sent', 'Enviada'),
  purchase('purchase', 'Confirmada'),
  done('done', 'Recibida'),
  cancel('cancel', 'Cancelada');
  
  final String value;
  final String displayName;
  
  const PurchaseOrderState(this.value, this.displayName);
  
  static PurchaseOrderState fromString(String value) {
    return PurchaseOrderState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PurchaseOrderState.draft,
    );
  }
}
