import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:taskify/screens/add_task_sheet.dart';
import 'package:taskify/firebase_options.dart';
import 'registration/login_screen.dart';
import 'screens/start_screen.dart';
import 'screens/onboarding_screen.dart';
import 'registration/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart'; 
import 'screens/profile_screen.dart';
import 'screens/shared_todo/shared_todo.dart';
import 'screens/focus_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const MyApp());
  
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskify',
      debugShowCheckedModeBanner: false,
      initialRoute: '/loginscreen',
      routes: {
       // '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/loginscreen': (context) => const LoginScreen(),
        '/startscreen': (context) => const StartScreen(),
        '/registerscreen': (context) => const RegisterScreen(),
        '/homescreen': (context) => const HomeScreen(), 
        '/profilescreen': (context) => const ProfileScreen(),
        '/sharedtodo': (context) =>  SharedTodoScreen(),
         '/focus': (context) => const FocusScreen(),
      },
    );
  }
}
