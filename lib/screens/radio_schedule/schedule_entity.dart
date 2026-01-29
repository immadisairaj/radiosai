class ScheduleEntity {
  ScheduleEntity({
    required this.dateTime,
    required this.category,
    required this.content,
    required this.durationMin,
    required this.relatedMediaFiles,
    required this.newFlag,
    required this.firstBroadcastOn,
  });
  DateTime dateTime;
  String category;
  String content;
  int durationMin;
  List<String> relatedMediaFiles;
  bool newFlag;
  String firstBroadcastOn;
}
