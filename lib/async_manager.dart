library async_manager;

import 'dart:async';
import 'dart:math';

import 'package:async_manager/async_manager_widget.dart';
import 'package:flutter/widgets.dart';

import 'anchor.dart';

enum OperationState { Done, Error, Unknown }

class OperationStateInfo {
  final OperationState opState;

  OperationStateInfo({this.opState});
}

typedef Operation = Future<OperationInfo> Function(
    AsyncManager parentOperation);
typedef OperationNotifier = void Function(OperationInfo info);

/// Gives more information about what is currently
/// up in the [AsyncManager]
class OperationInfo {
  final String title, description;

  OperationInfo({this.title, this.description});
}

/// Makes asynchronous operations manageable even when
/// a stateful widget is no longer mounted.
///
/// Define an async operation with all required information
/// and call [AsyncManager.runOperation].
/// Make sure your [operation] returns a [Future].
///
/// To make sure this operation is done before continuing,
/// call [AsyncManager.runOperation] with await keyword, or
/// use Future's "then" method.
///
/// You can now leave your page, through [Navigator] for example.
///
/// You can hook-up to your created AsyncManager like this:
/// #In initState:
/// ```dart
/// AsyncManager.registerAnchor(Anchor(callback: (state) {
///      if (!mounted) return;
///      setState(() {});
///    }, callbackInstancesActive: (state, count) {
///      if (!mounted) return;
///      setState(() {});
///    }, operationNotifier: (info) {
///      if (!mounted) return;
///      setState(() {});
///    }, operationActionNotifier: (action) {
///      if (!mounted) return;
///      setState(() {});
///    }));
/// ```
///
///
/// Loop through the AsyncManagers like this in widget tree:
/// ```dart
/// AsyncManager.instances != null && AsyncManager.instances.length > 0
///   ?
///     for (AsyncManager op in AsyncManager.instances.values)
///       Column(
///         children: <Widget>[
///             Text(op.operationInfo.title),
///
///             for(OperationAction action in op.operationActions)
///               Text(action.description),
///           ],
///         ),
///   : Container(),
/// ```
/// The above sample is a really light and very simple way.
///
/// More detailed info:
/// In [initState] of a [StatefulWidget], call
/// [AsyncManager.registerAnchor] with an [Anchor] containing
/// your callback. This callback gets called whenever an operation
/// is done; the future returns an OperationStateInfo, 'error' in case
/// the operation wasn't completed successfully, otherwise `done`.
/// Loop through the instances and see the [operationInfo].
/// The `callbackInstancesActive` callback is called when any instance
/// of AsyncManager is completed/deleted.
/// `operationNotifier` informs if OperationInfo is changed.
/// At least, `operationActionNotifier` says when an action is
/// needed to be done by the user.
///
/// ##OPERATIONINFO:
/// If you want to notify the anchors about a change in your async
/// operation, simply define a [OperationAction] and pass it to
/// [AsyncManager.notifyOperationInfo]. The anchor then receives
/// a callback to get informed about a change in the operationInfo.
/// The anchor then should simply call setState.
///
///
/// ##OPERATIONACTION:
/// If something is important to note or must be done by the user
/// itself, you can define an [OperationAction] that could hold
/// a routine to do if the user clicks a button or so.
/// The anchor needs to display the actions like described above
/// and call setState in the callback that is fired when an action
/// is fired via [AsyncManager.notifyOperationAction].
/// To call an action, the anchor must call
/// [OperationAction.showOperationAction] on the action instance
/// that is given in the AsyncManager instance.
/// An operation cannot be completed before the user has shown the action.
/// As an action gets completed, the AsyncManager calls "done" on
/// the primary operation if no more actions are available, keep this
/// in mind. The operation immediately will call "done" when an action
/// has completed, even when the operation itself never has returned
/// successfully.
/// For example:
/// If the operation is changing the app's brightness, an action changed
/// the brightness and is shown by the user, the primary changing of
/// the operation will never call and returns a successful OperationInfo.
/// Also, all pending awaits, operationNotification and all other
/// stuff will never be called.
///
/// Of course you can call another OperationAction inside an OperationAction
/// through the AsyncManagers parameter in operation field.
class AsyncManager {
  static Map<String, AsyncManager> instances;
  static List<Anchor> anchors;
  static OperationNotifier operationNotifier;

  final Operation operation;
  @deprecated
  final Widget sender;
  final AsyncManagerKey hookKey;
  OperationInfo operationInfo;

  List<OperationAction> operationActions;

  Random _randomGen;
  String _richKey;

  AsyncManager(
      {@required this.operation,
      @required this.operationInfo,
      @deprecated this.sender,
      @required this.hookKey}) {
    _randomGen = Random();
    _richKey = _randomGen.nextInt(120000).toString() + this.toString();
    if (instances == null) instances = Map();
    instances[_richKey] = this;
  }

  Completer<OperationState> _completer = Completer<OperationState>();

  Future<OperationState> runOperation() {
    _runOperation();
    return _completer.future;
  }

  void notifyOperationInfo(OperationInfo newInfo) {
    //if (operationNotifier != null) operationNotifier(newInfo);

    operationInfo = newInfo;
    print('AsyncManager: set new operationInfo: ${operationInfo.description}');

    _notifyAnchors(newInfo);
  }

  void notifyOperationAction(OperationAction action) {
    _informAnchorsActionNeeded(action);
    print("ASYNCOP: Action is needed! ${operationActions.length}");
  }

  void terminate() {
    _operationError();
  }

  void _runOperation() {
    _informAnchors(true);
    operation(this).then((c) {
      _operationDone();
    }).catchError((err) {
      print("THERE WAS AN ERROR IN ASYNCOP: " + err.toString());
      //
      //action needed, maybe...
      //
      _operationError(complete: false);
    });
  }

  void _operationDone() {
    print("ASYNCOP: Operation done?!...");
    if (operationActions != null && operationActions.length > 0) {
      //
      // call notifyoperationaction again??
      //
      print("ASYNCOP: There's another operationaction!");
      return;
    }
    _removeInstance();
    _informAnchors(false);
    if (!_completer.isCompleted)
      _completer.complete(OperationState.Done);
    else
      print("ASYNCOP: Already completed.");
  }

  void _operationError({bool complete = true}) {
    if (complete) {
      _removeInstance();
      _informAnchors(false);
      if (!_completer.isCompleted)
        _completer.completeError(OperationState.Error);
    }
  }

  void _removeInstance() {
    operationNotifier = null;
    operationActions = null;
    instances.removeWhere((k, v) => k == _richKey);
  }

  void _informAnchors(bool state) {
    if (anchors != null && anchors.length > 0)
      for (Anchor a in anchors) {
        if (a != null && a.callback != null) a.callback(state);
        if (a != null && a.callbackInstancesActive != null)
          a.callbackInstancesActive(
              instances.length > 0 && instances != null, instances?.length);
      }
  }

  void _informAnchorsActionNeeded(OperationAction action) {
    if (anchors != null && anchors.length > 0)
      for (Anchor a in anchors) {
        if (action != null) {
          if (operationActions == null) operationActions = List();
          if (!operationActions.contains(action)) operationActions.add(action);
        }
        if (a.operationActionNotifier != null)
          a.operationActionNotifier(action);
      }
  }

  void _notifyAnchors(OperationInfo info) {
    if (anchors != null && anchors.length > 0)
      for (Anchor a in anchors) {
        if (a.operationNotifier != null) a.operationNotifier(info);
      }
  }

  void operationActionDone(OperationAction action) {
    if (operationActions.contains(action)) {
      operationActions.remove(action);
      _informAnchorsActionNeeded(null);
      if (operationActions.length <= 0) {
        operationActions = null;
        _operationDone();
      }
      return;
    }
    print("ASYNCOPC: Not containing $action");
  }

  /// Marks this operation as internal.
  /// It means, it will never be displayed
  /// when someone anchors to the instances.
  void markAsInternal(bool sure) {
    if (sure) {
      instances.remove(this);
    }
  }

  static void registerAnchor(Anchor _anchor) {
    if (anchors == null) anchors = List();
    anchors.add(_anchor);
  }
}

/// For example, if an ad is loaded in async op, it cannot
/// be loaded when no valid context is available.
/// So solution is to connect this to an [OperationAction]
/// to auffordern the user to do some action to continue
class OperationAction {
  static const String title = 'Aktion erforderlich!';

  Completer<OperationStateInfo> _completer = Completer<OperationStateInfo>();

  final Operation operation;
  final String description;
  final Widget targetPage;
  final AsyncManager asyncManager;

  OperationAction(
      {this.description, this.targetPage, this.operation, this.asyncManager});

  Future<OperationStateInfo> showOperationAction() {
    _runOperation();
    return _completer.future;
  }

  void _runOperation() {
    operation(asyncManager).then((v) {
      asyncManager.operationActionDone(this);
      if (_completer.isCompleted) return;
      complete();
    });
  }

  void complete() {
    _completer.complete(OperationStateInfo());
  }
}
