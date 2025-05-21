import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import '../database.dart';
import '../admin.dart';
import 'admin_login.dart';
import '/ponto.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminPanel extends StatefulWidget {
  final Admin admin;
  const AdminPanel({super.key, required this.admin});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  //calcula as horas trabalhadas no mês
  double calcularHorasTrabalhadasPorMes(List<Ponto> pontos) {
    final now = DateTime.now();
    final pontosDoMes = pontos.where(
      (p) => p.checkIn.month == now.month && p.checkIn.year == now.year,
    );
    //soma as horas trabalhadas
    return pontosDoMes.fold(0.0, (total, ponto) {
      if (ponto.checkOut != null) {
        final duracao = ponto.checkOut!.difference(ponto.checkIn).inHours;
        return total + duracao;
      }
      return total;
    });
  }

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
                        .where(
                          'selected',
                          isEqualTo: false,
                        ) // só não selecionados
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
                        subtitle: Text(data['email'] ?? ''),
                        trailing: ElevatedButton(
                          child: Text("Adicionar"),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('employees')
                                .doc(docs[index].id)
                                .update({'selected': true});
                            Navigator.pop(
                              context,
                            ); // Fecha o pop-up após adicionar
                            setState(() {}); // Atualiza a tela principal
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Painel Administrativo"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _showCadastroFuncionarioDialog,
          ),
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
                          Text("ID: ${widget.admin.id}"),
                          Text("Telefone: ${widget.admin.email}"),
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
              // Faz logout do Firebase Auth
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

                  return ListTile(
                    title: Text("${employee.name} (${employee.email})"),
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
                                pontos.last.location.toString().contains(',')) {
                              try {
                                final location =
                                    pontos.last.location.toString();
                                final latLng =
                                    location
                                        .split(',')
                                        .map(
                                          (e) =>
                                              double.tryParse(e.trim()) ?? 0.0,
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
                                                  () => Navigator.pop(context),
                                              child: Text("Fechar"),
                                            ),
                                          ],
                                        ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Localização inválida"),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                  content: Text("Localização não disponível"),
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
                      ],
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
