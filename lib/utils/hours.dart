import 'package:ponto/ponto.dart';

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