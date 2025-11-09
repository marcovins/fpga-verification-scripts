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

    localparam CICLOS_ESTABILIZACAO_SENSOR = 4;
    localparam MAX_DURACAO_INTERMITENTE = 30;
    localparam MIN_DURACAO_INTERMITENTE = 1;
    localparam MAX_INTERVALO_INTERMITENTE = 30000;
    localparam MIN_INTERVALO_INTERMITENTE = 1;
    localparam QTD_REPETICOES_TESTE = 10;

    task automatic resetar; begin
            rst = 1;
            repeat (3) @(posedge clk);
            rst = 0;
        end
    endtask

    task simular_estimulo_proximidade(input int largura_pulso_ciclos);
        begin
            infravermelho = 1'b1;
            repeat(largura_pulso_ciclos) @(posedge clk);
            infravermelho = 1'b0;
            repeat(CICLOS_ESTABILIZACAO_SENSOR) @(posedge clk); // Aguarda estabilização do sinal
            #10;
        end
    endtask

    task executar_teste_estimulos_intermitentes;
        begin
            $display("Geração de 10 pulsos para o infravermelho");

            for (int i = 0; i < QTD_REPETICOES_TESTE; i++) begin
                int duracao_pulso_rand, intervalo_rand;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
                intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

                simular_estimulo_proximidade(duracao_pulso_rand);

                $display("-> Movimento %2d/%0d: Pulso de %0d ciclos, seguido por pausa de %0d ciclos.", i+1, QTD_REPETICOES_TESTE, duracao_pulso_rand, intervalo_rand);

                if (led)
                    $display("RESULTADO IMEDIATO: Saída = %0d | Led = %b | PASSOU!\n", saida, led);
                else
                    $display("RESULTADO IMEDIATO: Saída = %0d | Led = %b | FALHOU!\n", saida, led);

                repeat(intervalo_rand) @(posedge clk);
            end

            $display("\nRESULTADO FINAL: Saída = %0d | Led = %b\n", saida, led);
        end
    endtask

    initial begin
        resetar();
        $display("******* Sistema RESETADO! *******");
        $display("Led: %b | Lampada: %b", led, saida);
        $display("******* Pressionando o botão por 5305 pulsos... *******");

        push_button = 1;
        repeat(5305) @(posedge clk);
        push_button = 0;
        #10;
        $display("Led: %b | Lampada: %b", led, saida);

        if (led)
            $display("Modo manual ativado com sucesso - PASSOU!");
        else
            $display("Modo manual não ativado - FALHOU!");

        executar_teste_estimulos_intermitentes();

        #100 $finish;
    end

endmodule