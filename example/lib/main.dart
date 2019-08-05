import 'package:flutter/material.dart';
import 'package:async_manager/async_manager.dart';
import 'package:async_manager/anchor.dart';
import 'package:async_manager/async_manager_widget.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreenPage());
  }
}

class HomeScreenPage extends StatefulWidget {
  @override
  _HomeScreenPageState createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  @override
  void initState() {
    super.initState();

    _anchorToAsyncManager();
  }

  void _anchorToAsyncManager() {
    AsyncManager.registerAnchor(Anchor(callback: (state) {
      setState(() {});
    }, callbackInstancesActive: (count, state) {
      setState(() {});
    }, operationNotifier: (opinfo) {
      setState(() {});
    }, operationActionNotifier: (opaction) {
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AsyncManager sample app'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  'Here you can see if any operation is running, and information about'),
            ),
            SizedBox(
              height: 12,
            ),
          ]..addAll([_buildNotificationWidget(SettingsPage.HookKey)]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => SettingsPage()));
          }),
    );
  }

  Widget _buildNotificationWidget(String key) {
    return AsyncNotificationWidget(
      hookKey: AsyncManagerKey(key),
      child: (state, info, manager) {
        return state
            ? Column(
                children: <Widget>[
                  Text(info.title),
                  Text(
                    info.description,
                    style: TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                ]..addAll([
                    if (manager.operationActions != null &&
                        manager.operationActions.length > 0)
                      for (OperationAction a in manager.operationActions)
                        RaisedButton(
                          shape: RoundedRectangleBorder(),
                          child: Text('Need your patience!'),
                          onPressed: () {
                            a.showOperationAction();
                          },
                        )
                  ]),
              )
            : Container();
      },
    );
  }
}

class SettingsPage extends StatefulWidget {
  static const String HookKey = 'ad-async-manager';

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isOnScreen = true;

  @override
  void dispose() {
    isOnScreen = false;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Remove all ads in this session'),
              subtitle: Text(
                  'Watch a video and remove all ads until you restart the app.'),
              onTap: _createAsyncManagerAdRemove,
            ),
            AsyncManagerWidget(
                manager: _createAsyncManagerRefreshData(),
                instantLoad: false,
                builder: (amw, operationInfo, manager) {
                  return ListTile(
                    title: Text(operationInfo.title),
                    subtitle: Text(operationInfo.description),
                    onTap: () {
                      amw.runOperation();
                    },
                    trailing: operationInfo.state == OperationState.Started
                        ? CircularProgressIndicator()
                        : null,
                  );
                }),
          ],
        ),
      ),
    );
  }

  AsyncManager _createAsyncManagerRefreshData() {
    return AsyncManager(
      operation: (aman) {
        return Future.delayed(Duration(seconds: 2)).then((_) {
          aman.notifyOperationInfo(
            OperationInfo(
              title: 'Only a few bytes',
              description: 'We are not done yet.',
            ),
          );
          return Future.delayed(Duration(seconds: 3)).then((_) {
            aman.notifyOperationInfo(
              OperationInfo(
                title: 'Just a few seconds.',
                description: 'The data is processed by us.',
              ),
            );

            return Future.delayed(Duration(seconds: 4)).then((_) {
              aman.notifyOperationInfo(
                OperationInfo(
                  title: 'Here is your data',
                  description: 'Here is your new dummy data.',
                ),
              );
              return OperationInfo();
            });
          });
        });
      },
      operationInfo: OperationInfo(
          title: "Dummy data",
          description: 'This is dummy data (click to refresh internally)'),
    );
  }

  void _createAsyncManagerAdRemove() async {
    AsyncManager manager = AsyncManager(
        operation: _buildOperation,
        operationInfo: OperationInfo(
            title: 'Settings: preparing for ads...',
            description: 'Ad is loaded in about a second'),
        hookKey: AsyncManagerKey(SettingsPage.HookKey));

    await manager.runOperation();

    _showAdDummy();
  }

  Future<OperationInfo> _buildOperation(AsyncManager aman) async {
    //create dummy ad loading
    return Future.delayed(Duration(seconds: 1)).then((_) {
      //inform every anchor about the new state
      aman.notifyOperationInfo(
        OperationInfo(
          title: 'Settings: Now loading ad',
          description: 'You will get a notification if ad is available.',
        ),
      );
      return Future.delayed(Duration(seconds: 2)).then((_) {
        //inform the user that the ad was loaded.
        aman.notifyOperationInfo(
          OperationInfo(
            title: 'Ad is available',
            description: 'You can watch the ad now.',
          ),
        );

        //fire action to let the user watch the ad IF NOT ON SETTINGS SCREEN.
        //but if on screen and the ads are displayed, the operation will automatically
        //be hidden from all anchors.
        //first, check if on screen to not display the action.
        if (isOnScreen) {
          return OperationInfo();
        }
        aman.notifyOperationAction(
          OperationAction(
            description: 'The ad was loaded. You can now watch the ad.',
            asyncManager: aman,
            operation: (_) async {
              //the user interacted with an operation action.
              //here, you can display a dialog or snackbar.
              await Future.doWhile(() {
                //this is just a dummy future
                return false;
              });
              return OperationInfo();
            },
          ),
        );

        return OperationInfo();
      });
    });
  }

  void _showAdDummy() {
    print("Ad is now being displayed ");
  }
}
