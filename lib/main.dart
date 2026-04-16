import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stayresto/widgets/app_theme.dart';

import 'features/hotel_search/presentation/pages/Wishlist_bloc.dart';
import 'features/hotel_search/presentation/pages/firebase_pages/auth_page.dart';
import 'features/hotel_search/presentation/pages/firebase_pages/firebase_auth_services.dart';
import 'injection_container.dart' as di;
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPreferences.getInstance();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<WishlistBloc>(create: (_) => WishlistBloc()),
          ],
          child: MaterialApp(
            title: 'Flutter Demo',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<User?>(
              stream: AuthService.userStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = snapshot.data;

                if (user != null) {
                  if (user.emailVerified) {
                    return const MainShell();
                  } else {
                    return const AuthPage();
                  }
                } else {
                  return const AuthPage();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
