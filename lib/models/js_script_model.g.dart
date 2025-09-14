// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'js_script_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JsScriptAdapter extends TypeAdapter<JsScript> {
  @override
  final int typeId = 2;

  @override
  JsScript read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JsScript(
      id: fields[0] as String,
      name: fields[1] as String,
      script: fields[2] as String,
      type: fields[3] as JsScriptType,
      category: fields[4] as String,
      description: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, JsScript obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.script)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsScriptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JsScriptTypeAdapter extends TypeAdapter<JsScriptType> {
  @override
  final int typeId = 3;

  @override
  JsScriptType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return JsScriptType.regular;
      case 1:
        return JsScriptType.ai;
      default:
        return JsScriptType.regular;
    }
  }

  @override
  void write(BinaryWriter writer, JsScriptType obj) {
    switch (obj) {
      case JsScriptType.regular:
        writer.writeByte(0);
        break;
      case JsScriptType.ai:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsScriptTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
