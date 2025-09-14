// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_chain.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedChainAdapter extends TypeAdapter<SavedChain> {
  @override
  final int typeId = 0;

  @override
  SavedChain read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedChain(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      tools: (fields[3] as List).cast<SavedTool>(),
      created: fields[4] as DateTime,
      modified: fields[5] as DateTime,
      category: fields[6] as String?,
      tags: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SavedChain obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.tools)
      ..writeByte(4)
      ..write(obj.created)
      ..writeByte(5)
      ..write(obj.modified)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedChainAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedToolAdapter extends TypeAdapter<SavedTool> {
  @override
  final int typeId = 1;

  @override
  SavedTool read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedTool(
      id: fields[0] as String,
      toolType: fields[1] as String,
      settings: (fields[2] as Map).cast<String, dynamic>(),
      enabled: fields[3] as bool,
      order: fields[4] as int,
      category: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedTool obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.toolType)
      ..writeByte(2)
      ..write(obj.settings)
      ..writeByte(3)
      ..write(obj.enabled)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedToolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
