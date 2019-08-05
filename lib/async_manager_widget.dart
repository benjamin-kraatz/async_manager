import 'package:async_manager/anchor.dart';
import 'package:async_manager/async_manager.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

typedef AsyncManagerBuilder = Widget Function(_AsyncManagerWidgetState amwidget,
    OperationInfo info, AsyncManager manager);
typedef AsyncManagerNotificationBuilder = Widget Function(
    bool containsAchor, OperationInfo operationInfo, AsyncManager manager);

class AsyncManagerKey {
  final String key;

  AsyncManagerKey(this.key);
}

/// Use this widget to define an AsyncManager
/// and build a widget tree based on the current
/// state of operations run inside that manager.
///
/// The defined async manager is not added to the global
/// container and therefore can only be accessed
/// from inside the [builder].
///
/// ##HINT:
/// This widget is still under development and should
/// only be used in non-sensitive environment.
class AsyncManagerWidget extends StatefulWidget {
  final AsyncManagerBuilder builder;
  final AsyncManager manager;

  /// Define if you want manually start the manager (false),
  /// or if it should be run on initState (true).
  /// To manually start, call [runOperation] on this widget.
  final bool instantLoad;

  AsyncManagerWidget(
      {@required this.manager,
      @required this.builder,
      @required this.instantLoad});

  @override
  _AsyncManagerWidgetState createState() => _AsyncManagerWidgetState();
}

class _AsyncManagerWidgetState extends State<AsyncManagerWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(this, widget.manager.operationInfo, widget.manager);
  }

  @override
  void initState() {
    super.initState();

    widget.manager.markAsInternal(true);

    AsyncManager.registerAnchor(Anchor(
        operationActionNotifier: (opac) {
          if (!mounted) return;
          setState(() {});
        },
        callback: (state) {},
        callbackInstancesActive: (cia, ct) {
          if (!mounted) return;
          setState(() {});
        },
        child: widget,
        operationNotifier: (opinfo) {
          if (!mounted) return;
          setState(() {});
        }));

    if (!widget.instantLoad) return;

    runOperation();
  }

  void runOperation() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.manager.runOperation();
    });
  }
}

/// Wrap your widget with this widget to get notified
/// about when any async operation is done that
/// is sent by this widget.
///
/// Example:
/// Tapping on a widget running an AsyncManager
/// can change it's state.
/// A button saying 'Load data' can load some data,
/// and as long as the asyncOp is running, the button
/// can say 'Loading...'
///
/// The [child]'s builder has a boolean param, true if
/// any operation belongs to this widget, false
/// otherwise. Also it has the current operationInfo
class AsyncNotificationWidget extends StatefulWidget {
  final AsyncManagerNotificationBuilder child;
  final AsyncManagerKey hookKey;

  AsyncNotificationWidget({this.child, this.hookKey});

  @override
  _AsyncNotificationWidgetState createState() =>
      _AsyncNotificationWidgetState();
}

class _AsyncNotificationWidgetState extends State<AsyncNotificationWidget> {
  bool contains = false;
  OperationInfo _opInfo;
  AsyncManager _manager;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child(contains, _opInfo, _manager),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    AsyncManager.registerAnchor(Anchor(callback: (state) {
      if (!mounted) return;
      setState(() {
        _inform(state);
      });
    }, callbackInstancesActive: (state, count) {
      _inform(state);
    }, operationActionNotifier: (opaction) {
      setState(() {
        _inform(true);
      });
    }, operationNotifier: (opinfo) {
      setState(() {
        _inform(true);
      });
    }));
  }

  void _inform(bool state) {
    if (AsyncManager.instances != null) {
      for (AsyncManager operation in AsyncManager.instances.values) {
        if (operation.hookKey != null) {
          if (operation.hookKey.key == widget.hookKey.key) {
            contains = state;
            _opInfo = operation.operationInfo;
            _manager = operation;
            return;
          }
        }
      }
      _opInfo = null;
      contains = false;
    }
  }
}
