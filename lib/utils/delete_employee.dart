import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text("Remover Funcionário"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Você deseja remover ${widget.employeeName} da sua lista ou excluir permanentemente?",
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "Digite o nome para excluir permanentemente",
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
            "*Excluir é permanente e apaga todos os dados do funcionário.*",
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
              child: Text("Cancelar"),
            ),
            SizedBox(width: 5),
            ElevatedButton(                                           //botão para remover da lista
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size(0, 36),
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                await widget.onRemoveFromList();
                Navigator.pop(context);
              },
              child: Text("Remover da lista"),
            ),
            SizedBox(width: 5),
            ElevatedButton(                                          //botão para excluir permanentemente
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
              child: Text("Excluir"),
            ),
          ],
        ),
      ],
    );
  }
}
