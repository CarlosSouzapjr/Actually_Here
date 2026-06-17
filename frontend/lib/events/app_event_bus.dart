import 'dart:async';

import 'attendance_events.dart';

class AppEventBus {
  AppEventBus._();

  static final AppEventBus instance = AppEventBus._();

  final StreamController<AttendanceEvent> _attendanceController =
      StreamController<AttendanceEvent>.broadcast();

  Stream<AttendanceEvent> get attendanceEvents => _attendanceController.stream;

  void emitAttendance(AttendanceEvent event) {
    if (!_attendanceController.isClosed) {
      _attendanceController.add(event);
    }
  }

  void dispose() {
    _attendanceController.close();
  }
}
