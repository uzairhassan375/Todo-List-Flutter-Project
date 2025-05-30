import 'package:firebase_auth/firebase_auth.dart';

class Auth{
  FirebaseAuth _auth = FirebaseAuth.instance;
  Future<User?> signUpWithEmailAndPassword(String Email, String Password) async {
    try{
      UserCredential credential =await _auth.createUserWithEmailAndPassword(email: Email, password: Password);
      return credential.user;
    }catch (e){
      print("Some error occured $e");
    }
    return null;
    }
     Future<User?> signInWithEmailAndPassword(String Email, String Password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: Email,
        password: Password,
      );
      return credential.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }
  }


