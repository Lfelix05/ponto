import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
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

// Função para agendar notificação de lembrete de check-in
Future<void> scheduleCheckInReminder({
  required String employeeId,
  required String? checkInTime,
}) async {
  // checkInTime no formato "HH:mm"
  final parts = (checkInTime ?? "08:00").split(':');
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;

  final now = DateTime.now();
  final scheduled = DateTime(now.year, now.month, now.day, hour, minute);

  // Se já passou do horário hoje, não agenda
  if (now.isAfter(scheduled)) return;

  // Verifique se já fez check-in hoje
  final pontos = await Database.getPontosByEmployeeId(employeeId);
  final fezCheckInHoje = pontos.any(
    (p) =>
        p.checkIn.day == now.day &&
        p.checkIn.month == now.month &&
        p.checkIn.year == now.year,
  );
  if (fezCheckInHoje) return;

  // Agenda a notificação local
  await flutterLocalNotificationsPlugin.zonedSchedule(
    100,
    'Lembrete de Check-in',
    'Você ainda não fez o check-in hoje!',
    tz.TZDateTime.from(scheduled, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'ponto_channel',
        'Ponto Notificações',
        channelDescription: 'Notificações do app de ponto',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
