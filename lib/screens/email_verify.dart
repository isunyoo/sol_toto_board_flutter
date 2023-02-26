import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eth_toto_board_flutter/boardmain.dart';
import 'package:eth_toto_board_flutter/screens/login.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:eth_toto_board_flutter/utilities/authenticator.dart';

class EmailVerifyPage extends StatefulWidget {
  final User user;
  const EmailVerifyPage({Key? key, required this.user}) : super(key: key);

  @override
  _EmailVerifyPageState createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  bool _isSendingVerification = false;
  bool _isSigningOut = false;
  late User _currentUser;

  @override
  void initState() {
    _currentUser = widget.user;
    super.initState();
    // Request a Navigator operation if Email verified
    _launchBoardMain();
  }

  void _launchBoardMain() {
    if(_currentUser.emailVerified) {
      // The delay to route BoardMain Page Scaffold
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        // Navigate to the main screen using a named route.
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BoardMain()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SigningOut Status Parameter
    _isSigningOut;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Ethereum Toto(6/45)',
              style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25.0),
            Text(
              'NAME: ${_currentUser.displayName}',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 16.0),
            Text(
              'EMAIL: ${_currentUser.email}',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 20.0),
            // Email not verified showing following widgets
            if(_currentUser.emailVerified == false)
              Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Text("Refresh Email Verification Status"),
                          IconButton(icon: const Icon(Icons.refresh), onPressed: () async {
                            User? user = await FireAuth.refreshUser(_currentUser);
                            if (user != null) {
                              setState(() {
                                _currentUser = user;
                              });
                            }
                            // If(user?.emailVerified == true) then route BoardMain Page Scaffold
                            _launchBoardMain();
                          },),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text('Email not verified', style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),),
                        ]
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _isSendingVerification ? const CircularProgressIndicator() : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() { _isSendingVerification = true; });
                                  await _currentUser.sendEmailVerification();
                                  setState(() { _isSendingVerification = false; });
                                },
                                child: const Text('Verify Email'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
          icon: Icons.menu,
          backgroundColor: Colors.blueAccent,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.exit_to_app),
              label: 'Logout',
              backgroundColor: Colors.blue,
              onTap: () async {
                setState(() {
                  _isSigningOut = true;
                });
                await FirebaseAuth.instance.signOut();
                await FireAuth.signOutWithGoogle(context: context);
                setState(() {
                  _isSigningOut = false;
                });
                // Navigate Push Replacement which will not going back and return back to the LoginPage
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => const LoginPage()));
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.menu_rounded),
              label: 'Main',
              backgroundColor: Colors.blue,
              onTap: () {
                // If(user?.emailVerified == true) then route BoardMain Page Scaffold
                _launchBoardMain();
              },
            ),
          ]
      ),
    );
  }
}


