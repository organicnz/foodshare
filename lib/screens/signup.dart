import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodshare/screens/home_page.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _email, _password, _name;

  checkAuthentication() async {
    _auth.authStateChanges.listen(
      (user) async {
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentication();
  }

  signUp() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      try {
        FirebaseUser user = await _auth.createUserWithEmailAndPassword(
            email: _email, password: _password);
        if (user != null) {
          UserUpdateInfo updateuser = UserUpdateInfo();
          updateuser.displayName = _name;
          user.updateProfile(updateuser);
        }
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
                                return 'Enter Name';
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            onSaved: (input) => _name = input!),
                      ),
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
                        onPressed: signUp,
                        child: Text(
                          'SignUp',
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
            ],
          ),
        ),
      ),
    );
  }
}
