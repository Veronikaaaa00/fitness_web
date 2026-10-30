import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../repositories/member_profiles_repository.dart';
import '../state/auth_notifier.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';

/// 1:1 профиль клиента (member_profiles).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  final _notes = TextEditingController();
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _phone.dispose();
    _birth.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthNotifier>().user?.id;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await context.read<MemberProfilesRepository>().byUser(userId);
      if (!mounted) return;
      if (profile != null) {
        _phone.text = profile.phone;
        _birth.text = profile.birthDate;
        _notes.text = profile.notes;
      }
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthNotifier>().user?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      await context.read<MemberProfilesRepository>().upsert(
            userId: userId,
            phone: _phone.text.trim(),
            birthDate: _birth.text.trim(),
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Мой профиль',
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _phone,
                                decoration: const InputDecoration(
                                  labelText: 'Телефон',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    Validators.minLength(v, 5, label: 'Телефон'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _birth,
                                decoration: const InputDecoration(
                                  labelText: 'Дата рождения (ГГГГ-ММ-ДД)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _notes,
                                decoration: const InputDecoration(
                                  labelText: 'Заметки',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
