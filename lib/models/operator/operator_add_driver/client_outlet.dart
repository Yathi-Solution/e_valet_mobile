/// One active Outlet of the Client, from GET /operators/client-outlets.
class ClientOutlet {
  final int id;
  final String name;

  const ClientOutlet({required this.id, required this.name});

  factory ClientOutlet.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['outletId'];
    return ClientOutlet(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      name: (json['name'] ?? json['outletName'] ?? '').toString(),
    );
  }
}
