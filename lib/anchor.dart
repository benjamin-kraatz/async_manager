import 'package:async_manager/async_manager.dart';

/// Give [AsyncManager] an anchor to get
/// informed if an asyncop needs action or results
/// in error or success.
class Anchor<T> {
  final T child;
  final Function(bool) callback;

  /// Calls back if any AsyncOp instances are still active,
  /// and how many.
  final Function(bool, int) callbackInstancesActive;

  final Function(OperationInfo info) operationNotifier;
  final Function(OperationAction action) operationActionNotifier;

  Anchor(
      {this.callback,
      this.callbackInstancesActive,
      this.child,
      this.operationNotifier,
      this.operationActionNotifier});
}
