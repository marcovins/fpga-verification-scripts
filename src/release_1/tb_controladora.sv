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

    // Clock
    always #METADE_PERIODO clk = ~clk;

    // Instância do DUT
    controladora #(.SWITCH_MODE_MIN_T(5300)) 
    dut (
        .clk(clk),
        .rst(rst),
        .push_button(push_button),
        .infravermelho(infravermelho),
        .led(led),
        .saida(saida)
    );

    // Dump para waveform
    initial begin
        $dumpfile("tb_controladora.vcd");
        $dumpvars(0, tb_controladora);
    end

    task automatic resetar; begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        end
    endtask

    task automatic teste_alternar_modos(input int qnt_pulsos, 
                                        input int num_teste, 
                                        input logic led_esperado);
        logic resultado;

        resetar();
        // $display("\n== Teste Segurar push_button por %0d ciclos (%0t ns) ==",
        //         qnt_pulsos, qnt_pulsos * (2 * METADE_PERIODO));
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;

        #10;
        resultado = (led == led_esperado);
        $display("[%0t] Teste %0d: %s", $time, num_teste,
                resultado ? "PASSOU!" : "FALHOU!");
        #5;
    endtask

    initial begin
        // Teste 1: Pressionar o botão por 5300 pulsos -> Manter modo (led = 0)
        teste_alternar_modos(5300, 1, 0);

        // Teste 2: Pressionar o botão por 5301 pulsos -> Alternar modo (led = 1)
        teste_alternar_modos(5301, 2, 1);
        
        // Teste 3: Pressionar o botão por 5305 pulsos -> Alternar modo (led = 1)
        teste_alternar_modos(5305, 3, 1);

        #100 $finish;
    end

endmodule
