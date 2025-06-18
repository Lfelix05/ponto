import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ponto/employee.dart';
import '../database.dart';
import '../admin.dart';
import '../utils/hours.dart';
import 'admin_login.dart';
import '/ponto.dart';
import '../utils/delete_employee.dart';

class AdminPanelWeb extends StatefulWidget {
  final Admin admin;
  const AdminPanelWeb({super.key, required this.admin});

  @override
  _AdminPanelWebState createState() => _AdminPanelWebState();
}

class _AdminPanelWebState extends State<AdminPanelWeb> {
  int _reloadKey = 0; // Chave para recarregar a lista de funcionários
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<Ponto> pontos = []; // Lista de pontos para localização

  // ignore: unused_element
  Future<void> _loadPontos(String employeeId) async {
    try {
      pontos = await Database.getPontosByEmployeeId(employeeId);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar pontos: $e')));
    }
  }

  void _showCadastroFuncionarioDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Adicionar Funcionário"),
            content: SizedBox(
              width: 400,
              height: 500,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('employees')
                        .where('selected', isEqualTo: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Nenhum funcionário disponível"),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['phone'] ?? ''),
                        trailing: ElevatedButton(
                          child: const Text("Adicionar"),
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
                child: const Text("Fechar"),
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
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Painel Administrativo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Informações do Admin"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Nome: ${widget.admin.name}"),
                          Text("Email: ${widget.admin.email}"),
                          const SizedBox(height: 20),
                          Text("ID: ${widget.admin.id}"),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Fechar"),
                        ),
                      ],
                    ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              clearLocalData(); // Limpa os dados locais
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 80, // Largura maior
        height: 80, // Altura maior
        child: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 73, 157, 217),
          splashColor: const Color(0xFF23608D),
          onPressed: _showCadastroFuncionarioDialog,
          tooltip: "Adicionar Funcionário",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: const Icon(
            Icons.add,
            size: 40, // Aumenta o tamanho do ícone
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ), // Limita a largura máxima para Web
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar funcionário por nome ou telefone',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Employee>>(
                  key: ValueKey(_reloadKey),
                  future: Database.getEmployees(widget.admin.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return const Center(
                        child: Text("Erro ao carregar funcionários"),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Nenhum funcionário cadastrado"),
                      );
                    }
                    final allEmployees = snapshot.data!;
                    final filteredEmployees =
                        allEmployees.where((employee) {
                          final name = employee.name.toLowerCase();
                          final phone = employee.phone.toLowerCase();
                          return name.contains(_searchText) ||
                              phone.contains(_searchText);
                        }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
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
                            final pontos =
                                pontosSnapshot.hasData
                                    ? pontosSnapshot.data!.docs
                                        .map(
                                          (doc) => Ponto.fromJson(
                                            doc.data() as Map<String, dynamic>,
                                          ),
                                        )
                                        .toList()
                                    : <Ponto>[];
                            final horasTrabalhadas =
                                calcularHorasTrabalhadasPorMes(pontos);
                            return Card(
                              color: Colors.white,
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            employee.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          iconSize: 40,
                                          icon: const Icon(
                                            Icons.map,
                                            color: Colors.blue,
                                          ),
                                          tooltip: "Ver localização",
                                          onPressed: () {
                                            if (pontos.isNotEmpty &&
                                                pontos.last.location
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty &&
                                                pontos.last.location
                                                    .toString()
                                                    .contains(',')) {
                                              try {
                                                final location =
                                                    pontos.last.location
                                                        .toString();
                                                final latLng =
                                                    location
                                                        .split(',')
                                                        .map(
                                                          (e) =>
                                                              double.tryParse(
                                                                e.trim(),
                                                              ),
                                                        )
                                                        .toList();

                                                if (latLng.length == 2 &&
                                                    latLng[0] != null &&
                                                    latLng[1] != null) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: const Text(
                                                            "Localização do Funcionário",
                                                          ),
                                                          content: SizedBox(
                                                            width:
                                                                double
                                                                    .maxFinite,
                                                            height: 300,
                                                            child: FlutterMap(
                                                              options: MapOptions(
                                                                center: LatLng(
                                                                  latLng[0]!,
                                                                  latLng[1]!,
                                                                ),
                                                                zoom: 15.0,
                                                              ),
                                                              children: [
                                                                TileLayer(
                                                                  urlTemplate:
                                                                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                                                  subdomains: [
                                                                    'a',
                                                                    'b',
                                                                    'c',
                                                                  ],
                                                                ),
                                                                MarkerLayer(
                                                                  markers: [
                                                                    Marker(
                                                                      width:
                                                                          80.0,
                                                                      height:
                                                                          80.0,
                                                                      point: LatLng(
                                                                        latLng[0]!,
                                                                        latLng[1]!,
                                                                      ),
                                                                      builder:
                                                                          (
                                                                            ctx,
                                                                          ) => const Icon(
                                                                            Icons.location_on,
                                                                            color:
                                                                                Colors.red,
                                                                            size:
                                                                                40,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                              child: const Text(
                                                                "Fechar",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
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
                                                      "Erro ao processar localização: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Localização não disponível",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          iconSize: 40,
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red[400],
                                          ),
                                          tooltip: "Excluir funcionário",
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (
                                                    context,
                                                  ) => DeleteEmployeeDialog(
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
                                    const SizedBox(height: 4),
                                    Text(
                                      "Telefone: ${employee.phone}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.login,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Última Entrada: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          pontos.isNotEmpty
                                              ? DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(pontos.last.checkIn)
                                              : 'Sem registro',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.logout,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Última Saída: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          pontos.isNotEmpty &&
                                                  pontos.last.checkOut != null
                                              ? DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(pontos.last.checkOut!)
                                              : 'Ainda trabalhando',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Horas hoje: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          horasTrabalhadasPorDia(
                                            pontos,
                                            DateTime.now(),
                                          ).toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          "Mês: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          horasTrabalhadas.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(120, 50),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text(
                                                    "Informações do Funcionário",
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Nome: ${employee.name}",
                                                      ),
                                                      Text(
                                                        "Telefone: ${employee.phone}",
                                                      ),
                                                      Text(
                                                        "Horas trabalhadas no mês: ${horasTrabalhadas.toStringAsFixed(2)}",
                                                      ),
                                                      SizedBox(height: 1),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "Defina o horário de entrada: ",
                                                          ),
                                                          SizedBox(width: 10),
                                                          TextButton(
                                                            onPressed: () async {
                                                              final picked =
                                                                  await showTimePicker(
                                                                    context:
                                                                        context,
                                                                    initialTime:
                                                                        TimeOfDay(
                                                                          hour:
                                                                              8,
                                                                          minute:
                                                                              0,
                                                                        ),
                                                                  );
                                                              if (picked !=
                                                                  null) {
                                                                final formatted =
                                                                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                                                await Database.setCheckInTime(
                                                                  employee.id,
                                                                  formatted,
                                                                );
                                                                // Atualiza o valor em memória buscando do banco
                                                                final doc =
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                          'employees',
                                                                        )
                                                                        .doc(
                                                                          employee
                                                                              .id,
                                                                        )
                                                                        .get();
                                                                print(
                                                                  doc.data(),
                                                                );
                                                                setState(() {
                                                                  employee.checkIn_Time =
                                                                      doc.data()?['checkIn_Time'];
                                                                  _reloadKey++;
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      "Horário de entrada definido para $formatted",
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: Text(
                                                              (employee.checkIn_Time ==
                                                                          null ||
                                                                      employee
                                                                          .checkIn_Time!
                                                                          .isEmpty)
                                                                  ? '00:00'
                                                                  : employee
                                                                      .checkIn_Time!,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 20),
                                                      Text(
                                                        "Código de verificação: ${employee.verificationCode ?? 'Não definido'}",
                                                      ),
                                                      Text(
                                                        "Envie o código para o funcionário para que ele possa redefinir a senha.",
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 32,
                                                              vertical: 16,
                                                            ),
                                                        textStyle: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      child: Text("Fechar"),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                        child: Text(
                                          "Detalhes",
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ),
    );
  }
}
