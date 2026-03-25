import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router productRouter(Connection conn) {
  final router = Router();

  router.get('/', (Request req) async {
    try {
      final result = await conn.execute('SELECT * FROM products;');
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
        Sql.named('SELECT * FROM products WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      final products = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(
        jsonEncode(products.first),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  router.delete('/<id>', (Request request, String id) async {
    try {
      await conn.execute(
        Sql.named('DELETE FROM products WHERE id = @id'),
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
          'INSERT INTO products (id, title, description, image_url, brand_id, line_id, category_id, price, wholesale_price, code, attributes) '
          'VALUES (@id, @title, @description, @imageUrl, @brandId, @lineId, @categoryId, @price, @wholesalePrice, @code, @attributes) '
          'RETURNING *',
        ),
        parameters: {
          'id': data['id'],
          'title': data['title'],
          'description': data['description'],
          'imageUrl': List<String>.from(data['imageUrl']),
          'brandId': data['brandId'],
          'lineId': data['lineId'],
          'categoryId': data['categoryId'],
          'price': data['price'],
          'wholesalePrice': data['wholesalePrice'],
          'code': data['code'],
          'attributes': data['attributes'],
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
          'UPDATE products SET '
          'title = @title, description = @description, image_url = @imageUrl, '
          'brand_id = @brandId, line_id = @lineId, category_id = @categoryId, '
          'price = @price, wholesale_price = @wholesalePrice, code = @code, '
          'attributes = @attributes WHERE id = @id RETURNING *',
        ),
        parameters: {
          'id': int.parse(id),
          'title': data['title'],
          'description': data['description'],
          'imageUrl': List<String>.from(data['imageUrl']),
          'brandId': data['brandId'],
          'lineId': data['lineId'],
          'categoryId': data['categoryId'],
          'price': data['price'],
          'wholesalePrice': data['wholesalePrice'],
          'code': data['code'],
          'attributes': data['attributes'],
        },
      );

      if (result.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'products not found'}));
      }

      return Response.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  router.get('/search/<lineId>', (Request req, String lineId) async {
    try {
      final result = await conn.execute(
        Sql.named('SELECT * FROM products WHERE line_id=@lineId;'),
        parameters: {'lineId': int.tryParse(lineId)},
      );
      final list = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(
        jsonEncode(list),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });
  return router;
}
