class ScheduleEntity {
  ScheduleEntity({
    required this.dateTime,
    required this.category,
    required this.content,
    required this.durationMin,
    required this.relatedLink,
    required this.newFlag,
    required this.firstBroadcastOn,
  });
  DateTime dateTime;
  String category;
  String content;
  int durationMin;
  String relatedLink;
  bool newFlag;
  String firstBroadcastOn;
}
