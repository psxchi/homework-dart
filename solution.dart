import 'dart:io' as io;
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/customsearch/v1.dart' as search;
import 'package:dotenv/dotenv.dart' show load, env;

final customSearchId = 'a218432399cc24b39';

main(List<String> args) async {
  load();

  if (args.length != 2) {
    print("""Program requires 2 arguments. Example use:
dart run program input.csv output.""");
    io.exit(1);
  }

  String input = args[0];
  String output = args[1];

  String header = 'keyword,position,link\n';
  List<List<dynamic>> data = [];

  final csvList = await readCSV(input);

  var client = auth.clientViaApiKey(env['api']);
  var api = new search.CustomSearchApi(client);

  for (int i = 1; i < csvList.length; i++) {
    final url = csvList[i][3];
    final keywords = csvList[i][1].split(' ');

    for (int kw = 0; kw < keywords.length; kw++) {
      final results = await searchWeb(api, keywords[kw], url);
      if (results != null) data.add(results);
    }
  }

  writeToCSV(header, data, output);
}

// convert given csv file into a list and return it
readCSV(String filename) async {
  final input = io.File(filename).openRead();
  final fields = await input
      .transform(utf8.decoder)
      .transform(new CsvToListConverter())
      .toList();

  return fields;
}

Future<List<dynamic>> searchWeb(
    search.CustomSearchApi api, String keyword, String url) {
  return api.cse
      .list(q: keyword, cx: customSearchId)
      .then((search.Search search) {
    if (search.items == null) return null;

    for (int i = 0; i < search.items.length; i++) {
      if (search.items[i].link == url) return [keyword, i, url];
    }
  }).catchError(print);
}

writeToCSV(String header, List<List<dynamic>> data, String output) {
  final outFile = io.File(output).openWrite();
  outFile.write(header);
  final dataCSV = const ListToCsvConverter().convert(data);
  outFile.write(dataCSV);
  outFile.close();
}
