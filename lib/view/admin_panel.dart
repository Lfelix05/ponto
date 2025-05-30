import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import '../database.dart';
import '../admin.dart';
import 'home.dart';
import '/ponto.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/hours.dart';
import '../utils/delete_employee.dart';

class AdminPanel extends StatefulWidget {
  final Admin admin;
  const AdminPanel({super.key, required this.admin});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _reloadKey = 0; // Chave para recarregar a lista de funcionários
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  void _showCadastroFuncionarioDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Adicionar Funcionário"),
            content: SizedBox(
              width: 300,
              height: 400,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('employees')
                        .where('selected', isEqualTo: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(child: Text("Nenhum funcionário disponível"));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['phone'] ?? ''),
                        trailing: ElevatedButton(
                          child: Text("Adicionar"),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('employees')
                                .doc(docs[index].id)
                                .update({
                                  'selected': true,
                                  'adminId': widget.admin.id,
                                });
                            setState(() {
                              _reloadKey++; // Atualiza a lista principal ANTES de fechar o diálogo
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Fechar"),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Painel Administrativo"),
        actions: [
          // Botão para exibir informações do admin
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
                          Text("Email: ${widget.admin.email}"),
                          SizedBox(height: 20),
                          Text("ID: ${widget.admin.id}"),
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
            // Botão de logout
            icon: Icon(Icons.logout),
            onPressed: () async {
              clearLocalData(); // Limpa os dados locais
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(                   // Campo de busca para filtrar funcionários
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar funcionário por nome ou telefone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Employee>>(
              // FutureBuilder para carregar os funcionários
              key: ValueKey(_reloadKey),
              future: Database.getEmployees(
                widget.admin.id,
              ), // Passe o id do admin aqui
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text("Erro ao carregar funcionários"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Nenhum funcionário cadastrado"));
                }
                // Lista de funcionários carregada com sucesso
                final allEmployees = snapshot.data!;
                final filteredEmployees =
                    allEmployees.where((employee) {
                      final name = employee.name.toLowerCase();
                      final phone = employee.phone.toLowerCase();
                      return name.contains(_searchText) ||
                          phone.contains(_searchText);
                    }).toList();

                return ListView.builder(
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('employees')
                              .doc(employee.id)
                              .collection('pontos')
                              .orderBy('checkIn', descending: false)
                              .snapshots(),
                      builder: (context, pontosSnapshot) {
                        if (pontosSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text(employee.name),
                            subtitle: Text("Carregando dados de ponto..."),
                          );
                        }
                        if (pontosSnapshot.hasError ||
                            !pontosSnapshot.hasData) {
                          return ListTile(
                            title: Text(employee.name),
                            subtitle: Text("Erro ao carregar dados de ponto"),
                          );
                        }

                        final pontos =
                            pontosSnapshot.data!.docs
                                .map(
                                  (doc) => Ponto.fromJson(
                                    doc.data() as Map<String, dynamic>,
                                  ),
                                )
                                .toList();
                        final horasTrabalhadas = calcularHorasTrabalhadasPorMes(
                          pontos,
                        );
                        // Exibe os dados do funcionário e seus pontos
                        return ListTile(
                          contentPadding: EdgeInsets.all(10),
                          title: Text(
                            "${employee.name} - ${employee.phone}",
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                              Text(
                                "Horas trabalhadas hoje: ${horasTrabalhadasPorDia(pontos, DateTime.now()).toStringAsFixed(2)}",
                              ),
                              Text(
                                "Horas trabalhadas no mês: ${horasTrabalhadas.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.map, color: Colors.blue),
                                onPressed: () {
                                  if (pontos.isNotEmpty &&
                                      pontos.last.location
                                          .toString()
                                          .trim()
                                          .isNotEmpty &&
                                      pontos.last.location.toString().contains(
                                        ',',
                                      )) {
                                    try {
                                      final location =
                                          pontos.last.location.toString();
                                      final latLng =
                                          location
                                              .split(',')
                                              .map(
                                                (e) =>
                                                    double.tryParse(e.trim()) ??
                                                    0.0,
                                              )
                                              .toList();

                                      if (latLng.length == 2 &&
                                          latLng[0] != 0.0 &&
                                          latLng[1] != 0.0) {
                                        //exibe o Google Map com a localização do funcionário
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text(
                                                  "Localização do Funcionário",
                                                ),
                                                content: Container(
                                                  width: double.maxFinite,
                                                  height: 300,
                                                  child: GoogleMap(
                                                    initialCameraPosition:
                                                        CameraPosition(
                                                          target: LatLng(
                                                            latLng[0],
                                                            latLng[1],
                                                          ),
                                                          zoom: 15,
                                                        ),
                                                    markers: {
                                                      Marker(
                                                        markerId: MarkerId(
                                                          "employee_location",
                                                        ),
                                                        position: LatLng(
                                                          latLng[0],
                                                          latLng[1],
                                                        ),
                                                        infoWindow: InfoWindow(
                                                          title:
                                                              "Localização do Funcionário",
                                                        ),
                                                      ),
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: Text("Fechar"),
                                                  ),
                                                ],
                                              ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Localização inválida",
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Erro ao processar localização",
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Localização não disponível",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // Botão para excluir o funcionário
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => DeleteEmployeeDialog(
                                          employeeName: employee.name,
                                          onRemoveFromList: () async {
                                            await Database.removeEmployee(
                                              employee.id,
                                            );
                                            setState(() {
                                              _reloadKey++;
                                            });
                                          },
                                          onConfirm: () async {
                                            await Database.deleteEmployee(
                                              employee.id,
                                            );
                                            setState(() {
                                              _reloadKey++;
                                            });
                                          },
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 73, 157, 217),
        splashColor: Color(0xFF23608D),
        onPressed: _showCadastroFuncionarioDialog,
        tooltip: "Adicionar Funcionário",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
