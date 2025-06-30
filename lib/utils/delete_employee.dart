import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeleteEmployeeDialog extends StatefulWidget {
  final String employeeName;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onRemoveFromList;

  const DeleteEmployeeDialog({
    super.key,
    required this.employeeName,
    required this.onConfirm,
    required this.onRemoveFromList,
  });

  @override
  State<DeleteEmployeeDialog> createState() => _DeleteEmployeeDialogState();
}

class _DeleteEmployeeDialogState extends State<DeleteEmployeeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isNameCorrect = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.removeEmployee),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.wantToRemoveEmployee(widget.employeeName)),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.enterNameToDeletePermanently,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _isNameCorrect = value.trim() == widget.employeeName.trim();
              });
            },
          ),
          SizedBox(height: 10),
          Text(
            l10n.permanentDeleteWarning,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            SizedBox(width: 5),
            ElevatedButton(
              //botão para remover da lista
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size(0, 36),
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                await widget.onRemoveFromList();
                Navigator.pop(context);
              },
              child: Text(l10n.removeFromList),
            ),
            SizedBox(width: 5),
            ElevatedButton(
              //botão para excluir permanentemente
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size(0, 36),
                backgroundColor: Colors.red,
              ),
              onPressed:
                  _isNameCorrect
                      ? () async {
                        await widget.onConfirm();
                        Navigator.pop(context);
                      }
                      : null,
              child: Text(l10n.delete),
            ),
          ],
        ),
      ],
    );
  }
}
