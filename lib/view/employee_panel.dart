import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/employee.dart';
import '../database.dart';
import '../ponto.dart';
import '../utils/Geo-Check.dart';
import '../utils/hours.dart';

class EmployeePanel extends StatefulWidget {
  final Employee employee;
  const EmployeePanel({super.key, required this.employee});

  @override
  _EmployeePanelState createState() => _EmployeePanelState();
}

class _EmployeePanelState extends State<EmployeePanel> {
  Ponto? _currentPonto;
  bool _hasCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPonto();
  }

  void _loadCurrentPonto() async {
    final pontos = await Database.getPontosByEmployeeId(widget.employee.id);
    if (pontos.isNotEmpty) {
      setState(() {
        _currentPonto = pontos.last;
        _hasCheckedIn = _currentPonto!.checkOut == null;
      });
    }
  }

  // Método para realizar o check-in
  void checkIn() async {
    final now = DateTime.now();
    final location = await getCurrentLocation();

    // Salva no Firestore
    await FirebaseFirestore.instance
        .collection('employees')
        .doc(widget.employee.id)
        .collection('pontos')
        .add({
          'id': widget.employee.id,
          'name': widget.employee.name,
          'location': location, // <-- aqui: nunca salve null! JAMAIS!
          'checkIn': now.toIso8601String(),
          'checkOut': null,
        });

    setState(() {
      _currentPonto = Ponto(
        id: widget.employee.id,
        name: widget.employee.name,
        location: location,
        checkIn: now,
      );
      _hasCheckedIn = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Check-in realizado com sucesso!')));
  }

  // Método para realizar o check-out
  void checkOut() async {
    final now = DateTime.now();
    final location = await getCurrentLocation();

    if (_currentPonto != null) {
      // Busca o último ponto aberto (sem checkOut)
      final pontosRef = FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employee.id)
          .collection('pontos');
      final snapshot =
          await pontosRef
              .where('checkOut', isEqualTo: null)
              .orderBy('checkIn', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await pontosRef.doc(docId).update({
          'checkOut': now.toIso8601String(),
          'locationCheckOut': location,
        });
      }

      setState(() {
        _currentPonto!.checkOut = now;
        _hasCheckedIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-out realizado com sucesso! Localização: $location',
          ),
        ),
      );
    }
  }

  // Método para limpar dados locais (ex: ao fazer logout)
  void _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd/yyyy HH:mm'); // Formato desejado

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Painel do Funcionário'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Informações do Funcionário"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Nome: ${widget.employee.name}"),
                          Text("Telefone: ${widget.employee.phone}"),
                          SizedBox(height: 20),
                          Text("ID: ${widget.employee.id}"),
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
            onPressed: () {
              _clearLocalData(); // Limpa dados locais ao sair
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Status do Ponto",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                _hasCheckedIn
                    ? "Check-in realizado às: ${_currentPonto?.checkIn != null ? dateFormat.format(_currentPonto!.checkIn) : 'N/A'}"
                    : "Check-out realizado às: ${_currentPonto?.checkOut != null ? dateFormat.format(_currentPonto!.checkOut!) : 'N/A'}",
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      minimumSize: Size(0, 70),
                      backgroundColor:
                          _hasCheckedIn ? Colors.grey : Colors.green,
                    ),
                    onPressed: _hasCheckedIn ? null : checkIn,
                    child: Text("Check-in", style: TextStyle(fontSize: 20)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      minimumSize: Size(0, 70),
                      backgroundColor: _hasCheckedIn ? Colors.red : Colors.grey,
                    ),
                    onPressed: _hasCheckedIn ? checkOut : null,
                    child: Text("Check-out", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              SizedBox(height: 40),
              FutureBuilder<List<Ponto>>(
                future: Database.getPontosByEmployeeId(widget.employee.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text("Carregando...");
                  final pontos = snapshot.data!;
                  final horasHoje = horasTrabalhadasPorDia(
                    pontos,
                    DateTime.now(),
                  );
                  return Text("Horas trabalhadas hoje: $horasHoje");
                },
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Ponto>>(
                future: Database.getPontosByEmployeeId(widget.employee.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text("Carregando...");
                  final pontos = snapshot.data!;
                  final horasMes = calcularHorasTrabalhadasPorMes(pontos);
                  return Text("Horas trabalhadas no mês: $horasMes");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
