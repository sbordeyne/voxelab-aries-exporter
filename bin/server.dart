import 'package:voxelab_aries_prometheus_exporter/command.dart';
import 'env.dart';

import 'dart:io';
import 'dart:convert';

import 'package:prometheus_client/format.dart' as format;
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;

class Data {
  final Map<String, int> data;
  final Map<String, String> labels;

  Data(this.data, this.labels);
}

Stream<Data> connect(Env env) async* {
  final socket = await Socket.connect(env.ariesIp, env.ariesPort);
  print('Connected to ${socket.remoteAddress.address}:${socket.remotePort}');
  Map<String, int> data = {};
  Map<String, String> labels = {};

  socket.listen((event) {
    final asString = utf8.decode(event, allowMalformed: true);
    final firstLine = asString.split('\r\n').first;
    if (firstLine.contains(MachineStatusCommand.cmd)) {
      final commandResult = MachineStatusCommand.parse(asString);
      labels.addAll(commandResult);
      socket.add(TemperatureCommand.frame);
    }

    if (firstLine.contains(TemperatureCommand.cmd)) {
      final commandResult = TemperatureCommand.parse(asString);
      data.addAll(commandResult);
      socket.add(ProgressCommand.frame);
    }
    if (firstLine.contains(ProgressCommand.cmd)) {
      final commandResult = ProgressCommand.parse(asString);
      data.addAll(commandResult);
    }
  });

  while (true) {
    yield Data(data, labels);
    data = {};
    socket.add(MachineStatusCommand.frame);
    await Future.delayed(Duration(milliseconds: env.socketPollingInterval));
  }
}

void main(List<String> arguments) async {
  print('Starting Voxelab Aries Prometheus Exporter...');
  final env = Env();
  print('Env: ${env.ariesIp}:${env.ariesPort}');
  // Register runtime metrics with the default metrics registry
  print('Registering runtime metrics...');
  runtime_metrics.register();
  const labelNames = [
    'endstop_x_max',
    'endstop_y_max',
    'endstop_z_max',
    'machine_status',
    'move_mode',
    'status_s',
    'status_l',
    'status_j',
    'status_f',
  ];
  final sdPrintingByteCurrent = Gauge(
    name: 'voxelab_aries_sd_printing_byte_current',
    help: 'The current byte of the sd printing.',
    labelNames: labelNames,
  )..register();
  final sdPrintingByteTotal = Gauge(
    name: 'voxelab_aries_sd_printing_byte_total',
    help: 'The total byte of the sd printing.',
    labelNames: labelNames,
  )..register();
  final extruderCurrentTemperature = Gauge(
    name: 'voxelab_aries_extruder_current_temperature',
    help: 'The current temperature of the extruder.',
    labelNames: labelNames,
  )..register();
  final extruderTargetTemperature = Gauge(
    name: 'voxelab_aries_extruder_target_temperature',
    help: 'The target temperature of the extruder.',
    labelNames: labelNames,
  )..register();
  final baseCurrentTemperature = Gauge(
    name: 'voxelab_aries_base_current_temperature',
    help: 'The current temperature of the base.',
    labelNames: labelNames,
  )..register();
  final baseTargetTemperature = Gauge(
    name: 'voxelab_aries_base_target_temperature',
    help: 'The target temperature of the base.',
    labelNames: labelNames,
  )..register();

  // Create a http server
  final server = await HttpServer.bind(env.hostName, env.port);

  final stream = connect(env);
  stream.listen((data) async {
    final labels = data.labels;
    final d = data.data;
    if (data.data.isEmpty) {
      return;
    }
    sdPrintingByteCurrent
        .labels(
          labelNames.map((e) => labels[e] ?? '').toList(),
        )
        .value = d['voxelab_aries_sd_printing_byte_current']?.toDouble() ?? 0.0;
    sdPrintingByteTotal
        .labels(
          labelNames.map((e) => labels[e] ?? '').toList(),
        )
        .value = d['voxelab_aries_sd_printing_byte_total']?.toDouble() ?? 0.0;
    extruderCurrentTemperature
            .labels(
              labelNames.map((e) => labels[e] ?? '').toList(),
            )
            .value =
        d['voxelab_aries_extruder_current_temperature']?.toDouble() ?? 0.0;
    extruderTargetTemperature
            .labels(
              labelNames.map((e) => labels[e] ?? '').toList(),
            )
            .value =
        d['voxelab_aries_extruder_target_temperature']?.toDouble() ?? 0.0;
    baseCurrentTemperature
        .labels(
          labelNames.map((e) => labels[e] ?? '').toList(),
        )
        .value = d['voxelab_aries_base_current_temperature']?.toDouble() ?? 0.0;
    baseTargetTemperature
        .labels(
          labelNames.map((e) => labels[e] ?? '').toList(),
        )
        .value = d['voxelab_aries_base_target_temperature']?.toDouble() ?? 0.0;
  });

  print('Listening on ${server.address.host}:${server.port}/metrics');

  await for (HttpRequest request in server) {
    print('Request received on URI ${request.uri.toString()}');
    if (request.uri.path == '/metrics') {
      request.response.headers.add('content-type', format.contentType);
      final metrics =
          await CollectorRegistry.defaultRegistry.collectMetricFamilySamples();

      format.write004(request.response, metrics);
      print('Metrics formatted...');
      await request.response.close();
    } else if (request.uri.path == '/') {
      request.response.headers.add('content-type', 'text/html');
      request.response.write('''
      <html>
        <head><title>Voxelab Aries Prometheus Exporter</title></head>
        <body>
          <h1>Voxelab Aries Prometheus Exporter</h1>
          <p><a href="/metrics">Metrics</a></p>
        </body>
      </html>
      ''');
      await request.response.close();
    } else if (request.uri.path == '/health') {
      request.response.write('{"status": "ok"}');
      request.response.headers.add('content-type', 'application/json');
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }
}
