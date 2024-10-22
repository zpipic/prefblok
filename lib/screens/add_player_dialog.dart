import 'package:flutter/material.dart';

import '../models/models.dart';
import '../database/database_helper.dart';

class AddPlayerDialog extends StatefulWidget {
  final Function(Player) onPlayerAdded;
  final Player? player;

  const AddPlayerDialog({super.key, required this.onPlayerAdded, this.player});

  @override
  _AddPlayerDialogState createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog>{
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  String? _errorMsg;


  @override
  void initState() {
    super.initState();
    if (widget.player != null) {
      _nameController.text = widget.player!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _savePlayer() async {
    if (!_formKey.currentState!.validate()){
      return;
    }

    String name = _nameController.text.trim();

    if (widget.player == null || widget.player!.id == null) {
      // Adding a new player
      Player newPlayer = Player(name: name);
      int? playerId = await dbHelper.insertPlayer(newPlayer);

      if (playerId != null) {
        newPlayer.id = playerId;
        widget.onPlayerAdded(newPlayer);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMsg = 'Igrač već postoji';
          _formKey.currentState!.validate();
        });
      }
    } else {
      // Editing an existing player
      Player updatedPlayer = widget.player!;
      updatedPlayer.name = name;
      int result = await dbHelper.updatePlayer(updatedPlayer);

      if (result > 0) {
        widget.onPlayerAdded(updatedPlayer);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMsg = 'Ime več postoji';
          _formKey.currentState!.validate();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text((widget.player == null || widget.player!.id == null) ? 'Dodavanje novog igrača' : 'Uređivanje imena igrača'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ime',
                errorText: _errorMsg,
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty){
                  return 'Unesite ime igrača';
                } if (_errorMsg != null) {
                  return _errorMsg;
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _errorMsg = null;
                });
              },
            )
          ],
        )
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _savePlayer,
          child: Text(widget.player == null ? 'Dodaj' : 'Spremi'),
        ),
      ],
    );
  }
}