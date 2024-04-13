import 'dart:convert';
import 'dart:typed_data';

class ProgressCommand {
  static Uint8List get frame => utf8.encode("~M27\r\n");
  static String get name => 'progress';
  static String get cmd => 'M27';
  static Map<String, int> parse(String data) {
    final rv = <String, int>{};
    // Format
    // CMD M27 Received.\r\n
    // SD printing byte 0/100\r\n
    // ok
    final tmp = data.split('\r\n').elementAt(1);
    final matches =
        RegExp(r'SD printing byte (\d+)/(\d+)').allMatches(tmp).toList().first;
    rv['voxelab_aries_sd_printing_byte_current'] =
        int.parse(matches.group(1) ?? '0');
    rv['voxelab_aries_sd_printing_byte_total'] =
        int.parse(matches.group(2) ?? '0');
    return rv;
  }
}

class TemperatureCommand {
  static Uint8List get frame => utf8.encode("~M105\r\n");
  static String get name => 'temperature';
  static String get cmd => 'M105';
  static Map<String, int> parse(String data) {
    final rv = <String, int>{};
    // Format
    // CMD M105 Received.\r\n
    // T0:213 /210 B:60/60\r\n
    // ok
    final tmp = data.split('\r\n').elementAt(1);
    final matches = RegExp(r'T0:(\d+) ?/(\d+) B:(\d+)/(\d+)')
        .allMatches(tmp)
        .toList()
        .first;
    rv['voxelab_aries_extruder_current_temperature'] =
        int.tryParse(matches.group(1) ?? '0')!;
    rv['voxelab_aries_extruder_target_temperature'] =
        int.tryParse(matches.group(2) ?? '0')!;
    rv['voxelab_aries_base_current_temperature'] =
        int.tryParse(matches.group(3) ?? '0')!;
    rv['voxelab_aries_base_target_temperature'] =
        int.tryParse(matches.group(4) ?? '0')!;
    return rv;
  }
}

class MachineStatusCommand {
  static Uint8List get frame => utf8.encode('~M119\r\n');
  static String get name => 'machine_status';
  static String get cmd => 'M119';
  static Map<String, String> parse(String data) {
    final rv = <String, String>{};
    // Format
    // CMD M119 Received.
    // Endstop: X-max:0 Y-max:0 Z-max:0
    // MachineStatus: BUILDING_FROM_SD
    // MoveMode: MOVING
    // Status: S:0 L:0 J:0 F:0
    // ok

    final tmp = data.split('\r\n');
    final endstopLine = tmp.elementAt(1);
    final machineStatusLine = tmp.elementAt(2);
    final moveModeLine = tmp.elementAt(3);
    final statusLine = tmp.elementAt(4);
    rv['endstop_x_max'] = endstopLine.split(' ').elementAt(1).split(':').last;
    rv['endstop_y_max'] = endstopLine.split(' ').elementAt(2).split(':').last;
    rv['endstop_z_max'] = endstopLine.split(' ').elementAt(3).split(':').last;
    rv['machine_status'] = machineStatusLine.split(' ').last;
    rv['move_mode'] = moveModeLine.split(' ').last;
    rv['status_s'] = statusLine.split(' ').elementAt(1).split(':').last;
    rv['status_l'] = statusLine.split(' ').elementAt(2).split(':').last;
    rv['status_j'] = statusLine.split(' ').elementAt(3).split(':').last;
    rv['status_f'] = statusLine.split(' ').elementAt(4).split(':').last;
    return rv;
  }
}
