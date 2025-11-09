`timescale 1ns/1ps

module tb;

  // --- Sinais de Interface ---
  logic clk = 0;
  logic rst;
  logic push_button;
  logic infravermelho;
  logic led;
  logic saida;

  // --- Geração de Clock ---
  // Período de 2ns (500 MHz)
  always #1 clk = ~clk;

  // --- Instanciação do Módulo sob Teste (DUT) ---
  controladora #(
    .DEBOUNCE_P(300),
    .SWITCH_MODE_MIN_T(5300),
    .AUTO_SHUTDOWN_T(30000)
  ) dut (
    .clk(clk),
    .rst(rst),
    .infravermelho(infravermelho),
    .push_button(push_button),
    .led(led),
    .saida(saida)
  );

  // --- Parâmetros de Simulação ---
  localparam DURACAO_PULSO_LONGO = 10000;
  localparam TEMPO_ESPERA_EXTENSO = 30001;
  localparam CICLOS_ESTABILIZACAO_SENSOR = 4;
  localparam MAX_DURACAO_INTERMITENTE = 30;
  localparam MIN_DURACAO_INTERMITENTE = 1;
  localparam MAX_INTERVALO_INTERMITENTE = 30000;
  localparam MIN_INTERVALO_INTERMITENTE = 1;
  localparam QTD_REPETICOES_TESTE = 10;

  // ------------------------------------------------------------------
  // Bloco de Verificação para o Módulo de Controle de Iluminação v3
  // ------------------------------------------------------------------

  // --- Tarefa para simular a ativação do sensor ---
  task simular_estimulo_proximidade(input int largura_pulso_ciclos);
    begin
      infravermelho = 1'b1;
      repeat(largura_pulso_ciclos) @(posedge clk);
      infravermelho = 1'b0;
      repeat(CICLOS_ESTABILIZACAO_SENSOR) @(posedge clk); // Aguarda estabilização do sinal
    end
  endtask

  // --- Cenário de Teste 1: Pulso único de longa duração ---
  task executar_teste_pulso_longo;
    begin
      $display("Cenário 1: Pulso único de longa duração.");
      $display("VERIFICAÇÃO: A saída deve desativar após o tempo de espera definido.");

      simular_estimulo_proximidade(DURACAO_PULSO_LONGO);
      $display("Sensor ativado, saída acionada. Status da Saída: %0d", saida);

      $display("Sensor desativado. Aguardando %0d ciclos de clock...", TEMPO_ESPERA_EXTENSO);
      repeat(TEMPO_ESPERA_EXTENSO) @(posedge clk);

      $display("RESULTADO FINAL (Cenário 1): Sinal Infravermelho = %0d, Saída = %0d\n", infravermelho, saida);
    end
  endtask

  // --- Cenário de Teste 2: Estímulos intermitentes e aleatórios ---
  task executar_teste_estimulos_intermitentes;
    begin
      $display("Cenário 2: Simulação de %0d movimentos intermitentes.", QTD_REPETICOES_TESTE);
      $display("VERIFICAÇÃO: A saída deve permanecer acesa durante todo o cenário.");

      for (int i = 0; i < QTD_REPETICOES_TESTE; i++) begin
        int duracao_pulso_rand, intervalo_rand;

        duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
        intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

        simular_estimulo_proximidade(duracao_pulso_rand);
        $display("  -> Movimento %2d/%d: Pulso de %0d ciclos, seguido por pausa de %0d ciclos.", i+1, QTD_REPETICOES_TESTE, duracao_pulso_rand, intervalo_rand);
        $display("     RESULTADO IMEDIATO: Saída = %0d", saida);

        repeat(intervalo_rand) @(posedge clk);
      end
      $display("\nRESULTADO FINAL (Cenário 2): Saída = %0d\n", saida);
    end
  endtask

  // ----------------------------------------
  // --- Sequência Principal de Execução ---
  // ----------------------------------------
  initial begin
    // Inicialização dos sinais
    rst = 1'b1;
    push_button = 1'b0;
    infravermelho = 1'b0;
    
    $display("\n*********** INICIANDO VERIFICAÇÃO - REVISÃO 03 ***********\n");

    // Reset inicial do sistema
    #10; // Estabiliza antes do reset
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    // Execução dos cenários de teste
    executar_teste_pulso_longo();
    executar_teste_estimulos_intermitentes();

    $display("*********** FIM DA VERIFICAÇÃO - REVISÃO 03 ***********\n");
    $stop;
  end

endmodule