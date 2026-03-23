import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'offline_page.dart';

const Color ysPrimary = Color(0xFF2F3B69);
const Color ysPrimaryLight = Color(0xFF6E7FA6);
const Color ysBackground = Color(0xFFF3F0E7);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const YamsooApp());
}

class YamsooApp extends StatelessWidget {
  const YamsooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YAMSOO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const YamsooWebView(),
    );
  }
}

class YamsooWebView extends StatefulWidget {
  const YamsooWebView({super.key});

  @override
  State<YamsooWebView> createState() => _YamsooWebViewState();
}

class _YamsooWebViewState extends State<YamsooWebView>
    with WidgetsBindingObserver {
  static const String startUrl = "https://yamsoo.com/";

  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;

  double _progress = 0;
  bool _isOffline = false;
  bool _isRetrying = false;
  StreamSubscription? _connectivitySub;
  Key _webViewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _requestInitialPermissions();

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: ysPrimary),
      onRefresh: () async {
        if (_controller != null) {
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            final url = await _controller!.getUrl();
            if (url != null) {
              await _controller!.loadUrl(urlRequest: URLRequest(url: url));
            }
          } else {
            await _controller!.reload();
          }
        }
      },
    );

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      if (_isRetrying) return;

      final offline = (result == ConnectivityResult.none);
      setState(() => _isOffline = offline);
    });

    _initConnectivity();
  }

  Future<void> _requestInitialPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();
  }

  Future<bool> _ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> _ensureCameraAndMicPermissions() async {
    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }

    return cameraStatus.isGranted && micStatus.isGranted;
  }

  Future<void> _initConnectivity() async {
    final ok = await _hasInternetNow();
    if (!mounted) return;
    setState(() => _isOffline = !ok);
  }

  Future<bool> _hasInternetNow() async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }

  Future<void> _openExternal(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _isSameDomain(Uri uri) => uri.host == "yamsoo.com";

  Future<void> _retry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);
    try {
      final ok = await _hasInternetNow();
      if (!mounted) return;

      if (!ok) {
        setState(() {
          _isOffline = true;
          _isRetrying = false;
        });
        return;
      }

      setState(() {
        _isOffline = false;
        _progress = 0;
        _webViewKey = UniqueKey();
      });

      await Future.delayed(const Duration(milliseconds: 150));
      await _controller?.reload();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  bool get _showLoader => !_isOffline && _progress < 1.0;

  Widget _loader() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: ysBackground,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(ysPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webViewScreen() {
    return Stack(
      children: [
        InAppWebView(
          key: _webViewKey,
          initialUrlRequest: URLRequest(url: WebUri(startUrl)),
          pullToRefreshController: _pullToRefreshController,
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useShouldOverrideUrlLoading: true,
            supportZoom: false,
            builtInZoomControls: false,
            displayZoomControls: false,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            cacheEnabled: true,
            clearCache: false,
            hardwareAcceleration: true,
            disableContextMenu: true,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
            disallowOverScroll: true,
            javaScriptCanOpenWindowsAutomatically: true,
            supportMultipleWindows: false,
            geolocationEnabled: true,
          ),
          onWebViewCreated: (controller) => _controller = controller,
          androidOnGeolocationPermissionsShowPrompt:
              (controller, origin) async {
            final granted = await _ensureLocationPermission();
            return GeolocationPermissionShowPromptResponse(
              origin: origin,
              allow: granted,
              retain: true,
            );
          },
          androidOnPermissionRequest: (controller, origin, resources) async {
            bool granted = true;

            if (resources.contains(PermissionResourceType.CAMERA) ||
                resources.contains(PermissionResourceType.MICROPHONE)) {
              granted = await _ensureCameraAndMicPermissions();
            }

            return PermissionRequestResponse(
              resources: resources,
              action: granted
                  ? PermissionRequestResponseAction.GRANT
                  : PermissionRequestResponseAction.DENY,
            );
          },
          onLoadStart: (controller, url) {
            if (mounted) setState(() => _progress = 0);
          },
          onLoadStop: (controller, url) async {
            _pullToRefreshController?.endRefreshing();

            await controller.evaluateJavascript(source: """
              (function() {
                var meta = document.querySelector('meta[name=viewport]');
                if (!meta) {
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
              })();
            """);

            if (mounted) setState(() => _isOffline = false);
          },
          onLoadError: (controller, url, code, message) {
            _pullToRefreshController?.endRefreshing();
            if (!mounted) return;
            setState(() => _isOffline = true);
          },
          onLoadHttpError: (controller, url, statusCode, description) {
            if (!mounted) return;
            if (statusCode == 0) {
              setState(() => _isOffline = true);
            }
          },
          onProgressChanged: (controller, progress) {
            final p = progress / 100.0;
            if (mounted) setState(() => _progress = p);
            if (progress == 100) _pullToRefreshController?.endRefreshing();
          },
          shouldOverrideUrlLoading: (controller, navAction) async {
            final uri = navAction.request.url?.uriValue;
            if (uri == null) return NavigationActionPolicy.ALLOW;

            if (_isSameDomain(uri)) return NavigationActionPolicy.ALLOW;

            await _openExternal(uri);
            return NavigationActionPolicy.CANCEL;
          },
        ),
        if (_showLoader) _loader(),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _isOffline
            ? OfflinePage(
                onRetry: _retry,
                isRetrying: _isRetrying,
              )
            : _webViewScreen(),
      ),
    );
  }
}
