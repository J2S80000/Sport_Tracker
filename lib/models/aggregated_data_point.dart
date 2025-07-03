class AggregatedDataPoint {
  final String label;
  final double avgIntensity;
  final int count;
  final String nom;
  final String type;
  final String subType;
  final String commentaire;
  final DateTime rawDate;
  final int? series;
  final int? duration;
  final int? rest;

  AggregatedDataPoint({
    required this.label,
    required this.avgIntensity,
    required this.count,
    required this.nom,
    required this.commentaire,
    required this.type,
    required this.subType,
    required this.rawDate,
    this.series,
    this.duration,
    this.rest,
  });
}
