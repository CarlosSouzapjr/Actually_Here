sealed class AttendanceEvent {
  AttendanceEvent({
    required this.message,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  final String message;
  final DateTime occurredAt;
}

class AttendanceSessionStarted extends AttendanceEvent {
  AttendanceSessionStarted({
    required this.classId,
    required this.sessionId,
    super.occurredAt,
  }) : super(message: 'Sessao de presenca iniciada.');

  final int classId;
  final int sessionId;
}

class AttendanceSessionEnded extends AttendanceEvent {
  AttendanceSessionEnded({
    required this.sessionId,
    super.occurredAt,
  }) : super(message: 'Sessao de presenca encerrada.');

  final int sessionId;
}

class ActiveAttendanceSessionFound extends AttendanceEvent {
  ActiveAttendanceSessionFound({
    required this.classId,
    required this.sessionId,
    super.occurredAt,
  }) : super(message: 'Sessao ativa encontrada.');

  final int classId;
  final int sessionId;
}

class BeaconBroadcastStarted extends AttendanceEvent {
  BeaconBroadcastStarted({
    required this.beaconUuid,
    super.occurredAt,
  }) : super(message: 'Beacon iniciado.');

  final String beaconUuid;
}

class BeaconBroadcastStopped extends AttendanceEvent {
  BeaconBroadcastStopped({super.occurredAt})
      : super(message: 'Beacon parado.');
}

class ProfessorBeaconFound extends AttendanceEvent {
  ProfessorBeaconFound({
    required this.distance,
    super.occurredAt,
  }) : super(message: 'Professor encontrado.');

  final double distance;
}

class PresencePingPublished extends AttendanceEvent {
  PresencePingPublished({
    required this.classId,
    required this.studentId,
    required this.distance,
    super.occurredAt,
  }) : super(message: 'Ping de presenca publicado.');

  final int classId;
  final int studentId;
  final double distance;
}

class MqttConnected extends AttendanceEvent {
  MqttConnected({super.occurredAt}) : super(message: 'MQTT conectado.');
}

class MqttDisconnected extends AttendanceEvent {
  MqttDisconnected({super.occurredAt})
      : super(message: 'MQTT desconectado.');
}

class AttendanceError extends AttendanceEvent {
  AttendanceError({
    required this.source,
    required this.error,
    super.occurredAt,
  }) : super(message: 'Erro em $source: $error');

  final String source;
  final Object error;
}
