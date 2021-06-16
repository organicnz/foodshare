import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:foodshare/screens/login.dart';
import 'signup.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Start extends StatefulWidget {
  @override
  _StartState createState() => _StartState();
}

class _StartState extends State<Start> {
  navigateToLogin() async {
    Navigator.push(
      context,
      MeterialPageRoute(
        builder: (context) => Login(),
      ),
    );
    navigateToRegister() async {
      Navigator.push(
        context,
        MeterialPageRoute(
          builder: (context) => SignUp(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 35.0,
            ),
            Container(
              height: 400,
              child: Image(
                image: AssetImage('assets/images/start.jpg'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            RichText(
              text: TextSpan(
                text: 'Welcome to ',
                style: TextStyle(
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'FoodShare',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5.0,
            ),
            Text(
              'food rescuing app',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: navigateToLogin,
                  child: Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    primary: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(
                  width: 20.0,
                ),
                ElevatedButton(
                  onPressed: navigateToRegister,
                  child: Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    primary: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            SignInButton(
              Buttons.Google,
              text: "Sign up with Google",
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}
