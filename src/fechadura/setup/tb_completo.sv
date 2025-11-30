`timescale 1ns/1ns

module testbench_setup_completo;
    logic clk;
    logic rst;
    logic setup_on;
    senhaPac_t digitos_value;
    logic digitos_valid;
    logic display_en_setup;
    bcdPac_t bcd_pac_setup;
    setupPac_t data_setup_new;
    logic data_setup_ok;

    bcdPac_t bcd_pac_operacional;
    logic display_en_operacional;
    logic sensor_contato;
	logic botao_interno;
	logic botao_bloqueio;
	logic botao_config;
	logic teclado_en;
	logic tranca;
    logic bip;

	logic enable_o, enable_s;
	bcdPac_t bcd_packet_operacional, bcd_packet_setup;
 	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // Variables for release 7 random generation
    senhaPac_t saved_senha_master;
    senhaPac_t saved_senha_1;
    senhaPac_t saved_senha_2;
    senhaPac_t saved_senha_3;
    senhaPac_t saved_senha_4;
    setupPac_t old_configs;

    // Test variables
    int num_teste = 1;
    int digitos_14[14] = '{1,2,3,4,5,6,7,8,9,0,1,2,3,4};
    int ultimos_12[12] = '{3,4,5,6,7,8,9,0,1,2,3,4};
    int digitos_validos[6] = '{1,2,3,4,5,6};
    logic [3:0] standard_senha_master [4] = '{1, 2, 3, 4};

    // Test statistics variables
    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    
    // Per-release statistics
    int testes_r1_total = 0, testes_r1_passou = 0, testes_r1_falhou = 0;
    int testes_r2_total = 0, testes_r2_passou = 0, testes_r2_falhou = 0;
    int testes_r3_total = 0, testes_r3_passou = 0, testes_r3_falhou = 0;
    int testes_r4_total = 0, testes_r4_passou = 0, testes_r4_falhou = 0;
    int testes_r5_total = 0, testes_r5_passou = 0, testes_r5_falhou = 0;
    int testes_r6_total = 0, testes_r6_passou = 0, testes_r6_falhou = 0;
    int testes_r7_total = 0, testes_r7_passou = 0, testes_r7_falhou = 0;
    
    int current_release = 1; // Para controlar qual release está sendo testado

    always #1 clk = ~clk;

    setup dut_setup (
        .clk(clk),
        .rst(rst),
        .setup_on(setup_on),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .display_en(display_en_setup),
        .bcd_pac(bcd_pac_setup),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok)
    );

    operacional dut_operacional (
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
        .bcd_pac(bcd_pac_operacional),
        .teclado_en(teclado_en),
        .display_en(display_en_operacional),
        .setup_on(setup_on),
        .tranca(tranca),
        .bip(bip)
    );

    display DUT (
        .clk(clk),
        .rst(rst),
        .enable_o(display_en_operacional),
        .enable_s(display_en_setup),
        .bcd_packet_operacional(bcd_pac_operacional),
        .bcd_packet_setup(bcd_pac_setup),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    // ====================================================
    // Função genérica para entrar no setup
    // ====================================================
    task automatic enter_setup();
        botao_config = 1;
        repeat(3) @(posedge clk);
        botao_config = 0;
        repeat(2) @(posedge clk);

        foreach (standard_senha_master[i]) begin
            send_digit(standard_senha_master[i]);
        end

        // Pressionar '*'
        send_digit(4'hA);
        fork
            begin
                wait(setup_on == 1'b1);
                $display("TESTE %0d: PASSOU! Entrou no setup com sucesso.", num_teste);
                num_teste++;
            end
            begin
                #1000;
                $display("TESTE %0d: FALHOU! Timeout esperando setup_on", num_teste);
                num_teste++;
            end
        join_any
        disable fork;
    endtask

    // ====================================================
    // Random generator class for release 7
    // ====================================================
    class GeradorAleatorio;
        int min, max;
        int valores[];     
        int indice = 0;    

        function new(int min, int max);
            this.min = min;
            this.max = max;
            valores = new[max - min + 1]; 
            for (int i = 0; i <= (max - min); i++)
                valores[i] = min + i;
            embaralhar();
        endfunction

        function void embaralhar();
            int tmp, j;
            for (int i = valores.size()-1; i > 0; i--) begin
                j = $urandom_range(0, i);
                tmp = valores[i];
                valores[i] = valores[j];
                valores[j] = tmp;
            end
            indice = 0;
        endfunction

        function int proximo();
            if (indice >= valores.size())
                embaralhar();
            return valores[indice++];
        endfunction
    endclass

    GeradorAleatorio gen_descarta;
    GeradorAleatorio gen_14;
    GeradorAleatorio gen_qtd;
    GeradorAleatorio gen_between_4_12;

    int qtd_nova;
    int gerados_qtd[12] = '{default: 4'hF};
    int gerados[12]     = '{default: 4'hF};

    // ====================================================
    // Common tasks
    // ====================================================
    task automatic reset();
        rst = 1;
        repeat(5000) @(posedge clk);
        rst = 0;
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

    task automatic print_teste(input bit condicao, input string msg_erro);
        total_testes++;
        if (condicao) begin
            $display("Teste %0d: PASSOU!", num_teste);
            testes_passaram++;
            // Incrementar contadores por release
            case(current_release)
                1: begin testes_r1_total++; testes_r1_passou++; end
                2: begin testes_r2_total++; testes_r2_passou++; end
                3: begin testes_r3_total++; testes_r3_passou++; end
                4: begin testes_r4_total++; testes_r4_passou++; end
                5: begin testes_r5_total++; testes_r5_passou++; end
                6: begin testes_r6_total++; testes_r6_passou++; end
                7: begin testes_r7_total++; testes_r7_passou++; end
            endcase
        end else begin
            testes_falharam++;
            // Incrementar contadores por release
            case(current_release)
                1: begin testes_r1_total++; testes_r1_falhou++; end
                2: begin testes_r2_total++; testes_r2_falhou++; end
                3: begin testes_r3_total++; testes_r3_falhou++; end
                4: begin testes_r4_total++; testes_r4_falhou++; end
                5: begin testes_r5_total++; testes_r5_falhou++; end
                6: begin testes_r6_total++; testes_r6_falhou++; end
                7: begin testes_r7_total++; testes_r7_falhou++; end
            endcase
            if (msg_erro == "")
                $display("Teste %0d: FALHOU! (sem mensagem)", num_teste);
            else
                $display("Teste %0d: FALHOU! %s", num_teste, msg_erro);
        end
    endtask

    // ====================================================
    // Funções para estatísticas
    // ====================================================
    function real calcular_porcentagem(int passou, int total);
        if (total == 0)
            return 0.0;
        else
            return (real'(passou) / real'(total)) * 100.0;
    endfunction

    task automatic exibir_estatisticas_release(input string nome_release, input int total, input int passou, input int falhou);
        real porcentagem;
        porcentagem = calcular_porcentagem(passou, total);
        $display("%s: %0d/%0d testes passaram (%.1f%%)", nome_release, passou, total, porcentagem);
    endtask

    task automatic exibir_estatisticas_finais();
        real porcentagem_total;
        
        $display("\n===============================================");
        $display("ESTATÍSTICAS FINAIS DOS TESTES");
        $display("===============================================");
        
        // Estatísticas por release
        exibir_estatisticas_release("Release 1", testes_r1_total, testes_r1_passou, testes_r1_falhou);
        exibir_estatisticas_release("Release 2", testes_r2_total, testes_r2_passou, testes_r2_falhou);
        exibir_estatisticas_release("Release 3", testes_r3_total, testes_r3_passou, testes_r3_falhou);
        exibir_estatisticas_release("Release 4", testes_r4_total, testes_r4_passou, testes_r4_falhou);
        exibir_estatisticas_release("Release 5", testes_r5_total, testes_r5_passou, testes_r5_falhou);
        exibir_estatisticas_release("Release 6", testes_r6_total, testes_r6_passou, testes_r6_falhou);
        exibir_estatisticas_release("Release 7", testes_r7_total, testes_r7_passou, testes_r7_falhou);
        
        $display("-----------------------------------------------");
        
        // Estatísticas totais
        porcentagem_total = calcular_porcentagem(testes_passaram, total_testes);
        $display("TOTAL GERAL: %0d/%0d testes passaram (%.1f%%)", testes_passaram, total_testes, porcentagem_total);
        $display("Testes que falharam: %0d (%.1f%%)", testes_falharam, 100.0 - porcentagem_total);
        
        // Resumo final
        if (porcentagem_total >= 90.0)
            $display("🟢 RESULTADO: EXCELENTE!");
        else if (porcentagem_total >= 75.0)
            $display("🟡 RESULTADO: BOM");
        else if (porcentagem_total >= 50.0)
            $display("🟠 RESULTADO: REGULAR");
        else
            $display("🔴 RESULTADO: PRECISA MELHORAR");
            
        $display("===============================================\n");
    endtask

    // ====================================================
    // Release 1 tasks and tests
    // ====================================================
    task automatic execute_tests_release_1();
        $display("\n=== EXECUTANDO TESTES RELEASE 1 ===");
        current_release = 1;
        reset();
        num_teste = 1;
        // Porta destravada e aberta
        botao_interno = 0;
        repeat(3) @(posedge clk);
        sensor_contato = 1;

        // Passo 1 -> Pressionar botão CONFIG
        botao_config = 1;
        repeat(3) @(posedge clk);
        botao_config = 0;

        print_teste(bcd_pac_setup.BCD5 == 0, "BCD5 = 1");
        num_teste++;

        // Passo 2 -> Enviar senha incorreta + '*'
        for (int i = 0; i < 4; i++) begin
            send_digit(4'h1);
        end

        // Pressionar '*'
        send_digit(4'hA);

        print_teste(setup_on == 0 && HEX5 == 0, "SETUP = 1 e/ou HEX5 = 1");
        num_teste++;

        // Passo 3 -> Enviar senha master correta + '*'
        foreach (standard_senha_master[i]) begin
            send_digit(standard_senha_master[i]);
        end

        // Pressionar '*'
        send_digit(4'hA);

        print_teste(bcd_pac_setup.BCD5 == 1 && setup_on == 1, "BCD5 = 0 e/ou SETUP = 0");
        num_teste++;

        // Passo 4 -> Enviar tecla "#" antes de confirmar
        send_digit(4'hB);

        print_teste(setup_on == 0, "SETUP = 1");
        
        $display("=== RELEASE 1 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 2 tasks and tests
    // ====================================================

    task automatic execute_tests_release_2();
        $display("\n=== EXECUTANDO TESTES RELEASE 2 ===");
        current_release = 2;
        // Reset
        reset();
        num_teste = 1;

        // Guardando as configurações inicial do setup
        old_configs = data_setup_new;

        // 1. Entrar no setup (setup_on = 1)
        enter_setup();

        print_teste(bcd_pac_setup.BCD5 == 1, "BCD5 diferente de 1 após entrada no setup");
        num_teste++;

        // 2. Navegar através das opções 1-8 usando '*'
        for (int i = 2; i <= 8; i++) begin
            send_digit(4'hA);  // Avançar para próxima opção
            @(posedge clk);
            
            print_teste(bcd_pac_setup.BCD5 == i, $sformatf("BCD5 diferente de %0d na navegação", i));
            num_teste++;
        end

        // 3. Após opção 8, pressionar '*' novamente deve voltar ao operacional
        send_digit(4'hA);
        @(posedge clk);

        // Verificar se voltou para o modo operacional
        print_teste(display_en_setup == 0, "Não retornou ao modo operacional após opção 8");
        num_teste++;

        // Verificar se nenhum valor do setup foi alterado
        print_teste(old_configs == data_setup_new, "Algum valor foi alterado durante navegação");

        $display("=== RELEASE 2 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 3 tasks and tests
    // ====================================================

    task automatic execute_tests_release_3();
        $display("\n=== EXECUTANDO TESTES RELEASE 3 ===");
        current_release = 3;
        // Reset
        reset();
        num_teste = 1;

        // Testar saída do setup em cada uma das 8 opções
        for (int i = 1; i <= 8; i++) begin
            old_configs = data_setup_new;

            enter_setup();

            @(posedge clk);

            // Navegar até a opção i
            for (int j = 1; j < i; j++) begin
                send_digit(4'hA);
                @(posedge clk);
            end

            // Pressionar '#' para sair
            send_digit(4'hB);
            @(posedge clk);

            print_teste(display_en_setup == 0, $sformatf("Não saiu do setup na opção %0d", i));
            num_teste++;

            print_teste(data_setup_ok == 1, $sformatf("data_setup_ok não foi ativado na opção %0d", i));
            num_teste++;

            print_teste(setup_on == 0, $sformatf("setup_on não foi desativado na opção %0d", i));
            num_teste++;

            print_teste(old_configs == data_setup_new, $sformatf("Valores alterados ao sair da opção %0d", i));
            num_teste++;
        end

        $display("=== RELEASE 3 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 4 tasks and tests
    // ====================================================
    task automatic enter_setup_r4();
        enter_setup();
        @(posedge clk);
    endtask

    task automatic verifificar_valor_salvo();
        print_teste(bcd_pac_setup.BCD5 == 4'd1 && bcd_pac_setup.BCD0 == data_setup_new.bip_status, 
                   $sformatf("Valor não salvo corretamente - BCD5: %0d, BCD0: %0d, bip_status: %0d", 
                           bcd_pac_setup.BCD5, bcd_pac_setup.BCD0, data_setup_new.bip_status));
    endtask

    task automatic validar_entrada(input logic [3:0] digit);
        send_digit(digit);
        @(posedge clk);
        print_teste(bcd_pac_setup.BCD5 == 4'd1 && bcd_pac_setup.BCD0 == ((digit < 2)? digit : data_setup_new.bip_status),
                   $sformatf("Entrada inválida para dígito %0d - BCD5: %0d, BCD0: %0d", 
                           digit, bcd_pac_setup.BCD5, bcd_pac_setup.BCD0));
    endtask

    function automatic bit compare_configs_r4(setupPac_t a, setupPac_t b);
    return
        (a.bip_time === b.bip_time) &&
        (a.tranca_aut_time === b.tranca_aut_time) &&
        (a.senha_master.digits === b.senha_master.digits) &&
        (a.senha_1.digits === b.senha_1.digits) &&
        (a.senha_2.digits === b.senha_2.digits) &&
        (a.senha_3.digits === b.senha_3.digits) &&
        (a.senha_4.digits === b.senha_4.digits);
    endfunction

    task automatic execute_tests_release_4();
        $display("\n=== EXECUTANDO TESTES RELEASE 4 ===");
        current_release = 4;
        reset();
        num_teste = 1;
        old_configs = data_setup_new;
        
        enter_setup_r4();
        print_teste(bcd_pac_setup.BCD5 == 1, "Não entrou no setup (opção 1)");
        num_teste++;
                
        verifificar_valor_salvo();
        num_teste++;

        validar_entrada(4'b0001);
        num_teste++;
        
        validar_entrada(4'b0000);
        num_teste++;

        for (int i = 2; i < 10; i++) begin
            validar_entrada(i);
            num_teste++;
        end

        send_digit(4'hA);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                print_teste(1'b1, $sformatf("Teste %0d: PASSOU! Retorno ao operacional com sucesso.", num_teste));
                num_teste++;
            end
            begin
                #1000;
                print_teste(1'b0, $sformatf("Teste %0d: FALHOU! Timeout esperando data_setup_ok", num_teste));
                num_teste++;
            end
        join_any
        disable fork;
        num_teste++;

        print_teste(data_setup_new.bip_status === 4'b0000 && compare_configs_r4(data_setup_new, old_configs), 
                    "Configuração não salva corretamente");

        $display("=== RELEASE 4 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 5 tasks and tests - TEMPO DE BIP (Opção 2)
    // ====================================================
    task automatic enter_setup_r5_opcao2();
        enter_setup();
        @(posedge clk);
        // Navegar até opção 2 (tempo de BIP)
        send_digit(4'hA);  // Ir para opção 2
        @(posedge clk);
    endtask

    task automatic verificar_deslocamento_r5(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        print_teste(bcd_pac_setup.BCD1 == expected_BCD1 && bcd_pac_setup.BCD0 == expected_BCD0,
                   $sformatf("Deslocamento incorreto - Esperado BCD1=%0d, BCD0=%0d | Atual BCD1=%0d, BCD0=%0d", 
                           expected_BCD1, expected_BCD0, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0));
    endtask

    task automatic verificar_bcd_r5_opcao2(logic [3:0] expected_BCD5);
        print_teste(bcd_pac_setup.BCD5 == expected_BCD5,
                   $sformatf("Alternância de configuração incorreta - Esperado BCD5=%0d | Atual BCD5=%0d", 
                           expected_BCD5, bcd_pac_setup.BCD5));
    endtask

    function automatic bit compare_configs_r5(setupPac_t a, setupPac_t b);
    return
        (a.bip_status === b.bip_status) &&
        (a.tranca_aut_time === b.tranca_aut_time) &&
        (a.senha_master.digits === b.senha_master.digits) &&
        (a.senha_1.digits === b.senha_1.digits) &&
        (a.senha_2.digits === b.senha_2.digits) &&
        (a.senha_3.digits === b.senha_3.digits) &&
        (a.senha_4.digits === b.senha_4.digits);
    endfunction

    task automatic return_to_operational_r5(logic [5:0] expected_bip_time);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                print_teste(1'b1, $sformatf("Teste %0d: PASSOU! Retorno ao operacional com sucesso.", num_teste));
                num_teste++;
            end
            begin
                #1000;
                print_teste(1'b0, $sformatf("Teste %0d: FALHOU! Timeout esperando data_setup_ok", num_teste));
                num_teste++;
            end
        join_any
        disable fork;

        print_teste(data_setup_new.bip_time === expected_bip_time && compare_configs_r5(data_setup_new, old_configs),
                    $sformatf("Configuração não salva - Esperado bip_time=%0d | Atual=%0d", 
                                      expected_bip_time, data_setup_new.bip_time));
    endtask

    task automatic test_current_option_r5(logic [4:0] expected);
        print_teste(bcd_pac_setup.BCD5 == expected,
                   $sformatf("Opção incorreta após nova entrada - Esperado BCD5=%0d | Atual=%0d", 
                           expected, bcd_pac_setup.BCD5));
    endtask

    task automatic test_limits_r5(logic [6:0] input_value, logic [5:0] expected_value);
        send_digit(4'hA);
        @(posedge clk);

        print_teste(data_setup_new.bip_time === expected_value,
                   $sformatf("Limite não testado corretamente - Entrada=%0d | Esperado=%0d | Atual=%0d", 
                           input_value, expected_value, data_setup_new.bip_time));
    endtask

    task automatic execute_tests_release_5();
        $display("\n=== EXECUTANDO TESTES RELEASE 5 ===");
        current_release = 5;
        reset();
        num_teste = 1;
        old_configs = data_setup_new;
        
        // Teste 1: Entrar na opção 2 e testar digitação "1,2,3" → valor "23"
        enter_setup_r5_opcao2();

        // Verificar se está na opção 2
        print_teste(bcd_pac_setup.BCD5 == 2, "Não está na opção 2 (tempo de BIP)");
        num_teste++;

        // Digitar "1,2,3" → deve resultar em "23" nos últimos 2 dígitos
        send_digit(4'd1);
        send_digit(4'd2);
        send_digit(4'd3);
        verificar_deslocamento_r5(4'd2, 4'd3);  // BCD1=2, BCD0=3 → valor "23"
        num_teste++;

        // Pressionar "*" para confirmar
        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd3);  // Deve ir para opção 3
        num_teste++;

        // Sair do setup
        return_to_operational_r5(6'd23);
        num_teste += 2;

        // Teste 2: Testar saturação mínima (03 → 05)
        enter_setup_r5_opcao2();
        
        send_digit(4'd0);
        send_digit(4'd3);
        send_digit(4'hA);
        test_limits_r5(7'd3, 6'd5);  // 03 deve ser saturado para 05
        num_teste++;

        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd5);  // Deve ir para opção 5
        num_teste++;

        return_to_operational_r5(6'd5);
        num_teste += 2;

        // Teste 3: Testar saturação máxima (97 → 60)
        enter_setup_r5_opcao2();
        
        send_digit(4'd9);
        send_digit(4'd7);
        send_digit(4'hA);
        test_limits_r5(7'd97, 6'd60);  // 97 deve ser saturado para 60
        num_teste++;

        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd5);  // Deve ir para opção 5
        num_teste++;

        return_to_operational_r5(6'd60);

        $display("=== RELEASE 5 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 6 tasks and tests - TEMPO DE FECHAMENTO (Opção 3)  
    // ====================================================
    task automatic enter_setup_r6_opcao3();
        enter_setup();
        @(posedge clk);
        // Navegar até opção 3 (tempo de fechamento automático)
        send_digit(4'hA);  // Ir para opção 2
        @(posedge clk);
        send_digit(4'hA);  // Ir para opção 3
        @(posedge clk);
    endtask

    task automatic verificar_deslocamento_r6(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        print_teste(bcd_pac_setup.BCD1 == expected_BCD1 && bcd_pac_setup.BCD0 == expected_BCD0,
                   $sformatf("Deslocamento incorreto - Esperado BCD1=%0d, BCD0=%0d | Atual BCD1=%0d, BCD0=%0d", 
                           expected_BCD1, expected_BCD0, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0));
    endtask

    task automatic verificar_bcd_r6(logic [4:0] expected_BCD5);
        print_teste(bcd_pac_setup.BCD5 == expected_BCD5,
                   $sformatf("Alternância de configuração incorreta - Esperado BCD5=%0d | Atual BCD5=%0d", 
                           expected_BCD5, bcd_pac_setup.BCD5));
    endtask

    function automatic bit compare_configs_r6(setupPac_t a, setupPac_t b);
    return
        (a.bip_status === b.bip_status) &&
        (a.bip_time === b.bip_time) &&
        (a.senha_master.digits === b.senha_master.digits) &&
        (a.senha_1.digits === b.senha_1.digits) &&
        (a.senha_2.digits === b.senha_2.digits) &&
        (a.senha_3.digits === b.senha_3.digits) &&
        (a.senha_4.digits === b.senha_4.digits);
    endfunction

    task automatic return_to_operational_r6(logic [5:0] expected_tranca_aut_time);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                print_teste(1'b1, $sformatf("Teste %0d: PASSOU! Retorno ao operacional com sucesso.", num_teste));
                num_teste++;
            end
            begin
                #1000;
                print_teste(1'b0, $sformatf("Teste %0d: FALHOU! Timeout esperando data_setup_ok", num_teste));
                num_teste++;
            end
        join_any
        disable fork;

        print_teste(data_setup_new.tranca_aut_time === expected_tranca_aut_time && compare_configs_r6(data_setup_new, old_configs),
                    $sformatf("Configuração não salva - Esperado tranca_aut_time=%0d | Atual=%0d", 
                                      expected_tranca_aut_time, data_setup_new.tranca_aut_time));
    endtask

    task automatic test_limits_r6(logic [4:0] input_value, logic [4:0] expected_value);
        send_digit(input_value[3:0]);
        send_digit({1'b0, input_value[4]});
        send_digit(4'hA);
        @(posedge clk);

        print_teste(data_setup_new.tranca_aut_time === expected_value,
                   $sformatf("Limite não testado corretamente - Entrada=%0d | Esperado=%0d | Atual=%0d", 
                           input_value, expected_value, data_setup_new.tranca_aut_time));
    endtask

    task automatic execute_tests_release_6();
        $display("\n=== EXECUTANDO TESTES RELEASE 6 ===");
        current_release = 6;
        reset();
        num_teste = 1;
        
        old_configs = data_setup_new;

        // Teste 1: Entrar na opção 3 e testar digitação "1,2,3" → valor "23"
        enter_setup_r6_opcao3();

        // Verificar se está na opção 3
        print_teste(bcd_pac_setup.BCD5 == 3, "Não está na opção 3 (tempo de fechamento automático)");
        num_teste++;

        // Digitar "1,2,3" → deve resultar em "23" nos últimos 2 dígitos
        send_digit(4'd1);
        send_digit(4'd2);
        send_digit(4'd3);
        verificar_deslocamento_r6(4'd2, 4'd3);  // BCD1=2, BCD0=3 → valor "23"
        num_teste++;

        // Pressionar "*" para confirmar
        send_digit(4'hA);
        verificar_bcd_r6(4'd4);  // Deve ir para opção 4
        num_teste++;

        // Sair do setup
        return_to_operational_r6(6'd23);
        num_teste += 2;

        // Teste 2: Testar saturação mínima (03 → 05)
        enter_setup_r6_opcao3();
        
        send_digit(4'd0);
        send_digit(4'd3);
        send_digit(4'hA);
        test_limits_r6(6'd3, 6'd5);  // 03 deve ser saturado para 05
        num_teste++;

        send_digit(4'hA);
        verificar_bcd_r6(4'd5);  // Deve ir para opção 5
        num_teste++;

        return_to_operational_r6(6'd5);
        num_teste += 2;

        // Teste 3: Testar saturação máxima (97 → 60) 
        enter_setup_r6_opcao3();
        
        send_digit(4'd9);
        send_digit(4'd7);
        send_digit(4'hA);
        test_limits_r6(7'd97, 7'd60);  // 97 deve ser saturado para 60
        num_teste++;

        send_digit(4'hA);
        verificar_bcd_r6(4'd5);  // Deve ir para opção 5
        num_teste++;

        return_to_operational_r6(6'd60);

        $display("=== RELEASE 6 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 7 tasks and tests
    // ====================================================
    task automatic enter_setup_r7(int steps);

        enter_setup();
        @(posedge clk);
        // Navegar até a opção desejada
        repeat(steps) begin
            send_digit(4'hA);
            @(posedge clk);
        end
    endtask

    function automatic bit compare_configs_r7(
        setupPac_t a,
        senhaPac_t expected_senha_1,
        senhaPac_t expected_senha_2,
        senhaPac_t expected_senha_3,
        senhaPac_t expected_senha_4,
        senhaPac_t expected_senha_master
    );
        return
            (a.senha_master.digits === expected_senha_master.digits) &&
            (a.senha_1.digits    === expected_senha_1.digits) &&
            (a.senha_2.digits    === expected_senha_2.digits) &&
            (a.senha_3.digits    === expected_senha_3.digits) &&
            (a.senha_4.digits    === expected_senha_4.digits);
    endfunction

    task automatic return_to_operational_r7(
        senhaPac_t expected_senha_1,
        senhaPac_t expected_senha_2,
        senhaPac_t expected_senha_3,
        senhaPac_t expected_senha_4,
        senhaPac_t expected_senha_master
    );
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                $display("[%0t] PASSOU! retornou ao operacional com sucesso.", $time);
            end
            begin
                #1000;
                $display("[%0t] FALHOU! nao retornou ao operacional em tempo.", $time);
            end
        join_any
        disable fork;

        if (compare_configs_r7(data_setup_new, expected_senha_1, expected_senha_2, expected_senha_3, expected_senha_4, expected_senha_master)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end
    endtask

    task automatic verificar_descarte_r7(senhaPac_t senha, senhaPac_t senha_old);
        print_teste(senha.digits === senha_old.digits,
                   "Senha foi alterada após entrada incompleta (deveria ser descartada)");
    endtask

    task automatic validar_senha_r7(senhaPac_t senha, int gerados_in[]);
        print_teste(senha.digits === {gerados_in[0], gerados_in[1], gerados_in[2], gerados_in[3],
                              gerados_in[4], gerados_in[5]},
                   "Senha não foi alterada corretamente");
    endtask

    function automatic senhaPac_t get_senha_by_index(setupPac_t cfg, int idx);
        case (idx)
            0: return cfg.senha_master;
            1: return cfg.senha_1;
            2: return cfg.senha_2;
            3: return cfg.senha_3;
            4: return cfg.senha_4;
            default: return '0;
        endcase
    endfunction

    task automatic execute_tests_release_7();

        $display("\n=== EXECUTANDO TESTES RELEASE 7 ===");
        current_release = 7;
        reset();
        num_teste = 1;
        num_teste = 1;
        
        old_configs = data_setup_new;

        for (int i = 0; i < 5; i++) begin
            senhaPac_t senha_old = get_senha_by_index(data_setup_new, i);
            
            // Teste 1: Entrada com < 4 dígitos → senha descartada
            enter_setup_r7(i + 5);

            // Enviar apenas 3 dígitos + "*"
            send_digit(4'h1);
            send_digit(4'h2);
            send_digit(4'h3);
            send_digit(4'hA); // Confirmar com apenas 3 dígitos
            
            // Verificar se senha foi descartada (não deve ter mudado)
            verificar_descarte_r7(get_senha_by_index(data_setup_new, i), senha_old);
            num_teste++;

            // Teste 2: Entrada com > 12 dígitos → últimos 12 armazenados
            enter_setup_r7(i + 5);

            // Enviar 14 dígitos: 1,2,3,4,5,6,7,8,9,0,1,2,3,4
            for (int j = 0; j < 14; j++) begin
                send_digit(digitos_14[j]);
            end
            send_digit(4'hA); // Confirmar            
            
            // Verificar se os últimos 12 foram armazenados (adaptar validação para 12 dígitos)
            print_teste(get_senha_by_index(data_setup_new, i).digits[19:0] == {ultimos_12[0], ultimos_12[1], ultimos_12[2], 
                                                                        ultimos_12[3], ultimos_12[4], ultimos_12[5]}, 
                        "Últimos 12 dígitos não armazenados corretamente");
            num_teste++;

            // Teste 3: Entrada entre 4 e 12 dígitos → senha armazenada
            enter_setup_r7(i + 5);

            // Enviar 6 dígitos válidos
            for (int j = 0; j < 6; j++) begin
                send_digit(digitos_validos[j]);
            end
            send_digit(4'hA); // Confirmar
            
            // Validar se a senha foi alterada corretamente
            validar_senha_r7(get_senha_by_index(data_setup_new, i), digitos_validos);
            num_teste++;

            // Salvar a senha para verificação posterior
            case (i)
                0: saved_senha_master = data_setup_new.senha_master;
                1: saved_senha_1 = data_setup_new.senha_1;
                2: saved_senha_2 = data_setup_new.senha_2;
                3: saved_senha_3 = data_setup_new.senha_3;
                4: saved_senha_4 = data_setup_new.senha_4;
            endcase
        end

        // Sair do setup e verificar se todas as configurações foram salvas
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                print_teste(1'b1, $sformatf("Teste %0d: PASSOU! Retorno ao operacional com sucesso.", num_teste));
                num_teste++;
            end
            begin
                #1000;
                print_teste(1'b0, $sformatf("Teste %0d: FALHOU! Timeout esperando data_setup_ok", num_teste));
                num_teste++;
            end
        join_any
        disable fork;

        print_teste(compare_configs_r7(data_setup_new, saved_senha_1, saved_senha_2, saved_senha_3, saved_senha_4, saved_senha_master),
                    "Alguma senha não foi salva corretamente");

        $display("=== RELEASE 7 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Main test execution
    // ====================================================
    initial begin
        clk = 0;
        rst = 0;
        digitos_value.digits = '1;
        digitos_valid = 0;
        sensor_contato = 0;
        botao_interno = 0;
        botao_bloqueio = 0;
        botao_config = 0;
        
        $display("\n===============================================");
        $display("INICIANDO TESTBENCH COMPLETO - TODAS AS RELEASES");
        $display("===============================================\n");

        // Execute all releases sequentially
        execute_tests_release_1();
        execute_tests_release_2();
        execute_tests_release_3();
        execute_tests_release_4();
        execute_tests_release_5();
        execute_tests_release_6();
        execute_tests_release_7();

        // Exibir estatísticas finais
        exibir_estatisticas_finais();

        $display("\n===============================================");
        $display("TESTBENCH COMPLETO FINALIZADO");
        $display("===============================================\n");

        #100 $finish;
    end

endmodule