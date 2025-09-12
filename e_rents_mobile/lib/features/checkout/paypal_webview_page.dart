import 'package:e_rents_mobile/features/checkout/providers/checkout_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalWebViewPage extends StatefulWidget {
  final String approvalUrl;
  final String orderId;

  const PaypalWebViewPage({
    super.key,
    required this.approvalUrl,
    required this.orderId,
  });

  @override
  State<PaypalWebViewPage> createState() => _PaypalWebViewPageState();
}

class _PaypalWebViewPageState extends State<PaypalWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // Detect PayPal cancel
            if (_isCancelUrl(url)) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            // Detect our backend return URLs (they may be localhost which won't load on device)
            if (_isReturnUrl(url)) {
              _captureAndClose();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  bool _isReturnUrl(String url) {
    // Backend currently uses these placeholders; match generously
    return url.startsWith('http://localhost:5000/capture') ||
        url.startsWith('https://localhost:5001/capture') ||
        url.startsWith('http://localhost:5000/api/payments/return') ||
        url.startsWith('https://localhost:5001/api/payments/return');
  }

  bool _isCancelUrl(String url) {
    return url.contains('/cancel') || url.contains('cancel=true');
  }

  Future<void> _captureAndClose() async {
    try {
      final provider = context.read<CheckoutProvider>();
      await provider.capturePayPalOrder(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Approval'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
