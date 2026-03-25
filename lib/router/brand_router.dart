import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router brandRouter(Connection conn) {
  final router = Router();

  router.get('/', (Request req) async {
    try {
      final result = await conn.execute('SELECT * FROM brands;');
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
        Sql.named('SELECT * FROM brands WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      final brands = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(
        jsonEncode(brands.first),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  router.delete('/<id>', (Request request, String id) async {
    try {
      await conn.execute(
        Sql.named('DELETE FROM brands WHERE id = @id'),
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
          'INSERT INTO brands (name, image_url, lines_id) '
          'VALUES (@name, @imageUrl, @linesId) RETURNING id',
        ),
        parameters: {
          'name': data['name'],
          'imageUrl': data['imageUrl'],
          'linesId': List<String>.from(data['linesId']),
        },
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
          'UPDATE brands SET '
          'name = @name, '
          'image_url = @imageUrl, '
          'lines_id = @linesId '
          'WHERE id = @id RETURNING *',
        ),
        parameters: {
          'id': int.parse(id),
          'name': data['name'],
          'imageUrl': data['imageUrl'],
          'linesId': List<String>.from(data['linesId']),
        },
      );

      if (result.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Brand not found'}));
      }

      return Response.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  return router;
}
