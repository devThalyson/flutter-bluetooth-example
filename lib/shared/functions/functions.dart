class Functions {
  static String calcularPesagem(List<int> pesoEmBytes) {
    print(pesoEmBytes);

    if (pesoEmBytes.isNotEmpty) {
      int menorByteDoPeso = pesoEmBytes[2];

      int maiorByteDoPeso = pesoEmBytes[1];

      int resultadoCalculoInteiroNaoAssinaladoDe16Bits =
          (menorByteDoPeso * 256) + maiorByteDoPeso;

      double multiplicadorParaPesoReal = 0.05;

      return (resultadoCalculoInteiroNaoAssinaladoDe16Bits *
              multiplicadorParaPesoReal)
          .toString();
    }

    return '0';
  }
}
