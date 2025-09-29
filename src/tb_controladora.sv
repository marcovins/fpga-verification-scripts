`timescale 1ns/1ns

module tb_controladora;
    // Sinais principais
    logic clk = 0, rst = 1;
    logic push_button = 0;
    logic infravermelho = 0;
    logic led, saida;

    // Contador de ciclos (para debug)
    logic [12:0] cont;

    // Parâmetro de clock
    parameter int METADE_PERIODO = 1; // 1 ns -> periodo total 2 ns

    // Parâmetros do primeiro testbench
    parameter int PULSOS_TROCAR_MODO = 5300;
    parameter int INTERVALO_MIN = 4770;
    parameter int INTERVALO_MAX = 5830;
    parameter int QNT_ALEATORIOS_1 = 10;
    parameter int SEMENTE_1 = 1111;

    // Parâmetros do segundo testbench
    parameter int PULSOS_LIGAR_LAMPADA = 300;
    parameter int INTERVALO_MIN_IGNORA = 1;
    parameter int INTERVALO_MAX_IGNORA = 299;
    parameter int INTERVALO_MIN_ACEITA = 300;
    parameter int INTERVALO_MAX_ACEITA = 5299;
    parameter int QNT_ALEATORIOS_2 = 10;
    parameter int SEMENTE_2 = 1111;

    // Parâmetros do terceiro testbench
    localparam DURACAO_PULSO_LONGO = 10000;
    localparam TEMPO_ESPERA_EXTENSO = 30001;
    localparam CICLOS_ESTABILIZACAO_SENSOR = 4;
    localparam MAX_DURACAO_INTERMITENTE = 30;
    localparam MIN_DURACAO_INTERMITENTE = 1;
    localparam MAX_INTERVALO_INTERMITENTE = 30000;
    localparam MIN_INTERVALO_INTERMITENTE = 1;
    localparam QTD_REPETICOES_TESTE = 10;

    // Clock
    always #METADE_PERIODO clk = ~clk;

    // Instância do DUT
    controladora #(.SWITCH_MODE_MIN_T(PULSOS_TROCAR_MODO)) 
    dut (
        .clk(clk),
        .rst(rst),
        .push_button(push_button),
        .infravermelho(infravermelho),
        .led(led),
        .saida(saida)
    );

    // Gerador Aleatório
    class GeradorAleatorio;
        randc bit [12:0] num;
        int min, max;
        function new(input int min, input int max);
            this.min = min;
            this.max = max;
        endfunction
        constraint range_c { num inside {[min:max]}; }
    endclass

    // Dump para waveform
    initial begin
        $dumpfile("tb_controladora.vcd");
        $dumpvars(0, tb_controladora);
    end

    // Task do primeiro testbench
    task automatic resetar; begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        #10;
    end
    endtask

    task automatic teste_alternar_modos(input int qnt_pulsos);
        logic resultado;
        logic led_esperado = qnt_pulsos > PULSOS_TROCAR_MODO;
        static int num_teste = 1;
        string status;
        resetar();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;
        $display("%s", separador);
        if (led === led_esperado) begin
            status = "PASSOU";
        end else begin
            status = "FALHOU";
        end
        $display("[%-6s] | Teste: %2d | Pulsos: %4d | LED: %b | ESPERADO: %b | TEMPO: %8t ns",
            status, num_teste, qnt_pulsos, led, led_esperado, $time);
        num_teste++;
        #5;
    endtask

    // Tasks do segundo testbench
    task automatic setarManual; begin
        resetar();
        push_button = 1;
        repeat(PULSOS_TROCAR_MODO + 10) @(posedge clk);
        push_button = 0;
        #10;
        assert (dut.sub_2.state == 0) else 
            $fatal("Falha ao setar modo manual! Estado atual: %s", dut.sub_2.state.name());
    end
    endtask

    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    string separador = "------------------------------------------------------";

    task automatic simularTeste(input int qnt_pulsos);
        logic lampada_esperado = (qnt_pulsos >= PULSOS_LIGAR_LAMPADA) ? 1'b1 : 1'b0;
        static int num_teste = 1;
        string status;
        setarManual();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;
        $display("%s", separador);
        total_testes++;
        if (saida === lampada_esperado) begin
            testes_passaram++;
            status = "PASSOU";
        end else begin
            testes_falharam++;
            status = "FALHOU";
        end
        $display("[%-6s] | Teste: %2d | Pulsos: %4d | SAIDA: %b | ESPERADO: %b | ESTADO: %-18s | Tempo: %8t ns",
            status, num_teste, qnt_pulsos, saida, lampada_esperado, dut.sub_1.state.name(), $time);
        num_teste++;
        #5;
    endtask

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

    GeradorAleatorio gen;
    
    // Realizando os testes
    initial begin
        #10;
        $display("                      Iniciando testes...");
        $display("\n\n                      Testes RELEASE1:");
        $display("                      Pressionar o botão por 5300 pulsos (deve ser ignorado)");
        teste_alternar_modos(5300);
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 5301 pulsos (deve ser aceito)");
        teste_alternar_modos(5301);
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 5305 pulsos (deve ser aceito)");
        teste_alternar_modos(5305);
        repeat (2) $write("\n");
        $display("                      Gerar 10 pressões variando entre 4770 e 5830 pulsos de forma aleatória:\n");
        $srandom(SEMENTE_1);
        gen = new(INTERVALO_MIN, INTERVALO_MAX);
        repeat(QNT_ALEATORIOS_1) begin
            gen.randomize();
            teste_alternar_modos(gen.num);
        end
        // Testes do segundo testbench
        #10;
        $display("\n\n                      Testes RELEASE2:");
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 200 pulsos (deve ser ignorado)\n");
        simularTeste(200);
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 300 pulsos (deve ser aceito)\n");
        simularTeste(300);
        repeat (2) $write("\n");
        $display("                      Pressionar o botão 10 vezes entre 1 e 299 pulsos aleatoriamente (devem ser ignorados)\n");
        $srandom(SEMENTE_2);
        gen = new(INTERVALO_MIN_IGNORA, INTERVALO_MAX_IGNORA);
        repeat(QNT_ALEATORIOS_2) begin
            gen.randomize();
            simularTeste(gen.num);
        end
        #10;
        repeat (2) $write("\n");
        $display("                      Pressionar o botão 10 vezes entre 300 e 5299 pulsos aleatoriamente (devem ser aceitos)\n");
        gen = new(INTERVALO_MIN_ACEITA, INTERVALO_MAX_ACEITA);
        repeat(QNT_ALEATORIOS_2) begin
            gen.randomize();
            simularTeste(gen.num);
        end

        

        $display("\n\n                      Testes RELEASE3:");
        repeat (2) $write("\n");
        $display("%s", separador);
        // Execução dos cenários de teste
        executar_teste_pulso_longo();
        executar_teste_estimulos_intermitentes();

        $display("Resumo dos testes:");
        $display("Total: %0d | Passaram: %0d | Falharam: %0d", total_testes, testes_passaram, testes_falharam);
        #100 $finish;
    end

endmodule