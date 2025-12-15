`timescale 1ns/1ns

module testbench_operacional;
    parameter int UM_SEGUNDO = 1000;
    
    logic clk = 0;
    logic rst;
    logic sensor_contato = 1;
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

    task automatic aguarda_segundos(input int segundos);
        aguarda_ciclos(segundos * UM_SEGUNDO);
    endtask

    task automatic destravar_porta();
        // Destranca usando botão interno
        botao_interno = 1'b1;
        aguarda_ciclos(2);
        botao_interno = 1'b0;
        aguarda_ciclos(2);
    endtask

    task automatic fechar_porta();
        sensor_contato = 1'b1;
        aguarda_ciclos(2);
        $display("INFO: Porta fechada (sensor_contato=1)");
    endtask

    task automatic abrir_porta();
        sensor_contato = 1'b0;
        aguarda_ciclos(2);
        $display("INFO: Porta aberta (sensor_contato=0)");
    endtask

    task automatic execute_testes_release7;
        num_teste = 1;
        
        // Teste 1: Verificar estado inicial - porta fechada, tranca travada
        fechar_porta();
        aguarda_ciclos(5);
        print_teste(sensor_contato == 1'b1, "Porta deveria estar fechada inicialmente");
        num_teste++;
        
        // Teste 2: Destravar a porta
        destravar_porta();
        aguarda_ciclos(5);
        print_teste(tranca == 1'b0, "Tranca deveria estar destravada (tranca=0)");
        num_teste++;
        
        // Teste 3: Porta fechada - iniciar contagem do timer
        fechar_porta();
        aguarda_ciclos(5);
        print_teste(tranca == 1'b0, "Tranca ainda deve estar destravada no início da contagem");
        num_teste++;
        
        // Teste 4: Aguardar metade do tempo configurado - ainda destravada
        aguarda_ciclos( (UM_SEGUNDO * data_setup_new.timer_trancamento) * 3 / 4 );
        print_teste(tranca == 1'b0, "Tranca não deveria travar antes do tempo configurado.");
        num_teste++;

        // Teste 5: Aguardar completar o tempo configurado- tranca deve ativar
        aguarda_ciclos( (UM_SEGUNDO * data_setup_new.timer_trancamento) / 4 );
        print_teste(tranca == 1'b1, "Tranca deveria travar ao completar o tempo configurado.");
        num_teste++;

        // Teste 6: Destravar novamente e testar interrupção do timer
        destravar_porta();
        aguarda_ciclos(5);
        fechar_porta();
        aguarda_ciclos(5);
        aguarda_segundos(3);
        abrir_porta();
        aguarda_ciclos(5);
        aguardar_segundos(data_setup_new.timer_trancamento - 3);
        print_teste(tranca == 1'b0, "Tranca não deveria travar após interrupção do timer, contador não reiniciado.");
        num_teste++;
        
    endtask

    initial begin
        reset();
        execute_testes_release7();
        
        $display("\n========================================");
        $display("RESUMO DOS TESTES - RELEASE O-07");
        $display("========================================");
        $display("Total de testes: %0d", total_testes);
        $display("Testes passaram: %0d", testes_passaram);
        $display("Testes falharam: %0d", testes_falharam);
        $display("========================================\n");
        
        #100 $finish;
    end

endmodule
