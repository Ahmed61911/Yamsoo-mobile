import 'dart:async';
import 'package:flutter/material.dart';

const Color ysPrimary = Color(0xFF2F3B69);
const Color ysPrimaryLight = Color(0xFF6E7FA6);
const Color ysBackground = Color(0xFFF3F0E7);
const Color ysSurface = Color(0xFFF8F6EF);
const Color ysText = Color(0xFF2C3553);
const Color ysMuted = Color(0xFF707B97);
const Color ysBorder = Color(0xFFD8D3C7);

class OfflinePage extends StatefulWidget {
  final VoidCallback onRetry;
  final bool isRetrying;

  const OfflinePage({
    super.key,
    required this.onRetry,
    required this.isRetrying,
  });

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  static const int timeoutSeconds = 20;

  int remaining = timeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    remaining = timeoutSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (widget.isRetrying) return;

      if (remaining <= 1) {
        timer.cancel();
        widget.onRetry();
      } else {
        setState(() => remaining--);
      }
    });
  }

  void _manualRetry() {
    _timer?.cancel();
    widget.onRetry();
  }

  @override
  void didUpdateWidget(covariant OfflinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isRetrying && oldWidget.isRetrying) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _hintRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ysBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ysBorder),
          ),
          child: Icon(icon, size: 20, color: ysText),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: ysText,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ysBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ysPrimary, ysPrimaryLight],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "No internet connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: ysText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Check your Wi-Fi or mobile data, then try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: ysMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Retrying automatically in $remaining s",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ysMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ysSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ysBorder),
                  ),
                  child: Column(
                    children: [
                      _hintRow(Icons.router_outlined, "Turn Wi-Fi off and on"),
                      const SizedBox(height: 10),
                      _hintRow(Icons.signal_cellular_alt_outlined, "Check your mobile network"),
                      const SizedBox(height: 10),
                      _hintRow(Icons.refresh_rounded, "Tap Retry to try again now"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ysPrimary, ysPrimaryLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ysPrimary.withOpacity(0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.isRetrying ? null : _manualRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: widget.isRetrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              "Retry",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}