// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProcessingHistoryModelAdapter
    extends TypeAdapter<ProcessingHistoryModel> {
  @override
  final int typeId = 0;

  @override
  ProcessingHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProcessingHistoryModel(
      id: fields[0] as String,
      type: fields[1] as int,
      createdAt: fields[2] as DateTime,
      originalImagePath: fields[3] as String,
      processedImagePath: fields[4] as String,
      pdfPath: fields[5] as String?,
      fileSizeBytes: fields[6] as int,
      processingDurationMs: fields[7] as int,
      thumbnailPath: fields[8] as String,
      faceCount: fields[9] as int,
      extractedText: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProcessingHistoryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.originalImagePath)
      ..writeByte(4)
      ..write(obj.processedImagePath)
      ..writeByte(5)
      ..write(obj.pdfPath)
      ..writeByte(6)
      ..write(obj.fileSizeBytes)
      ..writeByte(7)
      ..write(obj.processingDurationMs)
      ..writeByte(8)
      ..write(obj.thumbnailPath)
      ..writeByte(9)
      ..write(obj.faceCount)
      ..writeByte(10)
      ..write(obj.extractedText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
