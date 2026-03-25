import 'package:dotenv/dotenv.dart';

final env = DotEnv()..load();

String getEnv(String key) {
  final value = env[key];
  return value.toString();
}
