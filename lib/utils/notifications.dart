import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'ponto_channel',
        'Ponto Notificações',
        channelDescription: 'Notificações do app de ponto',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
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
  required String employeeId,
  required String? checkInTime,
}) async {
  print('scheduleCheckInReminder chamado para $employeeId em $checkInTime');
  final parts = (checkInTime ?? "08:00").split(':');
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;

  final now = DateTime.now();
  final scheduled = DateTime(now.year, now.month, now.day, hour, minute);

  final pontos = await Database.getPontosByEmployeeId(employeeId);
  print('Pontos encontrados: ${pontos.length}');
  final fezCheckInHoje = pontos.any(
    (p) =>
        p.checkIn.day == now.day &&
        p.checkIn.month == now.month &&
        p.checkIn.year == now.year,
  );
  print('Fez check-in hoje? $fezCheckInHoje');
  if (fezCheckInHoje) {
    print('Já fez check-in hoje, não notifica.');
    return;
  }

  if (now.isAfter(scheduled)) {
    print('Horário já passou, disparando notificação de ausência!');
    await flutterLocalNotificationsPlugin.show(
      100,
      'Você está ausente!',
      'Você não fez o check-in no horário programado.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ponto_channel',
          'Ponto Notificações',
          channelDescription: 'Notificações do app de ponto',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: '',
    );
    return;
  }

  print('Horário ainda não passou, não notifica.');
}
