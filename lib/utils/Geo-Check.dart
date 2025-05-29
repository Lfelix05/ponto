import 'package:geolocator/geolocator.dart';

Future<String> getCurrentLocation() async {
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

