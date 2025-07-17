import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'utils/server_config.dart';

class WebViewPage extends StatelessWidget {
  final String htmlFile;

  const WebViewPage({super.key, required this.htmlFile});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: IPConfig.getIP(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ip = snapshot.data!;
        final filePath = 'assets/html/$htmlFile';

        return Scaffold(
          appBar: AppBar(title: Text(htmlFile)),
          body: InAppWebView(
            initialFile: filePath,
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            onLoadStop: (controller, _) async {
              await controller.evaluateJavascript(
                source:
                    """
                window.backendIP = "$ip";
                console.log("Injected backend IP: " + window.backendIP);
              """,
              );
            },
          ),
        );
      },
    );
  }
}
