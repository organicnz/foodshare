import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/pages/detailspage.dart';
import 'package:foodshare/pages/mainpage.dart';
import 'package:foodshare/pages/mappage.dart';
import 'package:foodshare/pages/onboardingpage.dart';
import 'package:foodshare/pages/selectedcategorypage.dart';
import 'package:foodshare/pages/splashpage.dart';
import 'package:foodshare/pages/welcomepage.dart';
import 'package:foodshare/services/cartservice.dart';
import 'package:foodshare/services/categoryselectionservice.dart';
import 'package:foodshare/services/categoryservice.dart';
import 'package:foodshare/services/loginservice.dart';
import 'package:provider/provider.dart';

import 'helpers/utils.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginService()),
        ChangeNotifierProvider(create: (_) => CategorySelectionService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider(create: (_) => CategoryService())
      ],
      child: MaterialApp(
        navigatorKey: Utils.mainAppNav,
        theme: ThemeData(fontFamily: 'Raleway'),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => SplashPage(duration: 3, goToPage: '/welcomepage'),
          '/welcomepage': (context) => WelcomePage(),
          '/mainpage': (context) => MainPage(),
          '/selectedcategorypage': (context) => SelectedCategoryPage(),
          '/detailspage': (context) => DetailsPage(),
          '/mappage': (context) => MapPage(),
          '/onboardingpage': (context) => OnboardingPage(),
        },
      ),
    ),
  );
}
