import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_all/webview_all.dart';

const String _defaultProdUrl = 'https://wateja.phoisec.com';

String getConfiguredBaseUrl() {
  const fromDefine = String.fromEnvironment(
    'WATEJA_BASE_URL',
    defaultValue: '',
  );

  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }

  final fromDotEnv = dotenv.env['WATEJA_BASE_URL'];
  if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
    return fromDotEnv;
  }

  return _defaultProdUrl;
}

int getSplashDurationMs() {
  const fromDefine = String.fromEnvironment(
    'SPLASH_DURATION_MS',
    defaultValue: '',
  );

  if (fromDefine.isNotEmpty) {
    final parsed = int.tryParse(fromDefine);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
  }

  final fromDotEnv = dotenv.env['SPLASH_DURATION_MS'];
  if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
    final parsed = int.tryParse(fromDotEnv);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
  }

  return 1800;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const WatejaApp());
}

class WatejaApp extends StatelessWidget {
  const WatejaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wateja',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C7C54)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final splashMs = getSplashDurationMs();
    Timer(Duration(milliseconds: splashMs), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WatejaWebViewScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E3B2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Wateja',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Loading marketplace...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatejaWebViewScreen extends StatefulWidget {
  const WatejaWebViewScreen({super.key});

  @override
  State<WatejaWebViewScreen> createState() => _WatejaWebViewScreenState();
}

class _WatejaWebViewScreenState extends State<WatejaWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';

  String get _initialUrl => getConfiguredBaseUrl();

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFffffff))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = '';
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Unable to load Wateja. Please check your connection and try again.';
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            final allowed = url.startsWith('http://localhost:5173') ||
                url.startsWith('http://127.0.0.1:') ||
                url.startsWith('https://wateja.phoisec.com') ||
                url.startsWith('https://www.phoisec.com') ||
                url.startsWith('https://') ||
                url.startsWith('http://');

            return allowed ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  Future<void> _reloadWebView() async {
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading Wateja...'),
                  ],
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _reloadWebView,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
