import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;

class VideoServer {
  HttpServer? _server;
  String _assetsPath = '';
  int _port = 8080;

  Future<void> start(String assetsPath) async {
    _assetsPath = assetsPath;

    // Create a handler that serves files from the assets directory
    final handler = shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(createStaticHandler(_assetsPath,
            defaultDocument: 'index.html', serveFilesOutsidePath: true));

    try {
      _server = await io.serve(handler, 'localhost', _port);
      print('Server running on localhost:${_server!.port}');
    } catch (e) {
      print('Failed to start server: $e');
      rethrow;
    }
  }

  String getUrlForAsset(String assetPath) {
    return 'http://localhost:$_port/${assetPath.replaceAll('\\', '/')}';
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
