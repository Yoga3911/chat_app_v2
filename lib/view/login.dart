import 'package:chat/service/auth_provider.dart';
import 'package:chat/view/register.dart';
import 'package:chat/view/wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _email;
  late TextEditingController _password;
  bool isVisible = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference user =
        FirebaseFirestore.instance.collection("user");
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Simple Chat App",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: isVisible ? false : true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                      onPressed: () => setState(() {
                            isVisible = !isVisible;
                          }),
                      icon: isVisible
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off)),
                  hintText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await auth
                      .login(
                    email: _email.text,
                    password: _password.text,
                  )
                      .then(
                    (value) async {
                      final dataUser = await user
                          .where("email", isEqualTo: _email.text)
                          .get();
                      final data =
                          (dataUser.docs.first.data() as Map<String, dynamic>);
                      final pref = await SharedPreferences.getInstance();
                      pref.setString("id", data["id"]);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Wrapper(id: data["id"]),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
                child: const Text("Login"),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                ),
                child: const Text("Register"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
