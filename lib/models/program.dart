class Program {
  final String nom;
  final String date;
  final String commentaire;
  final List<Map<String, dynamic>> exercices;

  Program({
    required this.nom,
    required this.date,
    required this.commentaire,
    required this.exercices,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'jour':  date,
      'commentaire': commentaire,
      'exercices': exercices,
    };
  }
}
