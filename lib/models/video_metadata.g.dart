// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoMetadataAdapter extends TypeAdapter<VideoMetadata> {
  @override
  final int typeId = 1;

  @override
  VideoMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoMetadata(
      bvid: fields[0] as String,
      title: fields[1] as String,
      cover: fields[2] as String,
      author: fields[3] as String?,
      description: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      publishDate: fields[6] as DateTime,
      viewCount: fields[7] as int,
      likeCount: fields[8] as int,
      coinCount: fields[9] as int,
      favoriteCount: fields[10] as int,
      shareCount: fields[11] as int,
      duration: fields[12] as String,
      partCount: fields[13] as int,
      cachedAt: fields[14] as DateTime,
      categories: (fields[15] as List).cast<String>(),
      isFavorite: fields[16] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VideoMetadata obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.bvid)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.cover)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.publishDate)
      ..writeByte(7)
      ..write(obj.viewCount)
      ..writeByte(8)
      ..write(obj.likeCount)
      ..writeByte(9)
      ..write(obj.coinCount)
      ..writeByte(10)
      ..write(obj.favoriteCount)
      ..writeByte(11)
      ..write(obj.shareCount)
      ..writeByte(12)
      ..write(obj.duration)
      ..writeByte(13)
      ..write(obj.partCount)
      ..writeByte(14)
      ..write(obj.cachedAt)
      ..writeByte(15)
      ..write(obj.categories)
      ..writeByte(16)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}