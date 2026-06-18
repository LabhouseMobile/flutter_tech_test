// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Podcast _$PodcastFromJson(Map<String, dynamic> json) => Podcast(
      id: (json['collectionId'] as num).toInt(),
      title: json['collectionName'] as String,
      author: json['artistName'] as String,
      feedUrl: json['feedUrl'] as String,
      artworkUrl: json['artworkUrl600'] as String?,
      genre: json['primaryGenreName'] as String?,
      episodeCount: (json['trackCount'] as num?)?.toInt(),
    );
