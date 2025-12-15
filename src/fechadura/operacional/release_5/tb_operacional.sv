`timescale 1ns/1ns

module testbench_operacional;
    logic clk = 0;
    logic rst;
    logic sensor_contato = 0;
    logic botao_interno = 0;
    logic botao_bloqueio = 0;
    logic botao_config = 0;
    setupPac_t data_setup_new = '0;
    logic data_setup_ok = 0;
    senhaPac_t digitos_value = '1;
    logic digitos_valid = 0;
    bcdPac_t bcd_pac;
    logic teclado_en;
    logic display_en;
    logic setup_on;
    logic tranca;
    logic bip;

    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    int num_teste;

    operacional dut (
        .clk(clk),
        .rst(rst),
        .sensor_contato(sensor_contato),
        .botao_interno(botao_interno),
        .botao_bloqueio(botao_bloqueio),
        .botao_config(botao_config),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .bcd_pac(bcd_pac),
        .teclado_en(teclado_en),
        .display_en(display_en),
        .setup_on(setup_on),
        .tranca(tranca),
        .bip(bip)
    );
    
    always #1 clk = ~clk;

    task automatic reset();
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
    endtask

    task automatic print_teste(input bit condicao, input string msg_erro);
        total_testes++;
        if (condicao) begin
            $display("Teste %0d: PASSOU!", num_teste);
            testes_passaram++;
        end else begin
            testes_falharam++;
            if (msg_erro == "")
                $display("Teste %0d: FALHOU! (sem mensagem)", num_teste);
            else
                $display("Teste %0d: FALHOU! %s", num_teste, msg_erro);
        end
    endtask

    task automatic aguarda_ciclos(input int ciclos);
        repeat(ciclos) @(posedge clk);
    endtask

    task automatic execute_testes_release5;
        num_teste = 1;
        
        // Teste 1: Verificar estado inicial da tranca (deve estar travada)
        aguarda_ciclos(2);
        print_teste(tranca == 1'b1, "Tranca deveria estar travada (tranca=1) no estado inicial");
        num_teste++;
        
        // Teste 2: Pressionar botão interno - tranca deve destravar imediatamente
        botao_interno = 1'b1;
        aguarda_ciclos(1);
        print_teste(tranca == 1'b0, "Tranca deveria destravar imediatamente (tranca=0) ao pressionar botão interno");
        num_teste++;
        botao_interno = 1'b0;
        
    endtask

    initial begin
        reset();
        execute_testes_release5();
        
        $display("\n========================================");
        $display("RESUMO DOS TESTES - RELEASE O-05");
        $display("========================================");
        $display("Total de testes: %0d", total_testes);
        $display("Testes passaram: %0d", testes_passaram);
        $display("Testes falharam: %0d", testes_falharam);
        $display("========================================\n");
        
        #100 $finish;
    end

endmodule
