import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../database.dart';
import '../employee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showNotification(
  BuildContext context,
  String title,
  String body,
) async {
  final l10n = AppLocalizations.of(context)!;
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'ponto_channel',
        l10n.appTitle,
        channelDescription: l10n.notificationsChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: '',
  );
}

// Função para agendar ou disparar notificação de ausência/check-in
Future<void> scheduleCheckInReminder({
  BuildContext? context,
  required String employeeId,
  required String? checkInTime,
}) async {
  // Usaremos strings hardcoded como fallback quando o contexto não estiver disponível
  String absentTitle = 'Você está ausente!';
  String absentMessage = 'Você não fez o check-in no horário programado.';
  String appTitle = 'Ponto Eletrônico';
  String channelDescription = 'Notificações do app de ponto';
  String localeCode = 'pt_BR';

  // Se o contexto estiver disponível, use as traduções
  if (context != null) {
    final l10n = AppLocalizations.of(context)!;
    absentTitle = l10n.youAreAbsent;
    absentMessage = l10n.noCheckInScheduledTime;
    appTitle = l10n.appTitle;
    channelDescription = l10n.notificationsChannelDescription;
    localeCode = Localizations.localeOf(context).languageCode;
  }

  // Parâmetros de horário
  final parts = (checkInTime ?? "08:00").split(':');
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;

  final now = DateTime.now();
  final scheduled = DateTime(now.year, now.month, now.day, hour, minute);

  final doc =
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .get();
  final employee = Employee.fromJson(doc.data()!);

  // Verificar se o dia atual está nos dias selecionados
  final daysOfWeek = employee.notificationDays ?? [];
  final today = DateFormat(
    'EEEE',
    localeCode == 'en' ? 'en_US' : 'pt_BR',
  ).format(now);
  if (!daysOfWeek.contains(today)) {
    // Dia atual não está nos dias selecionados para notificações
    return;
  }

  final pontos = await Database.getPontosByEmployeeId(employeeId);
  final fezCheckInHoje = pontos.any(
    (p) =>
        p.checkIn.day == now.day &&
        p.checkIn.month == now.month &&
        p.checkIn.year == now.year,
  );

  // Se já fez check-in hoje, não precisa notificar
  if (fezCheckInHoje) {
    return;
  }

  if (now.isAfter(scheduled)) {
    // Horário já passou, dispara notificação de ausência
    await flutterLocalNotificationsPlugin.show(
      100,
      absentTitle,
      absentMessage,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ponto_channel',
          appTitle,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: '',
    );
    return;
  }

  // Horário ainda não passou, não precisa notificar
}
