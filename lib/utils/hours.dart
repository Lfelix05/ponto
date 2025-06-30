import 'package:ponto/ponto.dart';
import 'package:shared_preferences/shared_preferences.dart';

//calcula as horas trabalhadas no mês
double calcularHorasTrabalhadasPorMes(List<Ponto> pontos) {
  final now = DateTime.now();
  final pontosDoMes = pontos.where(
    (p) => p.checkIn.month == now.month && p.checkIn.year == now.year,
  );
  //soma as horas trabalhadas
  return pontosDoMes.fold(0.0, (total, ponto) {
    if (ponto.checkOut != null) {
      final duracao = ponto.checkOut!.difference(ponto.checkIn).inHours;
      return total + duracao;
    }
    return total;
  });
}

//calcula as horas trabalhadas no mês anterior
double calcularHorasTrabalhadasMesAnterior(List<Ponto> pontos) {
  final now = DateTime.now();
  final mesAnterior = now.month == 1 ? 12 : now.month - 1;
  final anoMesAnterior = now.month == 1 ? now.year - 1 : now.year;

  final pontosDoMesAnterior = pontos.where(
    (p) => p.checkIn.month == mesAnterior && p.checkIn.year == anoMesAnterior,
  );
  //soma as horas trabalhadas no mês anterior
  return pontosDoMesAnterior.fold(0.0, (total, ponto) {
    if (ponto.checkOut != null) {
      final duracao = ponto.checkOut!.difference(ponto.checkIn).inHours;
      return total + duracao;
    }
    return total;
  });
}

//calcula as horas trabalhadas por dia
double horasTrabalhadasPorDia(List<Ponto> pontos, DateTime dia) {
  final pontosDoDia = pontos.where(
    (p) =>
        p.checkIn.day == dia.day &&
        p.checkIn.month == dia.month &&
        p.checkIn.year == dia.year,
  );
  return pontosDoDia.fold(0.0, (total, ponto) {
    if (ponto.checkOut != null) {
      final duracao = ponto.checkOut!.difference(ponto.checkIn).inHours;
      return total + duracao;
    }
    return total;
  });
}

// Método para limpar dados locais (ex: ao fazer logout)
void clearLocalData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
