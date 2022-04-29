import 'package:chat/model/user_mode.dart';
import 'package:chat/service/auth_provider.dart';
import 'package:chat/view/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _username;
  late TextEditingController _email;
  late TextEditingController _password;
  bool isVisible = false;

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DocumentReference user =
        FirebaseFirestore.instance.collection("user").doc();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  hintText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
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
                  hintText: "Password",
                  suffixIcon: IconButton(
                      onPressed: () => setState(() {
                            isVisible = !isVisible;
                          }),
                      icon: isVisible
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await auth
                      .register(
                    email: _email.text,
                    password: _password.text,
                  )
                      .then(
                    (_) async {
                      user.set(
                        UserModel(
                          id: user.id,
                          username: _username.text,
                          email: _email.text,
                          password: _password.text,
                          image:
                              "https://firebasestorage.googleapis.com/v0/b/chat-8dd7b.appspot.com/o/squid.png?alt=media&token=ff9be96f-5e8e-40ad-87b5-c8a5bf2c4d42",
                          isActive: false,
                        ).toJson(),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
                child: const Text("Register"),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text("Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
