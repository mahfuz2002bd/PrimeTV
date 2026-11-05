import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const playlistUrl = 'https://raw.githubusercontent.com/ashik4u/mrgify-clean/refs/heads/main/playlist.m3u';

void main() => runApp(const PlayZApp());

class Channel {
  final String name, url, group, logo;
  const Channel({required this.name, required this.url, this.group = 'Other', this.logo = ''});
}

class PlayZApp extends StatelessWidget {
  const PlayZApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PrimeTV',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00c896), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xff090d12),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Channel> channels = [];
  List<String> favorites = [];
  String selectedGroup = 'All';
  String search = '';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadPlaylist();
  }

  Future<void> _loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => favorites = p.getStringList('favorites') ?? []);
  }

  Future<void> _toggleFavorite(Channel c) async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      favorites.contains(c.url) ? favorites.remove(c.url) : favorites.add(c.url);
    });
    await p.setStringList('favorites', favorites);
  }

  Future<void> _loadPlaylist() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await http.get(Uri.parse(playlistUrl)).timeout(const Duration(seconds: 25));
      if (r.statusCode != 200) throw Exception('Playlist server returned ${r.statusCode}');
      final body = utf8.decode(r.bodyBytes, allowMalformed: true);
      final parsed = parseM3u(body);
      if (parsed.isEmpty) throw Exception('No playable channels were found.');
      if (mounted) setState(() { channels = parsed; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = 'Playlist load failed: $e'; loading = false; });
    }
  }

  List<String> get groups => ['All', 'Favorites', ...channels.map((c) => c.group).toSet().where((g) => g.isNotEmpty).toList()..sort()];

  List<Channel> get visible {
    Iterable<Channel> list = channels;
    if (selectedGroup == 'Favorites') list = list.where((c) => favorites.contains(c.url));
    else if (selectedGroup != 'All') list = list.where((c) => c.group == selectedGroup);
    if (search.trim().isNotEmpty) list = list.where((c) => c.name.toLowerCase().contains(search.toLowerCase()));
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 700;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.live_tv, color: Color(0xff00c896)), SizedBox(width: 10), Text('PrimeTV', style: TextStyle(fontWeight: FontWeight.bold))]),
        actions: [
          IconButton(tooltip: 'Reload playlist', onPressed: _loadPlaylist, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 16), FilledButton.icon(onPressed: _loadPlaylist, icon: const Icon(Icons.refresh), label: const Text('Try again'))
      ]))) :
      Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: TextField(
          decoration: InputDecoration(hintText: 'Search channels', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xff151d26), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
          onChanged: (v) => setState(() => search = v),
        )),
        SizedBox(height: 48, child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: groups.map((g) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
            label: Text(g), selected: selectedGroup == g, onSelected: (_) => setState(() => selectedGroup = g),
          ))).toList(),
        )),
        Expanded(child: visible.isEmpty ? const Center(child: Text('No channels in this category')) :
          GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? 5 : 2, childAspectRatio: wide ? 1.45 : 1.25, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final c = visible[i];
              return Focus(
                child: Builder(builder: (ctx) {
                  final focused = Focus.of(ctx).hasFocus;
                  return InkWell(
                    autofocus: i == 0,
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(channel: c, channels: visible))),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: focused ? const Color(0xff1c3b37) : const Color(0xff151d26), borderRadius: BorderRadius.circular(14), border: Border.all(color: focused ? const Color(0xff00c896) : Colors.white10, width: focused ? 2 : 1)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Expanded(child: c.logo.isNotEmpty ? Image.network(c.logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.live_tv, size: 42, color: Color(0xff00c896))) : const Icon(Icons.live_tv, size: 42, color: Color(0xff00c896))),
                        const SizedBox(height: 8),
                        Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(c.group, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        Align(alignment: Alignment.centerRight, child: IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Favorite',
                          onPressed: () => _toggleFavorite(c),
                          icon: Icon(favorites.contains(c.url) ? Icons.favorite : Icons.favorite_border, color: favorites.contains(c.url) ? Colors.redAccent : Colors.white70),
                        )),
                      ]),
                    ),
                  );
                }),
              );
            },
          )),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${visible.length} channels • Source playlist refreshes on demand', style: const TextStyle(color: Colors.white38, fontSize: 11))),
      ]),
    );
  }
}

List<Channel> parseM3u(String input) {
  final lines = const LineSplitter().convert(input);
  final result = <Channel>[];
  String? name, group, logo;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('#EXTINF')) {
      final comma = line.indexOf(',');
      name = comma >= 0 ? line.substring(comma + 1).trim() : 'Unknown channel';
      group = _attr(line, 'group-title') ?? 'Other';
      logo = _attr(line, 'tvg-logo') ?? '';
    } else if (line.isNotEmpty && !line.startsWith('#') && (line.startsWith('http://') || line.startsWith('https://'))) {
      result.add(Channel(name: (name == null || name!.isEmpty) ? 'Channel ${result.length + 1}' : name!, url: line, group: group ?? 'Other', logo: logo ?? ''));
      name = null; group = null; logo = null;
    }
  }
  return result;
}

String? _attr(String line, String key) {
  final match = RegExp('$key="([^"]*)"').firstMatch(line);
  return match?.group(1);
}

class PlayerPage extends StatefulWidget {
  final Channel channel;
  final List<Channel> channels;
  const PlayerPage({super.key, required this.channel, required this.channels});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? controller;
  bool busy = true;
  String? problem;
  int index = 0;

  @override
  void initState() { super.initState(); index = widget.channels.indexWhere((c) => c.url == widget.channel.url); _play(widget.channel); }

  Future<void> _play(Channel c) async {
    final old = controller;
    setState(() { busy = true; problem = null; });
    await old?.dispose();
    try {
      final next = VideoPlayerController.networkUrl(Uri.parse(c.url));
      controller = next;
      await next.initialize().timeout(const Duration(seconds: 30));
      await next.setLooping(false);
      await next.play();
      if (mounted) setState(() => busy = false);
    } catch (e) {
      if (mounted) setState(() { busy = false; problem = 'এই চ্যানেলটি চালু করা যাচ্ছে না। লিংক বন্ধ, মেয়াদোত্তীর্ণ বা নেটওয়ার্কে সমস্যা থাকতে পারে।'; });
    }
  }

  void _change(int delta) {
    if (widget.channels.isEmpty) return;
    index = (index + delta + widget.channels.length) % widget.channels.length;
    _play(widget.channels[index]);
  }

  @override
  void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.channels[index];
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _PrevIntent(),
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          _NextIntent: CallbackAction<_NextIntent>(onInvoke: (_) { _change(1); return null; }),
          _PrevIntent: CallbackAction<_PrevIntent>(onInvoke: (_) { _change(-1); return null; }),
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, title: Text(c.name), actions: [
            IconButton(tooltip: 'Previous channel', onPressed: () => _change(-1), icon: const Icon(Icons.skip_previous)),
            IconButton(tooltip: 'Next channel', onPressed: () => _change(1), icon: const Icon(Icons.skip_next)),
          ]),
          body: Center(child: AspectRatio(aspectRatio: controller?.value.isInitialized == true ? controller!.value.aspectRatio : 16 / 9, child: Stack(alignment: Alignment.center, children: [
            if (controller?.value.isInitialized == true) VideoPlayer(controller!) else const ColoredBox(color: Colors.black),
            if (busy) const CircularProgressIndicator(),
            if (problem != null) Padding(padding: const EdgeInsets.all(24), child: Text(problem!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
            if (controller?.value.isInitialized == true) Positioned(bottom: 12, left: 12, right: 12, child: Row(children: [
              IconButton(onPressed: () => controller!.value.isPlaying ? controller!.pause() : controller!.play(), icon: Icon(controller!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
              const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${index + 1}/${widget.channels.length}', style: const TextStyle(color: Colors.white70)),
            ])),
          ]))),
        ),
      ),
    );
  }
}
class _NextIntent extends Intent { const _NextIntent(); }
class _PrevIntent extends Intent { const _PrevIntent(); }
