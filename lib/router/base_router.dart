import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

abstract class BaseRouter {
  final Connection conn;
  final String tableName;

  BaseRouter(this.conn, this.tableName);

  Future<Result> insertQuery(Map<String, dynamic> data);
  Future<Result> updateQuery(String id, Map<String, dynamic> data);

  Router get router {
    final router = Router();

    router.get('/', (Request req) async {
      try {
        final result = await conn.execute('SELECT * FROM $tableName;');
        final items = result.map((row) => row.toColumnMap()).toList();
        return Response.ok(
          jsonEncode(items),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        throw Exception(e.toString());
      }
    });
    // GET ALL   

    // GET ONE
    router.get('/<id>', (Request req, String id) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM $tableName WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      if (result.isEmpty) return Response.notFound('Not found');
      return Response.ok(
        jsonEncode(result.first.toColumnMap()),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // DELETE
    router.delete('/<id>', (Request req, String id) async {
      await conn.execute(
        Sql.named('DELETE FROM $tableName WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      return Response.ok(
        'Deleted',
        headers: {'Content-Type': 'application/json'},
      );
    });

    // POST
    router.post('/', (Request req) async {
      final data = jsonDecode(await req.readAsString());
      final result = await insertQuery(data);
      return Response.ok(
        jsonEncode(result.first.toColumnMap()),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // PUT
    router.put('/<id>', (Request req, String id) async {
      final data = jsonDecode(await req.readAsString());
      final result = await updateQuery(id, data);
      if (result.isEmpty) return Response.notFound('Not found');
      return Response.ok(
        jsonEncode(result.first.toColumnMap()),
        headers: {'Content-Type': 'application/json'},
      );
    });

    return router;
  }
}
