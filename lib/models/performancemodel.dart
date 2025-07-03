class PerformanceModel {
  String type;
  String subType;
  String duration;
  String distance;
  String repetitions;
  String series;
  String restTime;
  String intensity;
  String commentaire;

  PerformanceModel({
    this.type = 'Street Workout',
    this.subType = '',
    this.duration = '',
    this.distance = '',
    this.repetitions = '',
    this.series = '',
    this.restTime = '',
    this.intensity = '',
    this.commentaire = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'subType': subType,
      'duration': duration,
      'distance': distance,
      'repetitions': repetitions,
      'series': series,
      'restTime': restTime,
      'intensité': intensity,
      'commentaire': commentaire,
      'accompli': true,
    };
  }
}
