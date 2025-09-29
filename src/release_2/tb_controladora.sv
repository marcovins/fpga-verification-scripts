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
    parameter int PULSOS_LIGAR_LAMPADA = 300;
    parameter int INTERVALO_MIN_IGNORA = 1;
    parameter int INTERVALO_MAX_IGNORA = 299;
    parameter int INTERVALO_MIN_ACEITA = 300;
    parameter int INTERVALO_MAX_ACEITA = 5299;
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
            #10;
        end
    endtask

    task automatic setarManual; begin
        // Garante que o sistema está em modo manual
        resetar();
        push_button = 1; // Pressiona o botão
        repeat(PULSOS_TROCAR_MODO + 10) @(posedge clk);
        push_button = 0; // Solta o botão
        #10;
        assert (dut.sub_2.state == 0) else 
            $fatal("Falha ao setar modo manual! Estado atual: %s", dut.sub_2.state.name());
        end
    endtask

    // Contadores para resumo dos testes
    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    string separador = "------------------------------------------------------";

    task automatic simularTeste(input int qnt_pulsos);
        logic lampada_esperado = (qnt_pulsos >= PULSOS_LIGAR_LAMPADA) ? 1'b1 : 1'b0;
        static int num_teste = 1;

        setarManual();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;

        $display("%s", separador);

        total_testes++;
        if (saida === lampada_esperado) begin
            testes_passaram++;
            $display("[PASSOU] | Teste: %2d | Pulsos: %4d | SAIDA: %b | ESPERADO: %b | ESTADO: %-18s | Tempo: %8t ns",
                num_teste, qnt_pulsos, saida, lampada_esperado, dut.sub_1.state.name(), $time);
        end else begin
            testes_falharam++;
            $display("[FALHOU] | Teste: %2d | Pulsos: %4d | SAIDA: %b | ESPERADO: %b | ESTADO: %-18s | Tempo: %8t ns",
                num_teste, qnt_pulsos, saida, lampada_esperado, dut.sub_1.state.name(), $time);
        end

        num_teste++;
        #5;
    endtask


    GeradorAleatorio gen;
    
    // Realizando os testes
    initial begin
      	#10;
        
        // Sinais iniciais
        $display("                      Iniciando testes...");
        $display("                      SAIDA: %b | LED: %b | ESTADO_SUBMODULO_1: %s\n\n", saida, led, dut.sub_1.state.name());

        // Teste: Pressionar o botão por 200 pulsos
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 200 pulsos (deve ser ignorado)\n");
        simularTeste(200);

        // Teste: Pressionar o botão por 300 pulsos
        repeat (2) $write("\n");
        $display("                      Pressionar o botão por 300 pulsos (deve ser aceito)\n");
        simularTeste(300);

        // Teste: Pressionar o botão 10 vezes entre 1 e 299 pulsos aleatoriamente
        repeat (2) $write("\n");
        $display("                      Pressionar o botão 10 vezes entre 1 e 299 pulsos aleatoriamente (devem ser ignorados)\n");
        $srandom(SEMENTE);

        gen = new(INTERVALO_MIN_IGNORA, INTERVALO_MAX_IGNORA);

        repeat(QNT_ALEATORIOS) begin
            gen.randomize();
            simularTeste(gen.num);
        end

        #10;

        // Teste: Pressionar o botão 10 vezes entre 300 e 5299 pulsos aleatoriamente
        repeat (2) $write("\n");
        $display("                      Pressionar o botão 10 vezes entre 300 e 5299 pulsos aleatoriamente (devem ser aceitos)\n");

        gen = new(INTERVALO_MIN_ACEITA, INTERVALO_MAX_ACEITA);

        repeat(QNT_ALEATORIOS) begin
            gen.randomize();
            simularTeste(gen.num);
        end

        $display("%s", separador);
        $display("Resumo dos testes:");
        $display("Total: %0d | Passaram: %0d | Falharam: %0d", total_testes, testes_passaram, testes_falharam);

        #100 $finish;
    end

endmodule
