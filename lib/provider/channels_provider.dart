import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/channel.dart';
import '../model/stream_source.dart';

class ChannelsProvider with ChangeNotifier {
  static const streamsCatalogUrl =
      'https://raw.githubusercontent.com/kananinirav/Indian-IPTV-App/refs/heads/master/data/streams.csv';

  List<Channel> channels = [];
  List<Channel> filteredChannels = [];

  Future<List<StreamSource>> fetchStreamSources() async {
    final response = await http.get(Uri.parse(streamsCatalogUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load stream sources');
    }

    final sources = <StreamSource>[];
    final lines = response.body.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('name,')) {
        continue;
      }

      final commaIndex = trimmed.indexOf(',');
      if (commaIndex == -1) continue;

      final name = trimmed.substring(0, commaIndex).trim();
      final streamUrl = trimmed.substring(commaIndex + 1).trim();
      if (name.isNotEmpty && streamUrl.isNotEmpty) {
        sources.add(StreamSource(name: name, streamUrl: streamUrl));
      }
    }

    return sources;
  }

  Future<List<Channel>> fetchM3UFile(String sourceUrl) async {
    channels.clear();
    filteredChannels.clear();

    final response = await http.get(Uri.parse(sourceUrl));
    if (response.statusCode == 200) {
      String fileText = response.body;
      List<String> lines = fileText.split('\n');

      String? name;
      String logoUrl = getDefaultLogoUrl();
      String? streamUrl;

      for (String line in lines) {
        if (line.startsWith('#EXTINF:')) {
          name = extractChannelName(line);
          logoUrl = extractLogoUrl(line) ?? getDefaultLogoUrl();
        } else if (line.isNotEmpty && !line.startsWith('#')) {
          streamUrl = line.trim();
          if (name != null) {
            channels.add(Channel(
              name: name,
              logoUrl: logoUrl,
              streamUrl: streamUrl,
            ));
          }
          name = null;
          logoUrl = getDefaultLogoUrl();
          streamUrl = null;
        }
      }
      filteredChannels = List.from(channels);
      return channels;
    } else {
      throw Exception('Failed to load M3U file');
    }
  }

  String getDefaultLogoUrl() {
    return 'assets/images/tv-icon.png';
  }

  String? extractChannelName(String line) {
    List<String> parts = line.split(',');
    return parts.last.trim();
  }

  String? extractLogoUrl(String line) {
    List<String> parts = line.split('"');
    if (parts.length > 1 && isValidUrl(parts[1])) {
      return parts[1];
    } else if (parts.length > 5 && isValidUrl(parts[5])) {
      return parts[5];
    }
    return null;
  }

  bool isValidUrl(String url) {
    return url.startsWith('https') || url.startsWith('http');
  }

  List<Channel> filterChannels(String query) {
    filteredChannels = channels
        .where((channel) =>
            channel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredChannels;
  }
}
