import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ponto/employee.dart';
import 'package:ponto/utils/employee_utils.dart';
import '../database.dart';
import '../admin.dart';
import 'home.dart';
import '/ponto.dart';
import 'package:intl/intl.dart';
import '../utils/hours.dart';
import '../utils/delete_employee.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        // Bloqueia o botão "voltar" e exibe uma mensagem
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.useLogoutButton)));
        return false; // Retorna false para impedir que o usuário saia da tela
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 195, 230, 255),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.adminPanel),
          actions: [
            // Botão para exibir informações do admin
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(l10n.adminDetails),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.nameFormat(widget.admin.name)),
                            Text(l10n.emailFormat(widget.admin.email)),
                            SizedBox(height: 20),
                            Text(l10n.idFormat(widget.admin.id)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.close),
                          ),
                        ],
                      ),
                );
              },
            ),
            // Botão para logout
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
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
            Padding(
              // Campo de busca para filtrar funcionários
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.searchEmployee,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fillColor: Color.fromARGB(255, 255, 255, 255),
                  filled: true,
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
                    return Center(child: Text(l10n.errorLoadingEmployees));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(l10n.noEmployeesRegistered));
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                            margin: EdgeInsets.symmetric(
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
                                        icon: Icon(
                                          Icons.map,
                                          color: Colors.blue[400],
                                        ),
                                        tooltip: l10n.viewLocation,
                                        onPressed: () {
                                          showLocationDialog(context, pontos);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red[400],
                                        ),
                                        tooltip: l10n.deleteEmployee,
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
                                  SizedBox(height: 4),
                                  Text(
                                    l10n.phoneFormat(employee.phone),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.login,
                                        size: 18,
                                        color: Colors.blue[300],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        l10n.lastEntry,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        pontos.isNotEmpty
                                            ? DateFormat(
                                              'dd/MM/yyyy HH:mm',
                                            ).format(pontos.last.checkIn)
                                            : l10n.noRecord,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Colors.blue[300],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        l10n.lastExit,
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
                                            : l10n.stillWorking,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.blue[300],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        l10n.workedHoursToday,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        horasTrabalhadasPorDia(
                                          pontos,
                                          DateTime.now(),
                                        ).toStringAsFixed(2),
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        l10n.workedHoursMonth,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        horasTrabalhadas.toStringAsFixed(2),
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text(
                                                  l10n.employeeInformation,
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n.nameFormat(
                                                        employee.name,
                                                      ),
                                                    ),
                                                    Text(
                                                      l10n.phoneFormat(
                                                        employee.phone,
                                                      ),
                                                    ),
                                                    Text(
                                                      l10n.hoursWorkedLastMonth(
                                                        calcularHorasTrabalhadasMesAnterior(
                                                          pontos,
                                                        ).toStringAsFixed(2),
                                                      ),
                                                    ),
                                                    SizedBox(height: 1),
                                                    Row(
                                                      children: [
                                                        Text(l10n.setEntryTime),
                                                        TextButton(
                                                          onPressed: () {
                                                            showDefineScheduleDialog(
                                                              context,
                                                              employee,
                                                            );
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
                                                      l10n.verificationCode(
                                                        employee.verificationCode ??
                                                            l10n.verificationCodeNotDefined,
                                                      ),
                                                    ),
                                                    Text(
                                                      l10n.sendCodeInstruction,
                                                      style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors.grey[600],
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
                                                    child: Text(l10n.close),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      child: Text(
                                        l10n.details,
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 73, 157, 217),
          splashColor: Color(0xFF23608D),
          onPressed: () {
            showCadastroFuncionarioDialog(
              context: context,
              adminId: widget.admin.id,
              onReload: () {
                setState(() {
                  _reloadKey++;
                });
              },
            );
          },
          tooltip: l10n.addEmployeeTooltip,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
