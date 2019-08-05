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
            Text(
                'Here you can see if any operation is running, and information about'),
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
      child: (state, info) {
        return state
            ? Column(
                children: <Widget>[
                  Text(info.title),
                  Text(
                    info.description,
                    style: TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                ],
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
            )
          ],
        ),
      ),
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
        aman.notifyOperationAction(OperationAction(
            description: 'The ad was loaded. You can now watch the ad.',
            operation: (aman) async {
              //Display the ad...
              _showAdDummy();
              return OperationInfo();
            }));

        return OperationInfo();
      });
    });
  }

  void _showAdDummy() {
    print("Ad is now being displayed.");
  }
}
