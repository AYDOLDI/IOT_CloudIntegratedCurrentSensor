import 'dart:async';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThingSpeak Chart',
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: const MyHomePage(title: 'ThingSpeak Chart'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TimeSeriesData> data = [];
  // Replace with your ThingSpeak API key
  String channelId = '1990679';
  String apiKey = 'JRTBVQC458HKHCT7';

  late List<charts.Series<TimeSeriesData, DateTime>> _seriesList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setUpTimedFetch();
    //_fetchData();
  }

  setUpTimedFetch() => Timer.periodic(const Duration(milliseconds: 60000), (timer) {
      setState(() {
        _isLoading = true;
        data = [];
        _fetchData();
      });
    });

  _fetchData() async {
    String url =
        'https://api.thingspeak.com/channels/$channelId/fields/1.json?results=60';
    http.Response response = await http.get(
      Uri.parse(url),
    );
    if (response.statusCode == 200) {

      final feeds = jsonDecode(response.body)['feeds'];
      for (var feed in feeds) {
        final date = DateTime.parse(feed['created_at']);
        // Replace with the field name that you want to plot
        final value = double.parse(feed['field1']);
        if(value < 5){
          data.add(TimeSeriesData(date, value.abs()));
        }

        log('date: $date and value: $value');
      }
      log('data: $data');
      setState(() {
        _seriesList = [
          charts.Series<TimeSeriesData, DateTime>(
            id: 'aa',
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (TimeSeriesData data, _) => data.time.toLocal(),
            measureFn: (TimeSeriesData data, _) => data.value.toDouble(),
            data: data,
          )

        ];

        _isLoading = false;
      });
      log('fetching data is completed');
    } else {
      log('Request failed with status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    int len = data.length;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Integrated Current Sensor Application'),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Container(
                    height: 550,
                    width: 600,
                    color: Colors.yellow,
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: charts.TimeSeriesChart(
                          _seriesList,
                          defaultRenderer: charts.LineRendererConfig(
                            includeArea: true,
                            stacked: true,
                          ),
                          animate: true,
                          primaryMeasureAxis: const charts.NumericAxisSpec(
                            tickProviderSpec:
                                charts.BasicNumericTickProviderSpec(
                              desiredTickCount: 3,
                            ),
                            //renderSpec: charts.NoneRenderSpec(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Container(

                    height: 500,
                    width: 600,
                    color: Colors.indigoAccent,
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        // Extract the field values from the data
                        var field1 = data[len - 1 - index].value;
                        var createdAt = data[len - 1 - index].time;

                        return ListTile(
                          title: const Text('Recieved Data:'),
                          subtitle: Text('Current: $field1\nCreated at: $createdAt'),
                        );
                      },
                    ),
                  ),
                ],
              ));
  }
}

class TimeSeriesData {
  final DateTime time;
  final double value;

  TimeSeriesData(this.time, this.value);
}
