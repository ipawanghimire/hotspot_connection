class Peer {
  final String id;
  final String name;
  final String? host;

  Peer({
    required this.id,
    required this.name,
    this.host,
  });

  factory Peer.fromMap(Map<dynamic, dynamic> map) {
    return Peer(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      host: map['host'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
    };
  }
}
