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

    // Alguns parâmetros
    parameter int PULSOS_TROCAR_MODO = 5300;
    parameter int INTERVALO_MIN = 4770;
    parameter int INTERVALO_MAX = 5830;
    parameter int QNT_ALEATORIOS = 10;
    parameter int SEMENTE = 1111;

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

    class GeradorAleatorio;

        // randc garante que cada valor na faixa será sorteado uma vez antes de repetir
        randc bit [12:0] num; // bit [12:0] pode representar valores de 0 a 8191

        int min, max;

        function new(input int min, input int max); // Define o construtor
            this.min = min;
            this.max = max;
        endfunction

        // Define a faixa de valores válidos
        constraint range_c { num inside {[min:max]}; }
    endclass

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

    task automatic teste_alternar_modos(input int qnt_pulsos);
        logic resultado;
        logic led_esperado = qnt_pulsos > PULSOS_TROCAR_MODO;

        static int num_teste = 1;

        resetar(); // Realiza o reset no sistema

        push_button = 1; // Pressiona o botão
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0; // Solta o botão

        #10;

        if (led === led_esperado) begin
            $display("[%0t] Teste %0d: PASSOU! Pulsos: %0d | LED: %b",
            $time, num_teste, qnt_pulsos, led);
        end
        else begin
            $display("[%0t] Teste %0d: FALHOU! Pulsos: %0d | LED: %b -> ESPERADO: %b",
            $time, num_teste, qnt_pulsos, led, led_esperado);
        end

        num_teste++;
        #5;
    endtask

    GeradorAleatorio gen;
    
    // Realizando os testes
    initial begin
        // Teste: Pressionar o botão por 5300 pulsos
        teste_alternar_modos(5300);

        // Teste: Pressionar o botão por 5301 pulsos
        teste_alternar_modos(5301);
        
        // Teste: Pressionar o botão por 5305 pulsos
        teste_alternar_modos(5305);

        // Teste: Pressionar o botão 10 vezes entre 4770 e 5830 pulsos aleatoriamente
        $srandom(SEMENTE);

        gen = new(INTERVALO_MIN, INTERVALO_MAX);

        repeat(QNT_ALEATORIOS) begin
            gen.randomize();
            teste_alternar_modos(gen.num);
        end

        #100 $finish;
    end

endmodule
