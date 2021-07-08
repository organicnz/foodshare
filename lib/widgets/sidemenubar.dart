import 'package:flutter/material.dart';
import 'package:foodshare/helpers/appcolors.dart';
import 'package:foodshare/helpers/iconhelper.dart';
import 'package:foodshare/helpers/utils.dart';
// import 'package:foodshare/services/categoryselectionservice.dart';
import 'package:foodshare/services/categoryservice.dart';
import 'package:foodshare/services/loginservice.dart';
import 'package:foodshare/widgets/iconfont.dart';
import 'package:provider/provider.dart';

class SideMenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LoginService loginService =
        Provider.of<LoginService>(context, listen: false);
    CategoryService categoryService =
        Provider.of<CategoryService>(context, listen: false);

    bool userLoggedIn = loginService.loggedInUserModel != null;

    return Scaffold(
        body: Container(
            padding: EdgeInsets.all(50),
            color: AppColors.MAIN_COLOR,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    TextButton(
                        onPressed: () async {
                          if (userLoggedIn) {
                            await loginService.signOut();
                            categoryService.resetCategoriesToDefaults();
                            Utils.mainAppNav.currentState!
                                .pushReplacementNamed('/welcomepage');
                          } else {
                            bool success =
                                await loginService.signInWithGoogle();
                            if (success) {
                              Utils.mainAppNav.currentState!
                                  .pushNamed('/mainpage');
                            }
                          }
                        },
                        child: Row(
                          children: [
                            Icon(userLoggedIn ? Icons.logout : Icons.login,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(userLoggedIn ? 'Exit' : 'Entrar',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))
                          ],
                        )),
                    SizedBox(height: 10),
                    Visibility(
                        visible: !userLoggedIn,
                        child: TextButton(
                            onPressed: () async {
                              Utils.mainAppNav.currentState!
                                  .pushNamed('/welcomepage');
                            },
                            child: Row(
                              children: [
                                Icon(Icons.home, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Bienvenido/a',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20))
                              ],
                            )))
                  ],
                ),
                IconFont(
                    iconName: IconFontHelper.LOGO,
                    size: 70,
                    color: Colors.white)
              ],
            )));
  }
}
