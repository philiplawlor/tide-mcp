import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tide MCP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TideHomePage(),
    );
  }
}

class TideHomePage extends StatefulWidget {
  const TideHomePage({super.key});

  @override
  State<TideHomePage> createState() => _TideHomePageState();
}

class _TideHomePageState extends State<TideHomePage> {
  String _selectedStationName = '';
  String _selectedStationDistanceKm = '';

  Map<String, dynamic>? todayData;
  Map<String, dynamic>? weekData;
  Map<String, dynamic>? predictionData;
  bool loading = true;
  String error = '';

  final String backendUrl = 'http://localhost:8000';

  // Location selection state
  String? selectedTown;
  String? selectedZip;
  double? selectedLat;
  double? selectedLon;
  String? selectedStationId;
  List<Map<String, dynamic>> locationResults = [];
  bool locationLoading = false;
  TextEditingController locationController = TextEditingController();

  Future<void> _addLocationIfNotExists(Map<String, dynamic> loc) async {
    // Try to add location to backend DB (ignore errors if already exists)
    try {
      await http.post(
        Uri.parse('$backendUrl/locations/add'),
        body: {
          'town': loc['town']?.toString() ?? '',
          'state': loc['state']?.toString() ?? '',
          'zip_code': loc['zip']?.toString() ?? '',
          'lat': loc['lat']?.toString() ?? '',
          'lon': loc['lon']?.toString() ?? '',
          'stationId': loc['stationId']?.toString() ?? '',
        },
      );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Do not fetch data on startup. Wait for user to select a location.
  }

  Future<void> fetchAll() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      if (selectedStationId == null || selectedStationId!.isEmpty) {
        setState(() {
          error = 'No tide station found for this location.';
          loading = false;
        });
        return;
      }
      String stationParam = '?station=$selectedStationId';
      final todayResp = await http.get(Uri.parse('$backendUrl/tide/today$stationParam'));
      final weekResp = await http.get(Uri.parse('$backendUrl/tide/week$stationParam'));
      print('DEBUG: /tide/week response body: \\${weekResp.body}');
      final predResp = await http.get(Uri.parse('$backendUrl/predictions/week'));
      setState(() {
        todayData = json.decode(todayResp.body);
        weekData = json.decode(weekResp.body);
        predictionData = json.decode(predResp.body);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Tide Clock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              fetchAll();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (selectedStationId == null || selectedStationId!.isEmpty)
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLocationSelector(),
                  const SizedBox(height: 24),
                  Text(
                    'Please select a location to view tide data.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ))
            : error.isNotEmpty
                ? Center(child: Text('Error: $error'))
                : RefreshIndicator(
                    onRefresh: fetchAll,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildLocationSelector(),
                        const SizedBox(height: 16),
                        Text(
                          'Today',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildTideChart(todayData),
                        const SizedBox(height: 8),
                        _buildHighLowTimes(todayData),
                        const SizedBox(height: 8),
                        _buildMoonPhase(todayData),
                        const Divider(height: 32),
                        Text(
                          'Week at a Glance',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildWeekView(weekData, predictionData),
                      ],
                    ),
                  ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Location:', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'Enter town, state or zip code',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    _searchLocations(value);
                  } else {
                    setState(() { locationResults = []; });
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Use Current Location',
              onPressed: _findNearbyLocations,
            ),
          ],
        ),
        if (locationLoading) const LinearProgressIndicator(),
        if (locationResults.isNotEmpty)
          ...locationResults.take(5).map((loc) => ListTile(
                title: Text('${loc['town']}, ${loc['state']} (${loc['zip']})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: ${loc['lat']}, Lon: ${loc['lon']}'),
                    if (loc['stationName'] != null && loc['stationName'].toString().isNotEmpty)
                      Text('NOAA Station: ${loc['stationName']}'),
                  ],
                ),
                onTap: () {
                  if (loc['stationId'] == null || loc['stationId'].toString().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No tide station found for this location')),
                    );
                    return;
                  }
                  setState(() {
                    selectedTown = loc['town']?.toString();
                    selectedZip = loc['zip']?.toString();
                    selectedLat = loc['lat'] is num ? loc['lat'].toDouble() : double.tryParse(loc['lat'].toString());
                    selectedLon = loc['lon'] is num ? loc['lon'].toString() : double.tryParse(loc['lon'].toString());
                    selectedStationId = loc['stationId']?.toString() ?? '';
                    _selectedStationName = loc['stationName']?.toString() ?? '';
                    _selectedStationDistanceKm = loc['distanceKm']?.toString() ?? '';
                    locationController.text = '${loc['town']}, ${loc['state']} (${loc['zip']})';
                    locationResults = [];
                    _addLocationIfNotExists(loc);
                    fetchAll();
                  });
                },
              )),
        if (selectedTown != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Selected: $selectedTown ($selectedZip)', style: const TextStyle(color: Colors.blue)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (selectedStationId != null && selectedStationId!.isNotEmpty)
                          ? () {
                              fetchAll();
                            }
                          : null,
                      child: const Text('Submit'),
                    )
                  ],
                ),
                if (selectedStationId != null && selectedStationId!.isNotEmpty && _selectedStationName.isNotEmpty && _selectedStationDistanceKm.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Tide data shown is for $_selectedStationName, $_selectedStationDistanceKm km from your selected location.',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          )
      ],
    );
  }

  void _searchLocations(String query) async {
    setState(() { locationLoading = true; });
    try {
      final resp = await http.get(Uri.parse('$backendUrl/locations/search?q=$query'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          locationResults = List<Map<String, dynamic>>.from(data['locations']);
          locationLoading = false;
        });
      } else {
        setState(() { locationLoading = false; });
      }
    } catch (e) {
      setState(() { locationLoading = false; });
    }
  }

  void _findNearbyLocations() async {
    setState(() { locationLoading = true; });
    // Try to get device location
    try {
      // Use geolocator package
      // (You may need to handle permissions and errors)
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lat = position.latitude;
      final lon = position.longitude;
      final resp = await http.get(Uri.parse('$backendUrl/locations/nearby?lat=$lat&lon=$lon'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          locationResults = List<Map<String, dynamic>>.from(data['locations']);
          locationLoading = false;
        });
      } else {
        setState(() { locationLoading = false; });
      }
    } catch (e) {
      setState(() { locationLoading = false; });
    }
  }

  Widget _buildTideChart(Map<String, dynamic>? data) {
    if (data == null || data['highs'] == null || data['lows'] == null) {
      return const Text('No tide data');
    }
    // Merge highs and lows, sort by time
    List<Map<String, dynamic>> events = [];
    for (var t in data['highs']) {
      events.add({'type': 'High', 'time': t['t'], 'height': double.tryParse(t['v'] ?? '0') ?? 0});
    }
    for (var t in data['lows']) {
      events.add({'type': 'Low', 'time': t['t'], 'height': double.tryParse(t['v'] ?? '0') ?? 0});
    }
    events.sort((a, b) => a['time'].compareTo(b['time']));
    if (events.isEmpty) return const Text('No tide events');
    // Prepare chart data
    List<FlSpot> spots = [];
    for (int i = 0; i < events.length; i++) {
      spots.add(FlSpot(i.toDouble(), events[i]['height']));
    }

    // Calculate current time position
    DateTime now = DateTime.now();
    double? nowX;
    for (int i = 0; i < events.length - 1; i++) {
      DateTime t1 = DateTime.parse(events[i]['time']);
      DateTime t2 = DateTime.parse(events[i + 1]['time']);
      if (now.isAfter(t1) && now.isBefore(t2)) {
        double frac = now.difference(t1).inSeconds / t2.difference(t1).inSeconds;
        nowX = i + frac;
        break;
      }
    }

    List<VerticalLine> verticalLines = [];
    if (nowX != null) {
      verticalLines.add(
        VerticalLine(
          x: nowX,
          color: Colors.red,
          strokeWidth: 2,
          dashArray: [6, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            labelResolver: (line) => 'Now',
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
          extraLinesData: ExtraLinesData(verticalLines: verticalLines),
        ),
      ),
    );
  }

  Widget _buildHighLowTimes(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    List<Widget> children = [];
    if (data['highs'] != null) {
      children.add(Text('High Tides:', style: const TextStyle(fontWeight: FontWeight.bold)));
      for (var t in data['highs']) {
        children.add(Text('${t['t']}  Height: ${t['v']} ft'));
      }
    }
    if (data['lows'] != null) {
      children.add(Text('Low Tides:', style: const TextStyle(fontWeight: FontWeight.bold)));
      for (var t in data['lows']) {
        children.add(Text('${t['t']}  Height: ${t['v']} ft'));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildMoonPhase(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.nights_stay),
        const SizedBox(width: 8),
        Text('Moon Phase: ${data['moon_phase'] ?? "-"}')
      ],
    );
  }

  Widget _buildWeekView(Map<String, dynamic>? week, Map<String, dynamic>? pred) {
    if (week == null || week['week'] == null) return const Text('No week data');
    List predictions = pred?['predictions'] ?? [];
    print('DEBUG: week[\'week\'] has \'${week['week'].length}\' days');
    return Column(
      children: List.generate(week['week'].length, (i) {
        var day = week['week'][i];
        var predDay = predictions.length > i ? predictions[i] : {};
        return Card(
          child: ListTile(
            title: Text('${day['date']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Highs: ${(day['highs'] as List).map((t) => t['t']).join(', ')}'),
                Text('Lows: ${(day['lows'] as List).map((t) => t['t']).join(', ')}'),
                Text('Moon: ${day['moon_phase']}'),
                Text('Fishing: ${predDay['fishing'] ?? "-"}'),
                Text('Hunting: ${predDay['hunting'] ?? "-"}'),
              ],
            ),
          ),
        );
      }),
    );
  }
}

