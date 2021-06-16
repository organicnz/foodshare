import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/home_page.dart';
import 'package:foodshare/screens/signup.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _email, _password;

  checkAuthentification(async) {
    _auth.authStateChanges().listen(
      (User? user) {
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => "HomePage"(),
            ),
          );
        }
      },
    );

    @override
    void initState() {
      super.initState();
      this.checkAuthentification();
    }
  }

  login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        FirebaseUser user = await _auth.signInWithEmailAndPassword(
            email: _email, password: _password);
      } catch (e) {
        showError(e.errormessage);
      }
    }
  }

  showError(String errormessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ERROR'),
          content: Text(errormessage),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
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
        );
      },
    );
  }

  navigateToSignUp() async {
    Navigator.push(context, MeterialPageRoute(builder: (context) => SignUp()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 400,
                child: Image(
                  image: AssetImage('assets/images/login.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
              Container(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: TextFormField(
                            validator: (input) {
                              if (input!.isEmpty) {
                                return 'Enter Email';
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            onSaved: (input) => _email = input!),
                      ),
                      Container(
                        child: TextFormField(
                            validator: (input) {
                              if (input!.length < 6) {
                                return 'Provide Minimum 6 Character';
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            onSaved: (input) => _password = input!),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      ElevatedButton(
                        onPressed: login,
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
                            left: 70.0,
                            right: 10.0,
                            top: 70.0,
                            bottom: 10.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          primary: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                child: Text('Create an Account?'),
                onTap: navigateToSignUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
