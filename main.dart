import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> accounts = [];

  Future<void> pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final jsonData = jsonDecode(await file.readAsString());

      if (jsonData is List) {
        setState(() {
          accounts = List<Map<String, dynamic>>.from(jsonData);
        });
      }
    }
  }

  void start() {
    if (accounts.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebPage(accounts: accounts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("eMaktab Auto Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickJson,
              child: const Text("📂 JSON yuklash"),
            ),
            const SizedBox(height: 10),
            Text("Yuklangan akkauntlar: ${accounts.length}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: start,
              child: const Text("🚀 Boshlash"),
            ),
          ],
        ),
      ),
    );
  }
}

class WebPage extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;
  const WebPage({super.key, required this.accounts});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late WebViewController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://login.emaktab.uz"))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await autoFill();
          },
        ),
      );
  }

  Future<void> autoFill() async {
    if (index >= widget.accounts.length) return;

    final login = widget.accounts[index]['login'];
    final password = widget.accounts[index]['password'];

    await controller.runJavaScript("""
      document.querySelector('input[type=text]').value = '$login';
      document.querySelector('input[type=password]').value = '$password';
    """);

    await Future.delayed(const Duration(seconds: 2));

    await controller.runJavaScript("""
      document.querySelector('button[type=submit]').click();
    """);

    // CAPTCHA uchun kutish
    await Future.delayed(const Duration(seconds: 10));

    // Yana bosish (agar captcha yechilgan bo‘lsa)
    await controller.runJavaScript("""
      document.querySelector('button[type=submit]').click();
    """);

    // Logout
    await Future.delayed(const Duration(seconds: 8));
    await controller.runJavaScript("""
      var l = document.querySelector('a[href*="logout"]');
      if (l) l.click();
    """);

    index++;

    await Future.delayed(const Duration(seconds: 5));
    controller.loadRequest(Uri.parse("https://login.emaktab.uz"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Akkaunt ${index + 1}/${widget.accounts.length}"),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}