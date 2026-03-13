part of 'health_reading.dart';

class HealthReadingAdapter extends TypeAdapter<HealthReading> {
  @override
  final int typeId = 0;

  @override
  HealthReading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthReading(
      patientName: fields[0] as String,
      weight: fields[1] as double,
      height: fields[2] as double,
      bmi: fields[3] as double,
      heartRate: fields[4] as int,
      spo2: fields[5] as int,
      temperature: fields[6] as double,
      systolic: fields[7] as int,
      diastolic: fields[8] as int,
      timestamp: fields[9] as DateTime,
      synced: fields[10] as bool, userEmail: '',
    );
  }

  @override
  void write(BinaryWriter writer, HealthReading obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.patientName)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.bmi)
      ..writeByte(4)
      ..write(obj.heartRate)
      ..writeByte(5)
      ..write(obj.spo2)
      ..writeByte(6)
      ..write(obj.temperature)
      ..writeByte(7)
      ..write(obj.systolic)
      ..writeByte(8)
      ..write(obj.diastolic)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is HealthReadingAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}