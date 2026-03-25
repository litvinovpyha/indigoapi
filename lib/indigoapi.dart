import 'package:indigoapi/core/env.dart';
import 'package:indigoapi/router/brand_router.dart';
import 'package:indigoapi/router/cats_router.dart';
import 'package:indigoapi/router/line_router.dart';
import 'package:indigoapi/router/product_router.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;

final host = getEnv('DB_HOST');
final db = getEnv('DB_NAME');
final user = getEnv('DB_USER');
final pw = getEnv('DB_PASSWORD');
void server() async {
  final conn = await Connection.open(
    Endpoint(host: host, database: db, username: user, password: pw),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  final api = Router();
  api.mount('/api/brands', brandRouter(conn).call);
  api.mount('/api/lines', lineRouter(conn).call);
  api.mount('/api/cats', catsRouter(conn).call);
  api.mount('/api/products', productRouter(conn).call);

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(api.call);
  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
}
