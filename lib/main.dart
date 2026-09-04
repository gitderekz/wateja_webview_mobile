import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

const String _defaultDevUrl = 'http://localhost:5173';
const String _defaultProdUrl = 'https://wateja.phoisec.com';

String getConfiguredBaseUrl() {
  const fromEnvironment = String.fromEnvironment(
    'WATEJA_BASE_URL',
    defaultValue: '',
  );

  if (fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }

  final isProduction = bool.fromEnvironment(
    'APP_ENV',
    defaultValue: false,
  );

  return isProduction ? _defaultProdUrl : _defaultDevUrl;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const WatejaWebViewScreen(),
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
