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

        task embaralhar();
            int tmp, j;
            for (int i = valores.size()-1; i > 0; i--) begin
                j = $urandom_range(0, i);
                tmp = valores[i];
                valores[i] = valores[j];
                valores[j] = tmp;
            end
            indice = 0;
        endtask

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

    task automatic print_teste(input bit condicao, input int num_teste, input string msg_erro);
        if (condicao)
            $display("Teste %0i: PASSOU!", num_teste);
        else
            $display("Teste %0i: FALHOU! %s", num_teste, msg_erro);
    endtask

    // ====================================================
    // Release 1 tasks and tests
    // ====================================================
    task automatic execute_tests_release_1();
        $display("\n=== EXECUTANDO TESTES RELEASE 1 ===");
        reset();

        // Porta destravada e aberta
        botao_interno = 0;
        repeat(3) @(posedge clk);
        sensor_contato = 1;

        int num_teste = 1;

        // Passo 1 -> Pressionar botão CONFIG
        botao_config = 1;
        repeat(3) @(posedge clk);
        botao_config = 0;

        print_teste(bcd_pac_setup.BCD5 == 0, num_teste, "BCD5 = 1");

        // Passo 2 -> Enviar senha incorreta + '*'
        for (int i = 0; i < 4; i++) begin
            send_digit(4'h1);
        end

        // Pressionar '*'
        send_digit(4'hA);

        num_teste = num_teste + 1;

        print_teste(setup_on == 0 && HEX5 == 0, num_teste, "SETUP = 1 e/ou HEX5 = 1");

        // Passo 3 -> Enviar senha master correta + '*'
        logic [3:0] sen_master [4] = '{1, 2, 3, 4};
        
        foreach (sen_master[i]) begin
            send_digit(sen_master[i]);
        end

        // Pressionar '*'
        send_digit(4'hA);

        num_teste = num_teste + 1;

        print_teste(bcd_pac_setup.BCD5 == 1 && setup_on == 1, num_teste, "BDC5 = 0 e/ou SETUP = 0");

        // Passo 4 -> Enviar tecla "#" antes de confirmar
        send_digit(4'hB);

        num_teste = num_teste + 1;

        print_teste(setup_on == 0, num_teste, "SETUP = 1");
        
        $display("=== RELEASE 1 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 2 tasks and tests
    // ====================================================
    task automatic enter_setup_r2();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
    endtask

    task automatic execute_tests_release_2();
        $display("\n=== EXECUTANDO TESTES RELEASE 2 ===");
        // Reset
        reset();

        // Guardando as configurações inicial do setup
        old_configs = data_setup_new;

        // 1. Entrar no setup (setup_on = 1)
        enter_setup_r2();

        int num_teste = 1;

        print_teste(bcd_pac_setup.BCD5 == 1, num_teste, "BCD5 diferente de 1 após entrada no setup");

        // 2. Navegar através das opções 1-8 usando '*'
        for (int i = 2; i <= 8; i++) begin
            send_digit(4'hA);  // Avançar para próxima opção
            @(posedge clk);
            
            num_teste = num_teste + 1;
            print_teste(bcd_pac_setup.BCD5 == i, num_teste, $sformatf("BCD5 diferente de %0d na navegação", i));
        end

        // 3. Após opção 8, pressionar '*' novamente deve voltar ao operacional
        send_digit(4'hA);
        @(posedge clk);

        num_teste = num_teste + 1;
        // Verificar se voltou para o modo operacional
        print_teste(display_en_setup == 0, num_teste, "Não retornou ao modo operacional após opção 8");

        num_teste = num_teste + 1;
        // Verificar se nenhum valor do setup foi alterado
        print_teste(old_configs == data_setup_new, num_teste, "Algum valor foi alterado durante navegação");

        $display("=== RELEASE 2 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 3 tasks and tests
    // ====================================================
    task automatic enter_setup_r3();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
    endtask

    task automatic execute_tests_release_3();
        $display("\n=== EXECUTANDO TESTES RELEASE 3 ===");
        // Reset
        reset();

        int num_teste = 1;

        // Testar saída do setup em cada uma das 8 opções
        for (int i = 1; i <= 8; i++) begin
            old_configs = data_setup_new;

            enter_setup_r3();

            @(posedge clk);

            // Navegar até a opção i
            for (int j = 1; j < i; j++) begin
                send_digit(4'hA);
                @(posedge clk);
            end

            // Pressionar '#' para sair
            send_digit(4'hB);
            @(posedge clk);

            print_teste(display_en_setup == 0, num_teste, $sformatf("Não saiu do setup na opção %0d", i));
            num_teste = num_teste + 1;

            print_teste(data_setup_ok == 1, num_teste, $sformatf("data_setup_ok não foi ativado na opção %0d", i));
            num_teste = num_teste + 1;

            print_teste(setup_on == 0, num_teste, $sformatf("setup_on não foi desativado na opção %0d", i));
            num_teste = num_teste + 1;

            print_teste(old_configs == data_setup_new, num_teste, $sformatf("Valores alterados ao sair da opção %0d", i));
            num_teste = num_teste + 1;
        end

        $display("=== RELEASE 3 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 4 tasks and tests
    // ====================================================
    task automatic enter_setup_r4();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        if(bcd_pac_setup.BCD5 == 1) begin
            $display("[%0t] PASSOU! entrou no setup(opção 1) com sucesso.", $time);
        end else begin
            $display("[%0t] FALHOU! nao entrou no setup(opção 1).", $time);
        end
    endtask

    task automatic verifificar_valor_salvo();
        if(bcd_pac_setup.BCD5 == 4'd1 && bcd_pac_setup.BCD0 == data_setup_new.bip_status) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD5, bcd_pac_setup.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD5, bcd_pac_setup.BCD0);
        end
    endtask

    task automatic validar_entrada(input logic [3:0] digit);
        send_digit(digit);
        @(posedge clk);
        if(bcd_pac_setup.BCD5 == 4'd1 && bcd_pac_setup.BCD0 == ((digit < 2)? digit : data_setup_new.bip_status)) begin
            $display("[%0t] PASSOU! Numero pressionado: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, digit, digitos_valid, bcd_pac_setup.BCD5, bcd_pac_setup.BCD0);
        end else begin
            $display("[%0t] FALHOU! Numero pressionado: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, digit, digitos_valid, bcd_pac_setup.BCD5, bcd_pac_setup.BCD0);
        end
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
        reset();
        
        old_configs = data_setup_new;
        enter_setup_r4();
        
        verifificar_valor_salvo();

        validar_entrada(4'b0001);
        validar_entrada(4'b0000);

        for (int i = 2; i < 10; i++) begin
            validar_entrada(i);
        end

        send_digit(4'hA);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                $display("[%0t] PASSOU! data_setup_ok ativado com sucesso.", $time);
            end
            begin
                #1000;
                $display("[%0t] FALHOU! nao ativou data_setup_ok em tempo.", $time);
            end
        join_any
        disable fork;

        if(data_setup_new.bip_status === 4'b0000 && compare_configs_r4(data_setup_new, old_configs)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end

        $display("=== RELEASE 4 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 5 tasks and tests - TEMPO DE BIP (Opção 2)
    // ====================================================
    task automatic enter_setup_r5_opcao2();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        // Navegar até opção 2 (tempo de BIP)
        send_digit(4'hA);  // Ir para opção 2
        @(posedge clk);
    endtask

    task automatic verificar_deslocamento_r5(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        if(bcd_pac_setup.BCD1 == expected_BCD1 && bcd_pac_setup.BCD0 == expected_BCD0) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end
    endtask

    task automatic verificar_bcd_r5_opcao2(logic [4:0] expected_BCD5);
        if(bcd_pac_setup.BCD5 == expected_BCD5) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end
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

    task automatic return_to_operational_r5(logic [4:0] expected_bip_time);
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

        if(data_setup_new.bip_time === expected_bip_time && compare_configs_r5(data_setup_new, old_configs)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end
    endtask

    task automatic test_current_option_r5(logic [4:0] expected);
        if(bcd_pac_setup.BCD5 == expected) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente apos nova entrada. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente apos nova entrada. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end
    endtask

    task automatic test_limits_r5(logic [4:0] input_value, logic [4:0] expected_value);
        send_digit(input_value[3:0]);
        send_digit({1'b0, input_value[4]});
        send_digit(4'hA);
        @(posedge clk);

        if(data_setup_new.bip_time === expected_value) begin
            $display("[%0t] PASSOU! Limite testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end else begin
            $display("[%0t] FALHOU! Limite nao testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end
    endtask

    task automatic execute_tests_release_5();
        $display("\n=== EXECUTANDO TESTES RELEASE 5 ===");
        reset();
        
        old_configs = data_setup_new;
        
        // Teste 1: Entrar na opção 2 e testar digitação "1,2,3" → valor "23"
        enter_setup_r5_opcao2();

        // Verificar se está na opção 2
        print_teste(bcd_pac_setup.BCD5 == 2, 1, "Não está na opção 2 (tempo de BIP)");

        // Digitar "1,2,3" → deve resultar em "23" nos últimos 2 dígitos
        send_digit(4'd1);
        send_digit(4'd2);
        send_digit(4'd3);
        verificar_deslocamento_r5(4'd2, 4'd3);  // BCD1=2, BCD0=3 → valor "23"

        // Pressionar "*" para confirmar
        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd3);  // Deve ir para opção 3

        // Sair do setup
        return_to_operational_r5(5'd23);

        // Teste 2: Testar saturação mínima (03 → 05)
        enter_setup_r5_opcao2();
        
        send_digit(4'd0);
        send_digit(4'd3);
        send_digit(4'hA);
        test_limits_r5(5'd3, 5'd5);  // 03 deve ser saturado para 05

        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd5);  // Deve ir para opção 5

        return_to_operational_r5(5'd5);

        // Teste 3: Testar saturação máxima (97 → 60)
        enter_setup_r5_opcao2();
        
        send_digit(4'd9);
        send_digit(4'd7);
        send_digit(4'hA);
        test_limits_r5(5'd97, 5'd60);  // 97 deve ser saturado para 60

        send_digit(4'hA);
        verificar_bcd_r5_opcao2(4'd5);  // Deve ir para opção 5

        return_to_operational_r5(5'd60);

        $display("=== RELEASE 5 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 6 tasks and tests - TEMPO DE FECHAMENTO (Opção 3)  
    // ====================================================
    task automatic enter_setup_r6_opcao3();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        // Navegar até opção 3 (tempo de fechamento automático)
        send_digit(4'hA);  // Ir para opção 2
        @(posedge clk);
        send_digit(4'hA);  // Ir para opção 3
        @(posedge clk);
    endtask

    task automatic verificar_deslocamento_r6(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        if(bcd_pac_setup.BCD1 == expected_BCD1 && bcd_pac_setup.BCD0 == expected_BCD0) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end
    endtask

    task automatic verificar_bcd_r6(logic [4:0] expected_BCD5);
        if(bcd_pac_setup.BCD5 == expected_BCD5) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end
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

    task automatic return_to_operational_r6(logic [4:0] expected_tranca_aut_time);
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

        if(data_setup_new.tranca_aut_time === expected_tranca_aut_time && compare_configs_r6(data_setup_new, old_configs)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end
    endtask

    task automatic test_limits_r6(logic [4:0] input_value, logic [4:0] expected_value);
        send_digit(input_value[3:0]);
        send_digit({1'b0, input_value[4]});
        send_digit(4'hA);
        @(posedge clk);

        if(data_setup_new.tranca_aut_time === expected_value) begin
            $display("[%0t] PASSOU! Limite testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end else begin
            $display("[%0t] FALHOU! Limite nao testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end
    endtask

    task automatic execute_tests_release_6();
        $display("\n=== EXECUTANDO TESTES RELEASE 6 ===");
        reset();
        
        old_configs = data_setup_new;
        
        // Teste 1: Entrar na opção 3 e testar digitação "1,2,3" → valor "23"
        enter_setup_r6_opcao3();

        // Verificar se está na opção 3
        print_teste(bcd_pac_setup.BCD5 == 3, 1, "Não está na opção 3 (tempo de fechamento automático)");

        // Digitar "1,2,3" → deve resultar em "23" nos últimos 2 dígitos
        send_digit(4'd1);
        send_digit(4'd2);
        send_digit(4'd3);
        verificar_deslocamento_r6(4'd2, 4'd3);  // BCD1=2, BCD0=3 → valor "23"

        // Pressionar "*" para confirmar
        send_digit(4'hA);
        verificar_bcd_r6(4'd4);  // Deve ir para opção 4

        // Sair do setup
        return_to_operational_r6(5'd23);

        // Teste 2: Testar saturação mínima (03 → 05)
        enter_setup_r6_opcao3();
        
        send_digit(4'd0);
        send_digit(4'd3);
        send_digit(4'hA);
        test_limits_r6(5'd3, 5'd5);  // 03 deve ser saturado para 05

        send_digit(4'hA);
        verificar_bcd_r6(4'd5);  // Deve ir para opção 5

        return_to_operational_r6(5'd5);

        // Teste 3: Testar saturação máxima (97 → 60) 
        enter_setup_r6_opcao3();
        
        send_digit(4'd9);
        send_digit(4'd7);
        send_digit(4'hA);
        test_limits_r6(5'd97, 5'd60);  // 97 deve ser saturado para 60

        send_digit(4'hA);
        verificar_bcd_r6(4'd5);  // Deve ir para opção 5

        return_to_operational_r6(5'd60);

        $display("=== RELEASE 6 CONCLUÍDA ===\n");
    endtask

    // ====================================================
    // Release 7 tasks and tests
    // ====================================================
    task automatic enter_setup_r7(int steps);
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        repeat(steps) begin
            send_digit(4'hA);
            @(posedge clk);
        end
    endtask

    task automatic verificar_deslocamento_r7(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        if (bcd_pac_setup.BCD1 == expected_BCD1 && bcd_pac_setup.BCD0 == expected_BCD0) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac_setup.BCD1, bcd_pac_setup.BCD0);
        end
    endtask

    task automatic verificar_bcd_r7(logic [4:0] expected_BCD5);
        if (bcd_pac_setup.BCD5 == expected_BCD5) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente. BCD5: %0d", $time, bcd_pac_setup.BCD5);
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
        if (senha.digits === senha_old.digits) begin
            $display("[%0t] PASSOU! Senha nao foi alterada apos entrada incompleta.", $time);
        end else begin
            $display("[%0t] FALHOU! Senha foi alterada apos entrada incompleta.", $time);
        end
    endtask

    task automatic validar_senha_r7(senhaPac_t senha, int gerados_in[]);
        if (senha.digits === {gerados_in[0], gerados_in[1], gerados_in[2], gerados_in[3],
                              gerados_in[4], gerados_in[5]}) begin
            $display("[%0t] PASSOU! Senha alterada corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Senha nao alterada corretamente.", $time);
        end
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
        reset();
        
        old_configs = data_setup_new;

        for (int i = 0; i < 5; i++) begin
            senhaPac_t senha_old = get_senha_by_index(data_setup_new, i);
            
            $display("\n--- Testando Senha %0d (Opção %0d) ---", i, i + 5);

            // Teste 1: Entrada com < 4 dígitos → senha descartada
            $display("Teste 1: Entrada com 3 dígitos (deve ser descartada)");
            enter_setup_r7(i + 5);

            // Enviar apenas 3 dígitos + "*"
            send_digit(4'h1);
            send_digit(4'h2);
            send_digit(4'h3);
            send_digit(4'hA); // Confirmar com apenas 3 dígitos
            
            // Verificar se senha foi descartada (não deve ter mudado)
            verificar_descarte_r7(get_senha_by_index(data_setup_new, i), senha_old);

            // Teste 2: Entrada com > 12 dígitos → últimos 12 armazenados
            $display("Teste 2: Entrada com 14 dígitos (últimos 12 devem ser armazenados)");
            enter_setup_r7(i + 5);

            // Enviar 14 dígitos: 1,2,3,4,5,6,7,8,9,0,1,2,3,4
            int digitos_14[14] = '{1,2,3,4,5,6,7,8,9,0,1,2,3,4};
            for (int j = 0; j < 14; j++) begin
                send_digit(digitos_14[j]);
            end
            send_digit(4'hA); // Confirmar
            
            // Os últimos 12 dígitos devem ser: 3,4,5,6,7,8,9,0,1,2,3,4 
            int ultimos_12[12] = '{3,4,5,6,7,8,9,0,1,2,3,4};
            
            // Verificar se os últimos 12 foram armazenados (adaptar validação para 12 dígitos)
            if (get_senha_by_index(data_setup_new, i).digits[22:0] == {ultimos_12[0], ultimos_12[1], ultimos_12[2], 
                                                                        ultimos_12[3], ultimos_12[4], ultimos_12[5]}) begin
                $display("[%0t] PASSOU! Últimos 12 dígitos armazenados corretamente.", $time);
            end else begin
                $display("[%0t] FALHOU! Últimos 12 dígitos não armazenados corretamente.", $time);
            end

            // Teste 3: Entrada entre 4 e 12 dígitos → senha armazenada
            $display("Teste 3: Entrada com 6 dígitos válidos");
            enter_setup_r7(i + 5);

            // Enviar 6 dígitos válidos
            int digitos_validos[6] = '{1,2,3,4,5,6};
            for (int j = 0; j < 6; j++) begin
                send_digit(digitos_validos[j]);
            end
            send_digit(4'hA); // Confirmar
            
            // Validar se a senha foi alterada corretamente
            validar_senha_r7(get_senha_by_index(data_setup_new, i), digitos_validos);

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
                $display("[%0t] PASSOU! Retornou ao operacional com sucesso.", $time);
            end
            begin
                #1000;
                $display("[%0t] FALHOU! Não retornou ao operacional em tempo.", $time);
            end
        join_any
        disable fork;

        if (compare_configs_r7(data_setup_new, saved_senha_1, saved_senha_2, saved_senha_3, saved_senha_4, saved_senha_master)) begin
            $display("[%0t] PASSOU! Todas as senhas foram salvas corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Alguma senha não foi salva corretamente.", $time);
        end

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
        setup_on = 0;
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

        $display("\n===============================================");
        $display("TESTBENCH COMPLETO FINALIZADO");
        $display("===============================================\n");

        #100 $finish;
    end

endmodule