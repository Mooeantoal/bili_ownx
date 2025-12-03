enum DownloadType {
  videoOnly,    // 仅视频
  audioOnly,    // 仅音频
  combined,     // 音视频合并
}

class DownloadOption {
  final DownloadType type;
  final String name;
  final String description;
  final String fileExtension;

  const DownloadOption({
    required this.type,
    required this.name,
    required this.description,
    required this.fileExtension,
  });

  static const List<DownloadOption> options = [
    DownloadOption(
      type: DownloadType.combined,
      name: '音视频合并',
      description: '下载包含音频和视频的完整文件',
      fileExtension: 'mp4',
    ),
    DownloadOption(
      type: DownloadType.videoOnly,
      name: '仅视频',
      description: '只下载视频流（无音频）',
      fileExtension: 'mp4',
    ),
    DownloadOption(
      type: DownloadType.audioOnly,
      name: '仅音频',
      description: '只下载音频流（适合音乐）',
      fileExtension: 'm4a',
    ),
  ];
}