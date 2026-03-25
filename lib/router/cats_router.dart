import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router catsRouter(Connection conn) {
  final router = Router();

  router.get('/', (Request req) async {
    try {
      final result = await conn.execute('SELECT * FROM cats;');
      final list = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(
        jsonEncode(list),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  });
  router.get('/<id>', (Request request, String id) async {
    try {
      final result = await conn.execute(
        Sql.named('SELECT * FROM cats WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      final cats = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(
        jsonEncode(cats.first),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  router.delete('/<id>', (Request request, String id) async {
    try {
      await conn.execute(
        Sql.named('DELETE FROM cats WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      return Response.ok(
        'Удален',
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/', (Request req) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body);

      final result = await conn.execute(
        Sql.named(
          'INSERT INTO cats (name, image_url) '
          'VALUES (@name, @imageUrl) RETURNING id',
        ),
        parameters: {'name': data['name'], 'imageUrl': data['imageUrl']},
      );

      return Response.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  router.put('/<id>', (Request req, String id) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body);

      final result = await conn.execute(
        Sql.named(
          'UPDATE cats SET '
          'name = @name, '
          'image_url = @imageUrl, '
          'WHERE id = @id RETURNING *',
        ),
        parameters: {
          'id': int.parse(id),
          'name': data['name'],
          'imageUrl': data['imageUrl'],
        },
      );

      if (result.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Cats not found'}));
      }

      return Response.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  return router;
}
