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

    task send_digit(input logic [3:0] digit);
        // Shift Register
        digitos_value.digits = {digitos_value.digits[18:0], digit};
        
        // Pulso de Validação
        digitos_valid = 1'b1;
        @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);

        // Limpa o buffer após '*' ou '#'
        if (digit == 4'hA || digit == 4'hB) begin
             digitos_value = '1; // Preenche tudo com 1s (equivale a 0xF repetido)
        end
    endtask

    task automatic execute_testes_release6;
        logic teclado_antes, teclado_depois;
        
        num_teste = 1;
        
        // Teste 1: Verificar estado inicial do teclado (deve estar habilitado)
        aguarda_ciclos(5);
        print_teste(teclado_en == 1'b1, "Teclado deveria estar habilitado inicialmente (teclado_en=1)");
        num_teste++;
        
        // Teste 2: Garantir que a porta está fechada (sensor_contato=1)
        sensor_contato = 1'b1; // Porta fechada
        aguarda_ciclos(2);
        print_teste(sensor_contato == 1'b1, "Porta deve estar fechada (sensor_contato=1) para ativar bloqueio");
        num_teste++;
        
        // Teste 3: Pressionar botão de bloqueio por menos de 3s (não deve ativar)
        botao_bloqueio = 1'b1;
        aguarda_segundos(2); // Apenas 2 segundos
        botao_bloqueio = 1'b0;
        aguarda_ciclos(10);
        print_teste(teclado_en == 1'b1, "Teclado não deveria desabilitar com menos de 3s de pressão");
        num_teste++;
        
        // Teste 4: Pressionar botão de bloqueio por exatos 3s
        aguarda_ciclos(5);
        teclado_antes = teclado_en;
        botao_bloqueio = 1'b1;
        aguarda_segundos(3); // Exatos 3 segundos
        aguarda_ciclos(5); // Ciclos extras para processar
        teclado_depois = teclado_en;
        print_teste(teclado_depois == 1'b0, "Teclado deveria estar desabilitado (teclado_en=0) após 3s");
        num_teste++;
        
        // Teste 5: Soltar botão de bloqueio - modo deve continuar ativo
        botao_bloqueio = 1'b0;
        aguarda_ciclos(10);
        print_teste(teclado_en == 1'b0, "Teclado deve permanecer desabilitado após soltar botão de bloqueio");
        num_teste++;
        
        // Teste 6: Tentar usar teclado durante bloqueio (deve ser ignorado)
        send_digit(4'd1);
        aguarda_ciclos(5);
        send_digit(4'd2);
        aguarda_ciclos(5);
        send_digit(4'd3);
        aguarda_ciclos(5);
        send_digit(4'hA);
        aguarda_ciclos(10);
        
        print_teste(teclado_en == 1'b0, "Teclado deve permanecer desabilitado mesmo após tentativas de uso");
        num_teste++;
        
        // Teste 7: Verificar que tranca permanece travada com teclado bloqueado
        print_teste(tranca == 1'b1, "Tranca deveria estar travada durante modo Não Perturbe");
        num_teste++;
        
        // Teste 8: Desativar bloqueio com botão interno
        botao_interno = 1'b1;
        aguarda_ciclos(2);
        print_teste(tranca == 1'b0, "Botão interno deve destravar a porta mesmo em modo Não Perturbe");
        num_teste++;
        
    endtask

    initial begin
        reset();
        execute_testes_release6();
        
        $display("\n========================================");
        $display("RESUMO DOS TESTES - RELEASE O-06");
        $display("========================================");
        $display("Total de testes: %0d", total_testes);
        $display("Testes passaram: %0d", testes_passaram);
        $display("Testes falharam: %0d", testes_falharam);
        $display("========================================\n");
        
        #100 $finish;
    end

endmodule
