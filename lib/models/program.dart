class Program {
  final String nom;
  final String jour;
  final String commentaire;
  final List<Map<String, dynamic>> exercices;

  Program({
    required this.nom,
    required this.jour,
    required this.commentaire,
    required this.exercices,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'jour': jour,
      'commentaire': commentaire,
      'exercices': exercices,
    };
  }
}
