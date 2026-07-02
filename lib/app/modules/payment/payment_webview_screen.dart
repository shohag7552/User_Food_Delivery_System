// lib/screens/payment_webview_screen.dart

import 'package:appwrite_user_app/app/appwrite/payment_service.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

enum PaymentResult { success, failed, cancelled }

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentURL;
  final String gatewayName;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentURL,
    required this.gatewayName,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  double _progress = 0;
  InAppWebViewController? _controller;
  bool _resultHandled = false;

  void _checkURL(String? urlString) {
    if (urlString == null || _resultHandled) return;

    if (urlString.startsWith(PaymentService.successURL)) {
      _resultHandled = true;
      context.pop(PaymentResult.success);
    } else if (urlString.startsWith(PaymentService.failURL)) {
      _resultHandled = true;
      context.pop(PaymentResult.failed);
    } else if (urlString.startsWith(PaymentService.cancelURL)) {
      _resultHandled = true;
      context.pop(PaymentResult.cancelled);
    }
  }

  Future<bool> _onBackPressed() async {
    // Check if web view can go back within the payment flow
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }

    // Show confirmation dialog before cancelling payment
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Your payment is not complete. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed();
        if (shouldPop && context.mounted) {
          context.pop(PaymentResult.cancelled);
        }
      },
      child: Scaffold(
        appBar: CustomAppbar(
          title: 'Pay with ${widget.gatewayName}',
          showBackButton: true,
          onBackButtonPressed: () async {
            final shouldLeave = await _onBackPressed();
            if (shouldLeave && context.mounted) {
              context.pop(PaymentResult.cancelled);
            }
          },
        ),
        body: Column(
          children: [
            // Progress indicator bar
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorResource.primaryDark,
                ),
              ),
            Expanded(
              child: _hasError
                  ? _buildErrorWidget()
                  : Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest:
                              URLRequest(url: WebUri(widget.paymentURL)),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            domStorageEnabled: true,
                            useShouldOverrideUrlLoading: true,
                            supportZoom: false,
                            clearCache: true,
                          ),
                          onWebViewCreated: (controller) =>
                              _controller = controller,
                          onLoadStart: (controller, url) {
                            _checkURL(url.toString());
                          },
                          onLoadStop: (controller, url) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                            _checkURL(url.toString());
                          },
                          onProgressChanged: (controller, progress) {
                            if (mounted) {
                              setState(() => _progress = progress / 100);
                            }
                          },
                          onReceivedError: (controller, request, error) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _hasError = true;
                              });
                            }
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            final url =
                                navigationAction.request.url.toString();
                            _checkURL(url);
                            return NavigationActionPolicy.ALLOW;
                          },
                        ),
                        if (_isLoading && _progress == 0)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Failed to load payment page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                  _progress = 0;
                });
                _controller?.reload();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(PaymentResult.cancelled),
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
