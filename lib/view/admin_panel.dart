import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import '../database.dart';
import '../adminstorage.dart';
import '../admin.dart';
import 'admin_login.dart';
import '/ponto.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  final Admin admin;
  const AdminPanel({super.key, required this.admin});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  double calcularHorasTrabalhadasPorMes(List<Ponto> pontos) {
    final now = DateTime.now();
    final pontosDoMes = pontos.where(
      (p) => p.checkIn.month == now.month && p.checkIn.year == now.year,
    );

    return pontosDoMes.fold(0.0, (total, ponto) {
      if (ponto.checkOut != null) {
        final duracao = ponto.checkOut!.difference(ponto.checkIn).inHours;
        return total + duracao;
      }
      return total;
    });
  }

  void _showCadastroFuncionarioDialog() {
    final _phoneController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Cadastrar Funcionário"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Nome do Funcionário",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor, insira o nome do funcionário";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Número de Telefone",
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor, insira o número de telefone";
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return "Por favor, insira apenas números";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Adiciona o funcionário ao banco de dados
                    Database.addEmployee(
                      _nameController.text,
                      _phoneController.text,
                    );

                    // Limpa os campos do formulário
                    _nameController.clear();
                    _phoneController.clear();

                    // Atualiza a interface
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: Text("Cadastrar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Administrativo"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _showCadastroFuncionarioDialog,
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
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

              return FutureBuilder<List<Ponto>>(
                future: Database.getPontosByEmployeeId(employee.id),
                builder: (context, pontosSnapshot) {
                  if (pontosSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text("${employee.name}"),
                      subtitle: Text("Carregando dados de ponto..."),
                    );
                  }
                  if (pontosSnapshot.hasError || !pontosSnapshot.hasData) {
                    return ListTile(
                      title: Text("${employee.name}"),
                      subtitle: Text("Erro ao carregar dados de ponto"),
                    );
                  }

                  final pontos = pontosSnapshot.data!;
                  final horasTrabalhadas = calcularHorasTrabalhadasPorMes(
                    pontos,
                  );

                  return ListTile(
                    title: Text(
                      "${employee.name} - ${pontos.isNotEmpty ? pontos.last.location : 'Localização desconhecida'}",
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Última Entrada: ${pontos.isNotEmpty ? DateFormat('MM/dd/yyyy HH:mm').format(pontos.last.checkIn) : 'Sem registro'}",
                        ),
                        Text(
                          "Última Saída: ${pontos.isNotEmpty && pontos.last.checkOut != null ? DateFormat('MM/dd/yyyy HH:mm').format(pontos.last.checkOut!) : 'Ainda trabalhando'}",
                        ),
                        Text("Horas trabalhadas no mês: $horasTrabalhadas"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Excluir Funcionário"),
                              content: Text(
                                "Você tem certeza que deseja excluir ${employee.name}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Database.deleteEmployee(employee.id);
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text("Excluir"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
