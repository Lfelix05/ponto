import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/notifications.dart';
import '/employee.dart';
import '../database.dart';
import '../ponto.dart';
import '../utils/Geo-Check.dart';
import '../utils/hours.dart';
import 'home.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmployeePanel extends StatefulWidget {
  final Employee employee;
  const EmployeePanel({super.key, required this.employee});

  @override
  _EmployeePanelState createState() => _EmployeePanelState();
}

class _EmployeePanelState extends State<EmployeePanel> {
  Ponto? _currentPonto;
  bool _hasCheckedIn = false;
  String? _checkInTime;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
    _loadCurrentPonto();
  }

  void _loadEmployee() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(widget.employee.id)
            .get();
    setState(() {
      _checkInTime = doc.data()?['checkIn_Time'];
    });

    // Cancela agendamento anterior e agenda novamente com o novo horário
    await Workmanager().cancelByUniqueName(
      "checkin_reminder_${widget.employee.id}_${DateTime.now().day}",
    );
    agendarNotificacaoDeAusencia();
  }

  void agendarNotificacaoDeAusencia() {
    print('Chamou agendarNotificacaoDeAusencia');
    final checkInTime = _checkInTime;
    print('checkInTime: $checkInTime');
    if (checkInTime == null || !checkInTime.contains(':')) return;
    final parts = checkInTime.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    final delay = scheduled.difference(now);
    if (delay.isNegative) return;

    print('Agendando ausência para ${widget.employee.id} às $hour:$minute');

    Workmanager().registerOneOffTask(
      "checkin_reminder_${widget.employee.id}_${now.day}",
      "checkinReminderTask",
      initialDelay: delay,
      inputData: {'employeeId': widget.employee.id, 'checkInTime': checkInTime},
    );
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
    final location = await getCurrentLocation(context);

    // Salva no Firestore
    await FirebaseFirestore.instance
        .collection('employees')
        .doc(widget.employee.id)
        .collection('pontos')
        .add({
          'id': widget.employee.id,
          'name': widget.employee.name,
          'location': location, // <-- NUNCA, JAMAIS deixe salvar null!!!
          'checkIn': now, // <-- Salve como DateTime, não como string!
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
    // Notificação local
    final l10n = AppLocalizations.of(context)!;
    await showNotification(
      context,
      l10n.checkInCompleted,
      l10n.yourCheckInRegisteredSuccessfully,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.checkInSuccessful)));
    await flutterLocalNotificationsPlugin.cancel(100);
  }

  // Método para realizar o check-out
  void checkOut() async {
    final now = DateTime.now();
    final location = await getCurrentLocation(context);

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
          'checkOut': now, // Salve como DateTime
          'locationCheckOut': location,
        });
      }

      setState(() {
        _currentPonto!.checkOut = now;
        _hasCheckedIn = false;
      });

      final l10n = AppLocalizations.of(context)!;
      await showNotification(
        context,
        l10n.checkOutCompleted,
        l10n.exitRegisteredSuccessfully,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.checkOutSuccessful)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _hasCheckedIn ? Colors.green : Colors.red;
    final statusText = _hasCheckedIn ? l10n.present : l10n.absent;
    final statusIcon = _hasCheckedIn ? Icons.check_circle : Icons.cancel;
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
          title: Text(l10n.employeePanel),
          actions: [
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(l10n.employeeDetails),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.nameFormat(widget.employee.name)),
                            Text(l10n.phoneFormat(widget.employee.phone)),
                            SizedBox(height: 20),
                            Text(l10n.idFormat(widget.employee.id)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(l10n.close),
                          ),
                        ],
                      ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                clearLocalData();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.blue[50],
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 48,
                        color: Colors.blue[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        l10n.checkInStatus,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 28),
                          SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                l10n.scheduledEntry,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _checkInTime ?? l10n.notAvailable,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                backgroundColor:
                                    _hasCheckedIn ? Colors.grey : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _hasCheckedIn ? null : checkIn,
                              icon: Icon(Icons.login, size: 24),
                              label: Text(
                                l10n.checkIn,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                backgroundColor:
                                    _hasCheckedIn ? Colors.red : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _hasCheckedIn ? checkOut : null,
                              icon: Icon(Icons.logout, size: 24),
                              label: Text(
                                l10n.checkOut,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        _hasCheckedIn
                            ? l10n.checkInDoneAt(
                              _currentPonto?.checkIn != null
                                  ? dateFormat.format(_currentPonto!.checkIn)
                                  : l10n.notAvailable,
                            )
                            : l10n.checkOutDoneAt(
                              _currentPonto?.checkOut != null
                                  ? dateFormat.format(_currentPonto!.checkOut!)
                                  : l10n.notAvailable,
                            ),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 32),
                      FutureBuilder<List<Ponto>>(
                        future: Database.getPontosByEmployeeId(
                          widget.employee.id,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Text(l10n.loading);
                          final pontos = snapshot.data!;
                          final horasHoje = horasTrabalhadasPorDia(
                            pontos,
                            DateTime.now(),
                          );
                          final horasMes = calcularHorasTrabalhadasPorMes(
                            pontos,
                          );
                          return Column(
                            children: [
                              Card(
                                color: Colors.blue[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        l10n.hoursWorkedToday,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "$horasHoje",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        l10n.hoursWorkedThisMonth,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "$horasMes",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
