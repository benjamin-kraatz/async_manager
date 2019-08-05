library async_manager;

import 'package:async_manager/anchor.dart';
import 'package:async_manager/async_manager.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

typedef AsyncManagerBuilder = Widget Function(OperationInfo info);
typedef AsyncManagerNotificationBuilder = Widget Function(bool containsAchor);

class AsyncManagerKey {
  final String key;

  AsyncManagerKey(this.key);
}

/// Use this widget to build a widget tree based on
/// all pending and executing AsyncManagers
class AsyncManagerWidget extends StatefulWidget {
  final AsyncManagerBuilder builder;
  final AsyncManager operation;

  AsyncManagerWidget({@required this.operation, @required this.builder});

  @override
  _AsyncManagerWidgetState createState() => _AsyncManagerWidgetState();
}

class _AsyncManagerWidgetState extends State<AsyncManagerWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(widget.operation.operationInfo);
  }

  @override
  void initState() {
    super.initState();

    widget.operation.markAsInternal(true);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.operation.runOperation();
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
/// otherwise.
class AsyncNotificationWidget extends StatefulWidget {
  final AsyncManagerNotificationBuilder child;
  final Widget sender;
  final AsyncManagerKey hookKey;

  AsyncNotificationWidget({this.child, this.sender, this.hookKey});

  @override
  _AsyncNotificationWidgetState createState() =>
      _AsyncNotificationWidgetState();
}

class _AsyncNotificationWidgetState extends State<AsyncNotificationWidget> {
  bool contains = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child(contains),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    AsyncManager.registerAnchor(Anchor(callback: (state) {
      if (!mounted) return;
      setState(
        () {
          if (AsyncManager.instances != null) {
            for (AsyncManager operation in AsyncManager.instances.values) {
              if (operation.hookKey != null) {
                if (operation.hookKey.key == widget.hookKey.key) {
                  contains = state;
                  return;
                }
              }
            }
            contains = false;
          }
        },
      );
    }));
  }
}
