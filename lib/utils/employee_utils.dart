import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    as gmaps; // Prefixo para google_maps_flutter
import '../employee.dart';

/// Exibe a localização do funcionário em um mapa.
void showLocationDialog(BuildContext context, List<dynamic> pontos) {
  if (pontos.isNotEmpty &&
      pontos.last.location.toString().trim().isNotEmpty &&
      pontos.last.location.toString().contains(',')) {
    try {
      final location = pontos.last.location.toString();
      final latLng =
          location
              .split(',')
              .map((e) => double.tryParse(e.trim()) ?? 0.0)
              .toList();

      if (latLng.length == 2 && latLng[0] != 0.0 && latLng[1] != 0.0) {
        // Exibe o Google Map com a localização do funcionário
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Localização do Funcionário"),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target: gmaps.LatLng(latLng[0], latLng[1]),
                      zoom: 15,
                    ),
                    markers: {
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId("employee_location"),
                        position: gmaps.LatLng(latLng[0], latLng[1]),
                        infoWindow: const gmaps.InfoWindow(
                          title: "Localização do Funcionário",
                        ),
                      ),
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
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Localização inválida")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao processar localização: $e")),
      );
    }
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Localização não disponível")));
  }
}

/// Exibe o diálogo para definir o horário e os dias da semana.
void showDefineScheduleDialog(BuildContext context, Employee employee) {
  final List<String> daysOfWeek = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  final selectedDays = employee.notificationDays ?? [];

  showDialog(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text("Definir Horário e Dias da Semana"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Defina o horário de entrada:"),
                    const SizedBox(height: 4),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Horário de Entrada (HH:mm)',
                        hintText: 'Exemplo: 08:00',
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        employee.checkIn_Time = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Selecione os dias da semana:"),
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
                    child: const Text("Cancelar"),
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
                        const SnackBar(
                          content: Text("Horário e dias atualizados!"),
                        ),
                      );
                    },
                    child: const Text("Salvar"),
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
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text("Adicionar Funcionário"),
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
              child: const Text("Fechar"),
            ),
          ],
        ),
  );
}
