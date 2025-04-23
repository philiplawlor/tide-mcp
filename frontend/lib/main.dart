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
    // Always set the MaterialApp title to include the current version
    // This will be updated dynamically as the version changes
    return MaterialApp(
      title: 'Tide MCP v${TideHomePage.version}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TideHomePage(),
    );
  }


}

class TideHomePage extends StatefulWidget {
  final bool initialLoading;
  static String version = '1.2.8'; // Default, will be updated from VERSION file
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
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=' + Uri.encodeComponent(input));
    final resp = await http.get(url, headers: {'User-Agent': 'TideMCP/1.0'});
    if (resp.statusCode == 200) {
      final results = jsonDecode(resp.body);
      if (results is List && results.isNotEmpty) {
        final loc = results[0];
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
    });
  }

  void _loadVersion() async {
    try {
      final version = await DefaultAssetBundle.of(context).loadString('assets/VERSION');
      setState(() {
        _version = version.trim();
        TideHomePage.version = _version; // Keep static and instance in sync for all titles
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
    try {
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
    List<Map<String, dynamic>> events = [];
    for (var t in data['highs']) {
      events.add({'type': 'High', 'time': t['t'], 'height': double.tryParse(t['v'] ?? '0') ?? 0});
    }
    for (var t in data['lows']) {
      events.add({'type': 'Low', 'time': t['t'], 'height': double.tryParse(t['v'] ?? '0') ?? 0});
    }
    events.sort((a, b) => a['time'].compareTo(b['time']));
    if (events.isEmpty) return const Text('No tide events');
    List<FlSpot> spots = [];
    for (int i = 0; i < events.length; i++) {
      spots.add(FlSpot(i.toDouble(), events[i]['height']));
    }

    DateTime now = DateTime.now();
    double? nowX;
    // Clamp 'Now' to chart range if outside
    DateTime firstT = DateTime.parse(events.first['time']);
    DateTime lastT = DateTime.parse(events.last['time']);
    if (now.isBefore(firstT)) {
      nowX = 0.0;
    } else if (now.isAfter(lastT)) {
      nowX = events.length - 1.0;
    } else {
      for (int i = 0; i < events.length - 1; i++) {
        DateTime t1 = DateTime.parse(events[i]['time']);
        DateTime t2 = DateTime.parse(events[i + 1]['time']);
        if (!now.isBefore(t1) && now.isBefore(t2)) {
          double frac = now.difference(t1).inSeconds / t2.difference(t1).inSeconds;
          nowX = i + frac;
          break;
        }
      }
    }

    List<VerticalLine> verticalLines = [];
    // Helper to find X for a given time string
    double? findX(String? timeStr) {
      if (timeStr == null) return null;
      try {
        DateTime t = DateTime.parse(timeStr);
        for (int i = 0; i < events.length - 1; i++) {
          DateTime t1 = DateTime.parse(events[i]['time']);
          DateTime t2 = DateTime.parse(events[i + 1]['time']);
          if (!t.isBefore(t1) && t.isBefore(t2)) {
            double frac = t.difference(t1).inSeconds / t2.difference(t1).inSeconds;
            return i + frac;
          }
        }
        // If exactly at the last event
        if (t.isAtSameMomentAs(DateTime.parse(events.last['time']))) {
          return events.length - 1.0;
        }
      } catch (_) {}
      return null;
    }

    // Add vertical lines for requested events
    // Midnight (x=0)
    verticalLines.add(
      VerticalLine(
        x: 0,
        color: Colors.black,
        strokeWidth: 2,
        dashArray: [2, 2],
        label: VerticalLineLabel(
          show: true,
          alignment: Alignment.topLeft,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          labelResolver: (line) => 'Midnight',
        ),
      ),
    );
    // Moonrise
    double? moonriseX = findX(data['moonrise'] as String?);
    if (moonriseX != null) {
      verticalLines.add(
        VerticalLine(
          x: moonriseX,
          color: Colors.indigo,
          strokeWidth: 2,
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            labelResolver: (line) => 'Moonrise',
          ),
        ),
      );
    }
    // Sunrise
    double? sunriseX = findX(data['sunrise'] as String?);
    if (sunriseX != null) {
      verticalLines.add(
        VerticalLine(
          x: sunriseX,
          color: Colors.orange,
          strokeWidth: 2,
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            labelResolver: (line) => 'Sunrise',
          ),
        ),
      );
    }
    // Moonset
    double? moonsetX = findX(data['moonset'] as String?);
    if (moonsetX != null) {
      verticalLines.add(
        VerticalLine(
          x: moonsetX,
          color: Colors.blueGrey,
          strokeWidth: 2,
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
            labelResolver: (line) => 'Moonset',
          ),
        ),
      );
    }
    // Sunset
    double? sunsetX = findX(data['sunset'] as String?);
    if (sunsetX != null) {
      verticalLines.add(
        VerticalLine(
          x: sunsetX,
          color: Colors.deepOrange,
          strokeWidth: 2,
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
            labelResolver: (line) => 'Sunset',
          ),
        ),
      );
    }
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
          minX: 0.0,
          maxX: 24.0, // 25 points: x=0 to x=24, with 'Now' at x=12

          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1.0, // 30-minute increments
                getTitlesWidget: (value, meta) {
                  // value: 0 to 24, 'Now' is always at 12
                  int minutesOffset = ((value - 12) * 30).round();
                  if (minutesOffset % 60 == 0) {
                    int hoursOffset = (minutesOffset / 60).round();
                    String label = hoursOffset == 0 ? 'Now' : (hoursOffset > 0 ? '+$hoursOffset' : '$hoursOffset');
                    return Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            verticalInterval: 1.0,
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: (() {
                // Interpolate tide heights at 30-min intervals from 6h before Now to 6h after
                if (events.isEmpty) return const <FlSpot>[];
                final List<FlSpot> newSpots = [];
                final DateTime now = DateTime.now();
                final DateTime startTime = now.subtract(const Duration(hours: 6));
                for (int i = 0; i <= 24; i++) {
                  DateTime t = startTime.add(Duration(minutes: i * 30));
                  // Find the two events this t falls between
                  int idx = 0;
                  while (idx < events.length - 1 && DateTime.parse(events[idx + 1]['time']).isBefore(t)) {
                    idx++;
                  }
                  DateTime t1 = DateTime.parse(events[idx]['time']);
                  double v1 = events[idx]['height'];
                  if (idx == events.length - 1) {
                    newSpots.add(FlSpot(i.toDouble() - 12, v1));
                  } else {
                    DateTime t2 = DateTime.parse(events[idx + 1]['time']);
                    double v2 = events[idx + 1]['height'];
                    double frac = t2.isAtSameMomentAs(t1) ? 0.0 : (t.difference(t1).inSeconds / t2.difference(t1).inSeconds);
                    double v = v1 + (v2 - v1) * frac;
                    newSpots.add(FlSpot(i.toDouble() - 12, v));
                  }
                }
                return newSpots;
              })(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            verticalLines: [
              ...verticalLines,
              // Noon line always in the middle
              VerticalLine(
                x: (events.length - 1) / 2.0,
                color: Colors.black87,
                strokeWidth: 3,
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topCenter,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  labelResolver: (line) => 'Noon',
                ),
              ),
            ],
          ),
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
