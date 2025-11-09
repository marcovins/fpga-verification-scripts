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

    localparam QTD_REPETICOES_TESTE = 10;
    localparam MAX_DURACAO_INTERMITENTE = 5299;
    localparam MIN_DURACAO_INTERMITENTE = 300;

    task automatic resetar; begin
            rst = 1;
            repeat (3) @(posedge clk);
            rst = 0;
        end
    endtask

    task simular_pressionar_botao(input int largura_pulso_ciclos);
        begin
            push_button = 1'b1;
            repeat(largura_pulso_ciclos) @(posedge clk);
            push_button = 1'b0;
            #10;
        end
    endtask

    task executar_teste_estimulos_intermitentes;
        begin
            $display("Geração de 10 pulsos para o push button");

            for (int i = 0; i < QTD_REPETICOES_TESTE; i++) begin
                int duracao_pulso_rand;
                logic saida_anterior;

                saida_anterior = saida;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);

                simular_pressionar_botao(duracao_pulso_rand);

                @(posedge clk);

                $display("-> Pressionando %2d/%0d: Pulso de %0d ciclos.", i+1, QTD_REPETICOES_TESTE, duracao_pulso_rand);
                $display("Saida: %b | saida anterior: %b", saida, saida_anterior);
                if (saida != saida_anterior)
                    $display("RESULTADO IMEDIATO: Saída = %0d | Led = %b | PASSOU!\n", saida, led);
                else
                    $display("RESULTADO IMEDIATO: Saída = %0d | Led = %b | FALHOU!\n", saida, led);
            end
        end
    endtask

    initial begin
        resetar();
        $display("******* Sistema RESETADO! *******");
        $display("Led: %b | Lampada: %b", led, saida);
        $display("******* Pressionando o botão por 5305 pulsos... *******");

        // Alterando para o modo manual pressionando o push button
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