import '/employee.dart';
import 'package:flutter/material.dart';
import '../database.dart';
import '../ponto.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<String> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Serviço de localização desativado";
    }

    // Verifica as permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Permissão de localização negada";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Permissão de localização permanentemente negada";
    }

    // Obtém a localização atual
    final position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    return "${position.latitude}, ${position.longitude}";
  }

  void _checkIn() async {
    final now = DateTime.now();
    final location = await _getCurrentLocation();

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

  void _checkOut() async {
    final now = DateTime.now();
    final location = await _getCurrentLocation();

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

  double _calcularHorasTrabalhadasNoDia() {
    if (_currentPonto != null && _currentPonto!.checkOut != null) {
      return _currentPonto!.checkOut!
          .difference(_currentPonto!.checkIn)
          .inHours
          .toDouble();
    }
    return 0.0;
  }

  Future<double> _calcularHorasTrabalhadasNoMes() {
    // Simula o cálculo de horas trabalhadas no mês
    return Database.getPontosByEmployeeId(widget.employee.id).then((pontos) {
      final now = DateTime.now();
      final pontosDoMes = pontos.where(
        (p) => p.checkIn.month == now.month && p.checkIn.year == now.year,
      );
      return pontosDoMes.fold<double>(0.0, (double total, ponto) {
        if (ponto.checkOut != null) {
          return total + ponto.checkOut!.difference(ponto.checkIn).inHours;
        }
        return total;
      });
    });
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
              SizedBox(height: 10),
              Text(
                "Horas trabalhadas hoje: ${_calcularHorasTrabalhadasNoDia()}",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              FutureBuilder<double>(
                future: _calcularHorasTrabalhadasNoMes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Calculando horas trabalhadas no mês...");
                  }
                  return Text(
                    "Horas trabalhadas no mês: ${snapshot.data ?? 0.0}",
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _hasCheckedIn ? null : _checkIn,
                    child: Text("Check-in"),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasCheckedIn ? Colors.red : Colors.grey,
                    ),
                    onPressed: _hasCheckedIn ? _checkOut : null,
                    child: Text("Check-out"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
