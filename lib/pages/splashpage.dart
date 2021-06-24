import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/helpers/appcolors.dart';
import 'package:foodshare/helpers/iconhelper.dart';
import 'package:foodshare/helpers/utils.dart';
import 'package:foodshare/services/categoryservice.dart';
import 'package:foodshare/widgets/iconfont.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatelessWidget {
  int? duration = 0;
  String? goToPage;

  SplashPage({this.goToPage, this.duration});

  @override
  Widget build(BuildContext context) {
    CategoryService catService =
        Provider.of<CategoryService>(context, listen: false);

    Future.delayed(Duration(seconds: this.duration!), () async {
      // await for the Firebase initialization to occur
      FirebaseApp app = await Firebase.initializeApp();

      catService.getCategoriesCollectionFromFirebase().then((value) {
        Utils.mainAppNav.currentState!.pushNamed(this.goToPage!);
      });
    });

    return Material(
        child: Container(
            color: AppColors.MAIN_COLOR,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Align(
                  child: IconFont(
                      color: Colors.white,
                      iconName: IconFontHelper.LOGO,
                      size: 80),
                  alignment: Alignment.center,
                ),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.5)),
                    ),
                  ),
                )
              ],
            )));
  }
}
