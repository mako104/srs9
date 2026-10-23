import 'package:flutter/material.dart';
import 'package:srs8/data/models/create_post_request.dart';
import 'package:srs8/presentation/state/post_list_notifier.dart';
import 'package:srs8/presentation/state/users_notifier.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _userId;
  bool _submitted = false; // блокирует повторное нажатие

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);

    final request = CreatePostRequest(
      title: _title.text.trim(),
      body: _body.text.trim(),
      userId: _userId!,
    );
    // Optimistic UI: пост появляется в списке сразу, запрос идёт в фоне.
    final future = context.read<PostListNotifier>().createPost(request);
    Navigator.of(context).pop<Future<CreateOutcome>>(future);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UsersNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пост')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                final len = (v ?? '').trim().length;
                if (len == 0) return 'Введите заголовок';
                if (len < 5) return 'Минимум 5 символов';
                if (len > 100) return 'Максимум 100 символов';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLength: 1000,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Текст поста',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                final len = (v ?? '').trim().length;
                if (len == 0) return 'Введите текст поста';
                if (len < 10) return 'Минимум 10 символов';
                if (len > 1000) return 'Максимум 1000 символов';
                return null;
              },
            ),
            const SizedBox(height: 12),
            FormField<int>(
              validator: (v) => v == null ? 'Выберите автора' : null,
              builder: (state) => InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Автор',
                  errorText: state.errorText,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.value,
                    isExpanded: true,
                    hint: const Text('Выберите автора'),
                    items: users.options
                        .map(
                          (o) => DropdownMenuItem<int>(
                            value: o.key,
                            child: Text(o.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      state.didChange(v);
                      setState(() => _userId = v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitted ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }
}