// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indian_food_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IndianFoodModelAdapter extends TypeAdapter<IndianFoodModel> {
  @override
  final int typeId = 2;

  @override
  IndianFoodModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IndianFoodModel(
      id: fields[0] as String,
      name: fields[1] as String,
      hindiName: fields[2] as String,
      category: fields[3] as String,
      region: fields[4] as String,
      calories: fields[5] as double,
      protein: fields[6] as double,
      carbs: fields[7] as double,
      fats: fields[8] as double,
      fiber: fields[9] as double,
      servingSize: fields[10] as String,
      keywords: (fields[11] as List).cast<String>(),
      isVeg: fields[12] as bool,
      imageUrl: fields[13] as String,
      dataSource: fields[14] as String,
      lastUpdated: fields[15] as String,
      sugar: fields[16] as double?,
      novaGroup: fields[17] as int?,
      isProcessed: fields[18] as bool?,
      unitType: fields[19] == null ? 'gram' : fields[19] as String,
      unitWeightGrams: fields[20] == null ? 100.0 : fields[20] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IndianFoodModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.hindiName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.region)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.carbs)
      ..writeByte(8)
      ..write(obj.fats)
      ..writeByte(9)
      ..write(obj.fiber)
      ..writeByte(10)
      ..write(obj.servingSize)
      ..writeByte(11)
      ..write(obj.keywords)
      ..writeByte(12)
      ..write(obj.isVeg)
      ..writeByte(13)
      ..write(obj.imageUrl)
      ..writeByte(14)
      ..write(obj.dataSource)
      ..writeByte(15)
      ..write(obj.lastUpdated)
      ..writeByte(16)
      ..write(obj.sugar)
      ..writeByte(17)
      ..write(obj.novaGroup)
      ..writeByte(18)
      ..write(obj.isProcessed)
      ..writeByte(19)
      ..write(obj.unitType)
      ..writeByte(20)
      ..write(obj.unitWeightGrams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndianFoodModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
