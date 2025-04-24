import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import 'database.dart';
import 'adminstorage.dart';
import 'admin.dart';
import 'admin_login.dart';

class AdminPanel extends StatefulWidget {
  final Admin admin; 
  const AdminPanel({super.key, required this.admin});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Administrativo"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Informações do Admin"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nome: ${widget.admin.name}"),
                      Text("ID: ${widget.admin.id}"),
                      Text("Telefone: ${widget.admin.phone}"),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Fechar"),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AdminStorage.clearAdmin();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Employee>>(
        future: Database.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar funcionários"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Nenhum funcionário cadastrado"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final employee = snapshot.data![index];

              return ListTile(
                title: Text("${employee.name} - ${employee.location}"),
                subtitle: Text(
                  "Entrada: ${employee.checkIn}\nSaída: ${employee.checkOut ?? 'Ainda trabalhando'}"
                ),
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
