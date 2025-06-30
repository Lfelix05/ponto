import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/employee.dart';

/// Exibe a localização do funcionário em um mapa.
void showLocationDialog(BuildContext context, List<dynamic> pontos) {
  final l10n = AppLocalizations.of(context)!;

  // Verifica se há pontos com localização
  if (pontos.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.locationNotAvailable)));
    return;
  }

  // Busca pelo último ponto com localização válida
  String? location;
  for (int i = pontos.length - 1; i >= 0; i--) {
    final currentLocation = pontos[i].location?.toString() ?? "";
    if (currentLocation.trim().isNotEmpty &&
        currentLocation != "null" &&
        currentLocation.contains(',')) {
      location = currentLocation;
      break;
    }
  }

  if (location == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.locationNotAvailable)));
    return;
  }

  try {
    // Extrai as coordenadas - usa 0.0 como valor padrão em caso de erro no parse
    final latLng =
        location
            .split(',')
            .map((e) => double.tryParse(e.trim()) ?? 0.0)
            .toList();

    // Verifica se há duas coordenadas válidas
    if (latLng.length == 2 && latLng[0] != 0.0 && latLng[1] != 0.0) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l10n.employeeLocation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latLng[0], latLng[1]),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: LatLng(latLng[0], latLng[1]),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${latLng[0].toStringAsFixed(6)}, ${latLng[1].toStringAsFixed(6)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close, style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    final url = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=${latLng[0]},${latLng[1]}",
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.cannotOpenMap)),
                        );
                      }
                    }
                  },
                  child: Text(l10n.openInGoogleMaps),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidLocation)));
    }
  } catch (e) {
    // Logger pode ser implementado aqui em vez de print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.errorProcessingLocation(e.toString()))),
    );
  }
}

/// Exibe o diálogo para definir o horário e os dias da semana.
void showDefineScheduleDialog(BuildContext context, Employee employee) {
  final l10n = AppLocalizations.of(context)!;

  final List<String> daysOfWeek = [
    l10n.monday,
    l10n.tuesday,
    l10n.wednesday,
    l10n.thursday,
    l10n.friday,
    l10n.saturday,
    l10n.sunday,
  ];
  final selectedDays = employee.notificationDays ?? [];

  showDialog(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(l10n.defineScheduleAndDays),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.defineEntrySchedule),
                    const SizedBox(height: 4),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.entryTimeHint,
                        hintText: l10n.entryTimeExample,
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        employee.checkIn_Time = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.selectDaysOfWeek),
                    Wrap(
                      spacing: 8,
                      children:
                          daysOfWeek.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(employee.id)
                          .update({
                            'checkIn_Time': employee.checkIn_Time,
                            'notificationDays': selectedDays,
                          });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.scheduleUpdated)),
                      );
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
        ),
  );
}

/// Exibe o diálogo para adicionar um novo funcionário.
void showCadastroFuncionarioDialog({
  required BuildContext context,
  required String adminId,
  required VoidCallback onReload,
}) {
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(l10n.addEmployeeTitle),
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text(l10n.noEmployeesAvailable));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(data['phone'] ?? ''),
                      trailing: ElevatedButton(
                        child: Text(l10n.add),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('employees')
                              .doc(docs[index].id)
                              .update({'selected': true, 'adminId': adminId});
                          onReload(); // Chama a função de atualização
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
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(l10n.close),
            ),
          ],
        ),
  );
}
