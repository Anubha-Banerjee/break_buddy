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

    // Create the static file handler
    final staticHandler = createStaticHandler(_assetsPath,
        defaultDocument: 'index.html', serveFilesOutsidePath: true);

    // Wrap with CORS headers
    final handler = (shelf.Request request) async {
      // Handle CORS preflight requests
      if (request.method == 'OPTIONS') {
        return shelf.Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS, POST, PUT',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Max-Age': '86400',
        });
      }

      // Call the static handler and add CORS headers to response
      final response = await staticHandler(request);
      return response.change(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      );
    };

    final logHandler = shelf.logRequests()(handler);

    try {
      _server = await io.serve(logHandler, 'localhost', _port);
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
