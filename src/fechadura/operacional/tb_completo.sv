`timescale 1ns/1ns

module testbench_operacional;
    parameter int UM_SEGUNDO = 1000;
    parameter int DEBOUNCE = 100;
    parameter int TIMEOUT = DEBOUNCE + 10;

    logic clk = 0;
    logic rst = 0;
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
    int num_teste = 1;
    bit teclado_ativo;
    logic [3:0] senha1 [8];
    int tempo;
    int ciclos;

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

    // ========== TASKS COMUNS ==========
    task automatic reset();
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    endtask

    task send_digit(input logic [3:0] digit);
        // Shift das teclas
        digitos_value.digits = {digitos_value.digits[18:0], digit};
        repeat (3) @(posedge clk);

        digitos_valid = 1'b1;
        repeat (5) @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);

        if (digit == 4'hA || digit == 4'hB) begin
            digitos_value = '1;
        end
        @(posedge clk);
    endtask

    // Macro que avalia a expressão dinamicamente usando polling (funciona com funções sem argumentos)
    `define print_teste(condicao, msg_erro) \
        begin \
            total_testes++; \
            fork \
                begin \
                    while (!(condicao)) @(posedge clk); \
                    $display("Teste %0d: PASSOU!", num_teste); \
                    testes_passaram++; \
                end \
                begin \
                    repeat (TIMEOUT) @(posedge clk); \
                    $display("Teste %0d: FALHOU! %s", num_teste, msg_erro); \
                    testes_falharam++; \
                end \
            join_any \
            disable fork; \
            num_teste++; \
        end

    task automatic aguarda_ciclos(input int ciclos);
        repeat(ciclos) @(posedge clk);
    endtask

    task automatic aguarda_segundos(input int segundos);
        aguarda_ciclos(segundos * UM_SEGUNDO);
    endtask

    task automatic digitar_aleatorios(input int n);
        for (int i = 0; i < n; i++) begin
            send_digit($urandom_range(0, 9));
        end
    endtask

    task automatic trancar_porta();
        sensor_contato = 0;

        repeat (3) @(posedge clk);

        if (tranca == 0) begin
            botao_interno = 1;
            repeat (DEBOUNCE + 5) @(posedge clk);
            botao_interno = 0;
            @(posedge clk);
        end
    endtask

    function automatic logic [3:0] retorna_bcd_por_idx(input int idx);
        case(idx)
            0: return bcd_pac.BCD0;
            1: return bcd_pac.BCD1;
            2: return bcd_pac.BCD2;
            3: return bcd_pac.BCD3;
            4: return bcd_pac.BCD4;
            5: return bcd_pac.BCD5;
            default: return '1;
        endcase
    endfunction

    function automatic logic verifica_valor_bcd(input int idx);
        // Verifica se os displays de 0 até idx mostram hífen
        for(int i = 0; i <= idx; i++)begin
            logic [3:0] bcd = retorna_bcd_por_idx(i);
            if(bcd !== 4'hA)
                return 1'b0;
        end
        return 1'b1;
    endfunction

    function automatic logic verifica_todos_bcd_hifen();
        // Verifica se todos os displays mostram hífen
        for(int i = 0; i < 5; i++)begin
            logic [3:0] bcd = retorna_bcd_por_idx(i);
            if(bcd !== 4'hA)
                return 1'b0;
        end
        return 1'b1;
    endfunction

    task automatic envia_senha_errada();
        // Envia 3 dígitos aleatórios + '*' para confirmar senha incorreta
        for (int j = 0; j < 3; j++) begin
            send_digit($urandom_range(0, 9));
        end
        send_digit(4'hA); // '*' para confirmar
        repeat(2)@(posedge clk);
    endtask

    task automatic destravar_porta();
        botao_interno = 1'b1;
        repeat (DEBOUNCE + 5) @(posedge clk);
        botao_interno = 1'b0;
        repeat (2) @(posedge clk);
    endtask

    task automatic destrancar_porta(input logic [3:0] senha [8]);
        for (int i = 0; i < 8; i++) begin
            send_digit(senha[i]);
        end
        send_digit(4'hA);
        @(posedge clk);
        sensor_contato = 1;
    endtask

    // ========== RELEASE 1: Teste de buffer de senha ==========
    task automatic execute_tests_release1();
        $display("\n========== INICIANDO TESTES RELEASE 1 ==========");
        senha1 = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};
        num_teste = 1;

        for (int i = 0; i < 5; i++) begin
            send_digit(senha1[i]);
        end

        send_digit(4'hB);
        `print_teste(digitos_value.digits == '1, "Valores não foram apagados após #")

        send_digit(4'hA);
        `print_teste(tranca == 1, "A senha incompleta foi considerada")
    endtask

    // ========== RELEASE 2: Teste de timeout entre dígitos ==========
    task automatic execute_tests_release2();
        $display("\n========== INICIANDO TESTES RELEASE 2 ==========");
        senha1 = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};
        num_teste = 1;

        for (int i = 0; i < 19; i++) begin
            if (i < 8)
                send_digit(senha1[i]);
            else
                send_digit(4'h5);
            
            tempo = $urandom_range(1, 6);
            aguarda_segundos(tempo);

            if (tempo > 5) begin
                digitos_value = {20{4'hE}};
                repeat (3) @(posedge clk);
                digitos_valid = 1'b1;
                @(posedge clk);
                digitos_valid = 1'b0;
                digitos_value = '1;
            end

            `print_teste((tempo > 5 && bip == 1) || (tempo <= 5 && bip == 0), 
                       "Timeout entre dígitos não funcionou corretamente")
        end
    endtask

    // ========== RELEASE 3: Teste de senha em buffer de 20 dígitos ==========
    task automatic execute_tests_release3();
        $display("\n========== INICIANDO TESTES RELEASE 3 ==========");
        senha1 = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};
        num_teste = 1;

        trancar_porta();
        repeat (10) @(posedge clk);

        digitar_aleatorios(12);
        for (int i = 0; i < 8; i++) begin
            send_digit(senha1[i]);
        end
        send_digit(4'hA);
        `print_teste(tranca == 0, "Tranca não destravou (aleatórios + senha + *)")

        trancar_porta();
        repeat (10) @(posedge clk);

        for (int i = 0; i < 8; i++) begin
            send_digit(senha1[i]);
        end
        digitar_aleatorios(12);
        send_digit(4'hA);
        `print_teste(tranca == 0, "Tranca não destravou (senha + aleatórios + *)")

        trancar_porta();
        repeat (10) @(posedge clk);

        digitar_aleatorios(6);
        for (int i = 0; i < 8; i++) begin
            send_digit(senha1[i]);
        end
        digitar_aleatorios(6);
        send_digit(4'hA);
        `print_teste(tranca == 0, "Tranca não destravou (aleatórios + senha + aleatórios + *)")
    endtask

    // ========== RELEASE 4: Teste de bloqueio por erros ==========
    task automatic execute_tests_release4();
        $display("\n========== INICIANDO TESTES RELEASE 4 ==========");

        num_teste = 1;
        
        // Teste 1 a 4: Erros de 1 a 4 - Verificar sistema inoperante por 1s e displays
        for (int i = 0; i < 4; i++) begin  
            teclado_ativo = 1'b0;
            // Envia senha errada
            envia_senha_errada();
            // Verifica se o display correspondente está com hífen
            `print_teste(verifica_valor_bcd(i), $sformatf("BCD%0d deveria mostrar hífen após erro %0d", i, i+1))
            
            fork
                begin
                    // Aguarda 1 segundo (sistema inoperante)
                    aguarda_segundos(1); // 1 segundo
                end
                begin
                    while (teclado_en == 0) @(posedge clk);
                    teclado_ativo = 1'b1;
                end
            join_any
            disable fork;
            `print_teste(teclado_ativo == 1'b0, $sformatf("Teclado deveria estar desabilitado por 1s após erro %0d", i+1))
        end

        ciclos = 0;
        teclado_ativo = 1'b0;
        // Teste 5: 5º erro - Bloqueio de 30s e todos displays com hífen
        envia_senha_errada();
        // Verifica se todos os displays mostram hífen
        `print_teste(verifica_todos_bcd_hifen(), "Todos os displays deveriam mostrar hífen após 5 erros")
        fork
            begin
                // Aguarda 30 segundos  (sistema inoperante)
                aguarda_segundos(30); // 30 segundos
            end
            begin
                while (teclado_en == 0)begin
                    @(posedge clk);
                    ciclos++;
                end
                teclado_ativo = 1'b1;
            end
        join_any
        disable fork;
        // Teste 6: verifica se o teclado ficou desabilitado durante o bloqueio
        `print_teste(teclado_ativo == 1'b0, "Teclado deveria estar desabilitado durante o bloqueio")

        aguarda_ciclos((30 * UM_SEGUNDO) - ciclos); // Completa os 30 segundos se tiver saido do loop antes
        `print_teste(teclado_en == 1'b1, "Sistema deveria normalizar após 30s (teclado_en ativo)")
    endtask

    // ========== RELEASE 5: Teste de botão interno ==========
    task automatic execute_tests_release5();
        $display("\n========== INICIANDO TESTES RELEASE 5 ==========");
        num_teste = 1;
        `print_teste(tranca == 1'b1, "Tranca deveria estar travada no estado inicial")
        
        botao_interno = 1'b1;
        repeat (DEBOUNCE + 5) @(posedge clk);
        botao_interno = 1'b0;
        `print_teste(tranca == 1'b0, "Tranca deveria destravar ao pressionar botão interno")
    endtask

    // ========== RELEASE 6: Teste de modo Não Perturbe ==========
    task automatic execute_tests_release6();
        $display("\n========== INICIANDO TESTES RELEASE 6 ==========");
        num_teste = 1;
        `print_teste(teclado_en == 1'b1, "Teclado deveria estar habilitado inicialmente")
        
        sensor_contato = 1'b1;
        repeat (2) @(posedge clk);
        
        botao_bloqueio = 1'b1;
        aguarda_segundos(2);
        botao_bloqueio = 1'b0;
        `print_teste(teclado_en == 1'b1, "Teclado não deveria desabilitar com menos de 3s")
        
        repeat (5) @(posedge clk);
        botao_bloqueio = 1'b1;
        aguarda_segundos(3);
        `print_teste(teclado_en == 1'b0, "Teclado deveria estar desabilitado após 3s")
        
        botao_bloqueio = 1'b0;
        `print_teste(teclado_en == 1'b0, "Teclado deve permanecer desabilitado após soltar botão")
        
        send_digit(4'd1);
        repeat (5) @(posedge clk);
        send_digit(4'hA);
        `print_teste(teclado_en == 1'b0, "Teclado deve permanecer desabilitado durante uso")
        
        `print_teste(tranca == 1'b1, "Tranca deveria estar travada durante modo Não Perturbe")
        
        botao_interno = 1'b1;
        repeat (DEBOUNCE + 5) @(posedge clk);
        botao_interno = 1'b0;
        `print_teste(tranca == 1'b0, "Botão interno deve destravar mesmo em modo Não Perturbe")
    endtask

    // ========== RELEASE 7: Teste de timer de trancamento automático ==========
    task automatic execute_tests_release7();
        $display("\n========== INICIANDO TESTES RELEASE 7 ==========");
        num_teste = 1;
        sensor_contato = 1'b1;
        repeat (5) @(posedge clk);
        `print_teste(sensor_contato == 1'b1, "Porta deveria estar fechada inicialmente")
        
        destravar_porta();
        repeat (5) @(posedge clk);
        `print_teste(tranca == 1'b0, "Tranca deveria estar destravada")
        
        sensor_contato = 1'b1;
        repeat (5) @(posedge clk);
        `print_teste(tranca == 1'b0, "Tranca ainda deve estar destravada no início")
        
        aguarda_ciclos((UM_SEGUNDO * data_setup_new.tranca_aut_time) * 3 / 4);
        `print_teste(tranca == 1'b0, "Tranca não deveria travar antes do tempo configurado") // verifica após 3/4 do tempo total

        aguarda_ciclos((UM_SEGUNDO * data_setup_new.tranca_aut_time) / 4);
        `print_teste(tranca == 1'b1, "Tranca deveria travar ao completar o tempo configurado") // verifica após o tempo total 1/4 + 3/4 = 1

        destravar_porta();
        repeat (5) @(posedge clk);
        sensor_contato = 1'b1;
        repeat (5) @(posedge clk);
        aguarda_segundos(3);
        sensor_contato = 1'b0;
        repeat (5) @(posedge clk);
        aguarda_segundos(data_setup_new.tranca_aut_time - 3);
        `print_teste(tranca == 1'b0, "Tranca não deveria travar após interrupção do timer")
    endtask

    // ========== RELEASE 8: Teste de alarme de porta aberta ==========
    task automatic execute_tests_release8();
        $display("\n========== INICIANDO TESTES RELEASE 8 ==========");
        senha1 = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};
        num_teste = 1;
        trancar_porta();
        destrancar_porta(senha1);

        fork
            begin
                aguarda_ciclos((data_setup_new.bip_time) * UM_SEGUNDO);
            end
            begin
                while (bip == 0) @(posedge clk);
                `print_teste(bip == 0, "Bip acionado antes do tempo de porta aberta excedido")
            end
        join_any
        disable fork;

        @(posedge clk);
        `print_teste(bip == 1, "Bip não acionado após tempo de porta aberta excedido")

        trancar_porta();
        destrancar_porta(senha1);

        fork
            begin
                aguarda_ciclos((data_setup_new.bip_time) * UM_SEGUNDO - 1);
            end
            begin
                while (bip == 0) @(posedge clk);
                `print_teste(bip == 0, "Bip acionado antes do tempo excedido (caso 2)")
            end
        join_any
        disable fork;

        sensor_contato = 0;
        @(posedge clk);
        `print_teste(bip == 0, "Bip acionado após fechar porta antes do tempo")
    endtask

    task automatic configuracoes_iniciais();
        data_setup_new.senha_1.digits = '{7:4'h1, 6:4'h2, 5:4'h3, 4:4'h4, 3:4'h5, 2:4'h6, 1:4'h7, 0:4'h8, default: 4'hf};
        data_setup_new.tranca_aut_time = 6'd10; // 10 segundos para timer de trancamento
        data_setup_new.bip_time = 6'd5; // 5 segundos para alarme
        data_setup_ok = 1;
        @(posedge clk);
        data_setup_ok = 0;
        sensor_contato = 0;

        repeat (3) @(posedge clk);
    endtask

    // ========== SEQUÊNCIA PRINCIPAL DE TESTES ==========
    initial begin
        
        // Executar todos os testes sequencialmente
        reset();
        configuracoes_iniciais();
        execute_tests_release1();

        reset();
        configuracoes_iniciais();
        execute_tests_release2();

        reset();
        configuracoes_iniciais();
        execute_tests_release3();

        reset();
        configuracoes_iniciais();
        execute_tests_release4();

        reset();
        configuracoes_iniciais();
        execute_tests_release5();

        reset();
        configuracoes_iniciais();
        execute_tests_release6();

        reset();
        configuracoes_iniciais();
        execute_tests_release7();

        reset();
        configuracoes_iniciais();
        execute_tests_release8();

        // Resumo final
        $display("\n========================================");
        $display("RESUMO FINAL DOS TESTES");
        $display("========================================");
        $display("Total de testes: %0d", total_testes);
        $display("Testes passaram: %0d", testes_passaram);
        $display("Testes falharam: %0d", testes_falharam);
        if (testes_falharam == 0)
            $display("STATUS: TODOS OS TESTES PASSARAM!");
        else
            $display("STATUS: ALGUNS TESTES FALHARAM!");
        $display("========================================\n");
        
        #100 $finish;
    end

endmodule