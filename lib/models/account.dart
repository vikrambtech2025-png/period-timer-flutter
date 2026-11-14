class Account {
  final String id;
  final String email;
  final String name;
  final String salt;
  final String hash;
  final int rounds;
  final int createdAt;
  Account({
    required this.id,
    required this.email,
    required this.name,
    required this.salt,
    required this.hash,
    required this.rounds,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        name: j['name'] ?? '',
        salt: j['salt'] ?? '',
        hash: j['hash'] ?? '',
        rounds: j['rounds'] ?? 1500,
        createdAt: j['createdAt'] ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'salt': salt,
        'hash': hash,
        'rounds': rounds,
        'createdAt': createdAt,
      };
}