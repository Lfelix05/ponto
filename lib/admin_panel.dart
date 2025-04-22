import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import 'database.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Painel Administrativo")),
      body: FutureBuilder<List<Employee>>(
        future: Database.getEmployees(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final employee = snapshot.data![index];

              return ListTile(
                title: Text("${employee.name} - ${employee.location}"),
                subtitle: Text("Entrada: ${employee.checkIn}\nSaída: ${employee.checkOut ?? 'Ainda trabalhando'}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Database.deleteEmployee(employee.id);
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
