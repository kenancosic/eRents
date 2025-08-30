import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';

class PaypalWebViewScreen extends StatefulWidget {
  final String approvalUrl;

  const PaypalWebViewScreen({super.key, required this.approvalUrl});

  @override
  State<PaypalWebViewScreen> createState() => _PaypalWebViewScreenState();
}

class _PaypalWebViewScreenState extends State<PaypalWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check for the success URL from the backend
            if (request.url.startsWith('http://localhost:5000/capture')) {
              // Pop the webview and return success
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            // Check for the cancel URL from the backend
            if (request.url.startsWith('http://localhost:5000/cancel')) {
              // Pop the webview and return failure
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Complete Payment',
        showBackButton: true,
        onBackButtonPressed: () => Navigator.of(context).pop(false),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
