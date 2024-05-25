import 'dart:convert';
import 'dart:ffi';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _results = [];
  final apiKey = 'dvzi-dBISICc2Muwq0MnPAkynirorFofe_NmIhkeM7w';

  Future<void> _search(String keyword) async {
    keyword = keyword.trim();

    final url =
        'https://autocomplete.search.hereapi.com/v1/autocomplete?q=$keyword&in=countryCode:VNM&limit=20&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = data['items'];

        setState(() {
          _results = items.map((item) {
            String label = item['address']['label'].toString();
            String normalizedLabel = removeDiacritics(label);
            String normalizedKeyword = removeDiacritics(keyword);

            String boldLabel = label.replaceAllMapped(
                RegExp(normalizedKeyword, caseSensitive: false), (match) {
              return '<b>${match.group(0)}</b>';
            });

            return {
              'address': boldLabel,
              'id': item['id'].toString(),
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load data');
    }
  }
  List<TextSpan> _parseBoldText(String text) {
    final RegExp boldTag = RegExp(r'<b>(.*?)<\/b>');
    final List<TextSpan> spans = [];
    int start = 0;
    boldTag.allMatches(text).forEach((match) {
      final plainText = text.substring(start, match.start);
      if (plainText.isNotEmpty) {
        spans.add(TextSpan(text: plainText));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    });
    final remainingText = text.substring(start);
    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(text: remainingText));
    }
    return spans;
  }

  Future<void> _lookup(String id) async {
    final url =
        'https://lookup.search.hereapi.com/v1/lookup?id=$id&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final double latitude = data['position']['lat'];
      final double longitude = data['position']['lng'];

      print(latitude);
      print(longitude);
      var url1 =
          "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude";
      launchUrl(Uri.parse(url1));
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _search(_controller.text);
                  },
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                    });
                  },
                ),
                hintText: 'Enter keyword',
              ),
              onChanged: (value) {
                _search(_controller.text);
              },
              onSubmitted: (value){
                _search(_controller.text);
              },),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return InkWell(
                    onTap: () {
                      _lookup(result['id'].toString());
                    },
                    child: ListTile(
                      leading: Icon(Icons.location_on_outlined),
                      title: Text.rich(
                        TextSpan(
                          children: _parseBoldText(result['address']!),
                        ),
                      ),
                      trailing: InkWell(
                        onTap: () {
                          _lookup(result['id']!);
                        },
                        child: Icon(Icons.directions),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
