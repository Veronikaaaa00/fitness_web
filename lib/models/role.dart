enum Role {
  member,
  trainer,
  admin;

  String get label => switch (this) {
        Role.member => 'Клиент',
        Role.trainer => 'Тренер',
        Role.admin => 'Администратор',
      };

  String get apiValue => name;

  static Role fromApi(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    return Role.values.firstWhere(
      (r) => r.name == v,
      orElse: () => Role.member,
    );
  }

  bool atLeast(Role other) => index >= other.index;
}
