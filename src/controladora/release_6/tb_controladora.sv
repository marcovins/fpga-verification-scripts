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

    parameter int SEMENTE = 1111;
    parameter int QNT_ALEATORIOS = 10;
    parameter int PULSOS_TROCAR_MODO = 5300;
    parameter int INTERVALO_MIN_RELEASE_6 = 300;
    parameter int INTERVALO_MAX_RELEASE_6 = 5299;

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

    task automatic resetar; begin
            rst = 1;
            repeat (3) @(posedge clk);
            rst = 0;
            #10;
        end
    endtask

    task automatic setarAutomatico; begin
        // Garante que o sistema está em modo manual
        resetar();
        assert (led == 0) else 
            $fatal("Falha ao setar modo automático! Estado atual: %s", dut.sub_1.state.name());
        end
    endtask

    // Contadores para resumo dos testes
    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    string separador = "------------------------------------------------------";

    task automatic simular_teste_release_6(input int qnt_pulsos);
        logic saida_esperado = 0;
        static int num_teste = 1;

        setarAutomatico();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;

        $display("%s", separador);

        total_testes++;
        if (saida === saida_esperado) begin
            testes_passaram++;
            $display("[PASSOU] | Teste: %2d | Pulsos: %4d | SAIDA: %b | ESPERADO: %b | ESTADO: %-18s | Tempo: %8t ns",
                num_teste, qnt_pulsos, saida, saida_esperado, dut.sub_1.state.name(), $time);
        end else begin
            testes_falharam++;
            $display("[FALHOU] | Teste: %2d | Pulsos: %4d | SAIDA: %b | ESPERADO: %b | ESTADO: %-18s | Tempo: %8t ns",
                num_teste, qnt_pulsos, saida, saida_esperado, dut.sub_1.state.name(), $time);
        end

        num_teste++;
        #5;
    endtask

    GeradorAleatorio gen;

    initial begin
        resetar();
        #10;

        // Sinais iniciais
        $display("                      Iniciando testes...");
        $display("                      SAIDA: %b | LED: %b | ESTADO_SUBMODULO_1: %s\n\n", saida, led, dut.sub_1.state.name());

        gen = new(INTERVALO_MIN_RELEASE_6, INTERVALO_MAX_RELEASE_6);

        repeat(QNT_ALEATORIOS) begin
            gen.randomize();
            simular_teste_release_6(gen.num);
        end

        $display("%s", separador);
        $display("Resumo dos testes:");
        $display("Total: %0d | Passaram: %0d | Falharam: %0d", total_testes, testes_passaram, testes_falharam);

        #100 $finish;

    end

endmodule