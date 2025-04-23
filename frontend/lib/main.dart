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
  final bool initialLoading;
  const TideHomePage({super.key, this.initialLoading = true});

  @override
  State<TideHomePage> createState() => _TideHomePageState();
}

class _TideHomePageState extends State<TideHomePage> {
  String _selectedStationName = '';
  String _selectedStationDistanceKm = '';
  String _version = '1.2.2'; // Default, will try to update from VERSION file

  Map<String, dynamic>? todayData;
  Map<String, dynamic>? weekData;
  Map<String, dynamic>? predictionData;
  late bool loading; // Use late to initialize in initState
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
  TextEditingController manualLocationController = TextEditingController();
  bool usingManualLocation = false;
  String? manualLocationError;

  // Helper for app bar title
  String _buildAppBarTitle() {
  String locationName = selectedTown ?? _selectedStationName;
  String title = 'Local Tides';
  if (locationName != null && locationName.isNotEmpty) {
    title += ' [' + locationName + ']';
  }
  title += ' - v$_version';
  return title;
}

  Future<Map<String, dynamic>?> _geocodeLocation(String input) async {
  // Use Nominatim OpenStreetMap API for free geocoding
  final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=' + Uri.encodeComponent(input));
  final resp = await http.get(url, headers: {'User-Agent': 'TideMCP/1.0'});
  if (resp.statusCode == 200) {
  final results = jsonDecode(resp.body);
  if (results is List && results.isNotEmpty) {
  final loc = results[0];
  // Try to parse town, state, zip from address if available
  String? town;
  String? state;
  String? zip;
  if (loc['address'] != null) {
      final addr = loc['address'];
        town = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? addr['municipality'] ?? addr['county'];
        state = addr['state'] ?? addr['region'];
        zip = addr['postcode'];
      }
      return {
        'lat': double.tryParse(loc['lat']),
        'lon': double.tryParse(loc['lon']),
        'display_name': loc['display_name'],
        'town': town,
        'state': state,
        'zip': zip,
      };
    }
  }
  return null;
}

  Future<void> _selectManualLocation() async {
  setState(() { manualLocationError = null; });
  final input = manualLocationController.text.trim();
  if (input.isEmpty) {
    setState(() { manualLocationError = 'Please enter a location.'; });
    return;
  }
  final loc = await _geocodeLocation(input);
  if (loc == null || loc['lat'] == null || loc['lon'] == null) {
    setState(() { manualLocationError = 'Could not find location.'; });
    return;
  }
  String? displayLocation;
  String? zip = loc['zip'];
  String? town = loc['town'];
  String? state = loc['state'];
  // If zip is missing, try to look it up with another geocode query
  if ((zip == null || zip.isEmpty) && town != null && state != null) {
    final zipQuery = await _geocodeLocation("$town, $state");
    if (zipQuery != null && zipQuery['zip'] != null && zipQuery['zip'].toString().isNotEmpty) {
      zip = zipQuery['zip'];
    }
  }
  if (town != null && state != null) {
    displayLocation = zip != null && zip.isNotEmpty ? "$town, $state $zip" : "$town, $state";
  } else {
    displayLocation = loc['display_name'];
  }
  // Update the manual location field with the ZIP if discovered
  if (town != null && state != null && zip != null && zip.isNotEmpty) {
    manualLocationController.text = "$town, $state $zip";
  } else if (town != null && state != null) {
    manualLocationController.text = "$town, $state";
  }
  setState(() {
    selectedLat = loc['lat'];
    selectedLon = loc['lon'];
    selectedTown = displayLocation;
    selectedZip = zip;
    usingManualLocation = true;
    selectedStationId = null;
  });
  await fetchAll();
}

  Future<void> _fetchTideData() async {
  setState(() { loading = true; error = ''; });
  try {
  String url = '';
  if (usingManualLocation && selectedLat != null && selectedLon != null) {
  // Add town/state/zip if available
    List<String> params = [
    'lat=${selectedLat}',
      'lon=${selectedLon}'
  ];
  if (selectedTown != null && selectedTown!.isNotEmpty) {
      params.add('town=${Uri.encodeComponent(selectedTown!)}');
    }
  if (selectedZip != null && selectedZip!.isNotEmpty) {
    params.add('zip=${Uri.encodeComponent(selectedZip!)}');
  }
  url = '$backendUrl/tide/today?${params.join('&')}';
    } else if (selectedStationId != null) {
    url = '$backendUrl/tide/today?station=$selectedStationId';
    } else {
      setState(() { error = 'No location selected.'; loading = false; });
      return;
    }
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      todayData = jsonDecode(resp.body);
    } else {
      error = 'Failed to fetch tide data.';
    }
  } catch (e) {
    error = 'Error: $e';
  }
  setState(() { loading = false; });
}

  @override
  void initState() {
    super.initState();
    loading = false;
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() { loading = false; });
      // Do not fetch data on startup; wait for user to pick a location
    });
  }

  void _loadVersion() async {
    // Only works if running with access to assets or file system
    try {
      // For web, this may need a different approach
      final version = await DefaultAssetBundle.of(context).loadString('assets/VERSION');
      setState(() {
        _version = version.trim();
      });
    } catch (e) {
      // fallback to default
    }
  }

  Future<void> fetchAll() async {
  setState(() {
  loading = true;
  error = '';
  });
  try {
  String todayUrl = '';
  String weekUrl = '';
  if (usingManualLocation && selectedLat != null && selectedLon != null) {
  List<String> params = [
    'lat=${selectedLat}',
    'lon=${selectedLon}'
    ];
    if (selectedTown != null && selectedTown!.isNotEmpty) {
      params.add('town=${Uri.encodeComponent(selectedTown!)}');
    }
    if (selectedZip != null && selectedZip!.isNotEmpty) {
      params.add('zip=${Uri.encodeComponent(selectedZip!)}');
    }
  todayUrl = '$backendUrl/tide/today?${params.join('&')}';
  weekUrl = '$backendUrl/tide/week?${params.join('&')}';
  } else if (selectedStationId != null && selectedStationId!.isNotEmpty) {
  String stationParam = '?station=$selectedStationId';
    todayUrl = '$backendUrl/tide/today$stationParam';
      weekUrl = '$backendUrl/tide/week$stationParam';
  } else {
  setState(() {
    error = 'No tide station found for this location.';
      loading = false;
      });
      return;
    }
    final todayResp = await http.get(Uri.parse(todayUrl));
    final weekResp = await http.get(Uri.parse(weekUrl));
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
        title: Text(_buildAppBarTitle()),
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
      : ((selectedStationId == null || selectedStationId!.isEmpty) && !usingManualLocation)
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
                onSubmitted: (value) {
                   if (value.trim().isNotEmpty) {
                     manualLocationController.text = value.trim();
                     _selectManualLocation();
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
                    selectedLat = loc['lat'] is num ? (loc['lat'] as num).toDouble() : double.tryParse(loc['lat']?.toString() ?? '');
                    selectedLon = loc['lon'] is num ? (loc['lon'] as num).toDouble() : double.tryParse(loc['lon']?.toString() ?? '');
                    selectedStationId = loc['stationId']?.toString() ?? '';
                    _selectedStationName = loc['stationName']?.toString() ?? '';
                    _selectedStationDistanceKm = loc['distanceKm']?.toString() ?? '';
                    locationController.text = '${loc['town']}, ${loc['state']} (${loc['zip']})';
                    locationResults = [];
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

