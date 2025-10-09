`timescale 1ns/1ps

module tb_completo_todas_releases;

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

    // --- Parâmetros Globais ---
    localparam int SEMENTE = 1111;
    localparam int QNT_ALEATORIOS = 10;
    localparam int PULSOS_TROCAR_MODO = 5300;
    localparam int TIMEOUT = 100;
    localparam int TEMPO_ESTAVEL = 300;
    
    // Release 1 - Parâmetros
    localparam int INTERVALO_MIN_RELEASE_1 = 4770;
    localparam int INTERVALO_MAX_RELEASE_1 = 5830;
    
    // Release 2 - Parâmetros
    localparam int PULSOS_LIGAR_LAMPADA = 300;
    localparam int INTERVALO_MIN_IGNORA = 1;
    localparam int INTERVALO_MAX_IGNORA = 299;
    localparam int INTERVALO_MIN_ACEITA = 300;
    localparam int INTERVALO_MAX_ACEITA = 5299;
    
    // Release 3 - Parâmetros
    localparam int DURACAO_PULSO_LONGO = 50;
    localparam int TEMPO_ESPERA_EXTENSO = 30000;
    localparam int MAX_DURACAO_INTERMITENTE = 30;
    localparam int MIN_DURACAO_INTERMITENTE = 1;
    localparam int MAX_INTERVALO_INTERMITENTE = 30000;
    localparam int MIN_INTERVALO_INTERMITENTE = 1;
    localparam int QTD_REPETICOES_TESTE_R3 = 10;
    localparam int CICLOS_ESTABILIZACAO_SENSOR = 4;
    
    // Release 4 - Parâmetros
    localparam int QTD_REPETICOES_TESTE_R4 = 10;
    
    // Release 5 - Parâmetros
    localparam int QTD_REPETICOES_TESTE_R5 = 10;
    localparam int MAX_DURACAO_INTERMITENTE_R5 = 5299;
    localparam int MIN_DURACAO_INTERMITENTE_R5 = 300;
    
    // Release 6 - Parâmetros
    localparam int INTERVALO_MIN_RELEASE_6 = 300;
    localparam int INTERVALO_MAX_RELEASE_6 = 5299;
    
    // Release 8 - Parâmetros
    localparam int QTD_RESETS_TESTE = 10;
    localparam int MIN_INTERVALO_RESET = 5300;
    localparam int MAX_INTERVALO_RESET = 10600;
    localparam int MIN_DURACAO_RESET = 301;
    localparam int MAX_DURACAO_RESET = 1000;
    localparam int MIN_INTERVALO_TROCA_MODO = 2000;
    localparam int MAX_INTERVALO_TROCA_MODO = 8000;
    localparam int MIN_INTERVALO_ESTIMULO = 500;
    localparam int MAX_INTERVALO_ESTIMULO = 4000;

    // --- Contadores Globais ---
    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;
    string separador = "======================================================";
    string separador_minor = "------------------------------------------------------";

    // --- Classe Geradora de Números Aleatórios ---
    class GeradorAleatorio;
        randc bit [12:0] num;
        int min, max;

        function new(input int min, input int max);
            this.min = min;
            this.max = max;
        endfunction

        constraint range_c { num inside {[min:max]}; }
    endclass

    // --- Instâncias dos Geradores ---
    GeradorAleatorio gen_release_1;
    GeradorAleatorio gen_ignora;
    GeradorAleatorio gen_aceita;
    GeradorAleatorio gen_release_6;

    // --- Eventos para Release 8 ---
    event teste_de_reset_concluido;
    int resets_executados = 0;

    // --- Tasks Comuns ---
    task automatic resetar; 
        begin
            rst = 1;
            repeat (3) @(posedge clk);
            rst = 0;
            #10;
        end
    endtask

    task automatic setarAutomatico; 
        begin
            resetar();
            if (led != 0) begin
                $display("[ERRO] Falha ao setar modo automático! Estado atual: %s", dut.sub_1.state.name());
                testes_falharam++;
            end
        end
    endtask

    task automatic setarManual; 
        begin
            resetar();
            push_button = 1;
            repeat(PULSOS_TROCAR_MODO + 10) @(posedge clk);
            push_button = 0;
            #10;
            if (led != 1) begin
                $display("[ERRO] Falha ao setar modo manual! Estado atual: %s", dut.sub_1.state.name());
                testes_falharam++;
            end
        end
    endtask

    // --- Tasks específicas da Release 8 ---
    task automatic simular_pulso_botao_release_8(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] Release 8 - STIMULUS: Pulso PUSH_BUTTON por %0d ciclos", $time, duracao);
        push_button = 1'b1;
        repeat(duracao) @(posedge clk);
        push_button = 1'b0;
    endtask

    task automatic simular_pulso_ir_release_8(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] Release 8 - STIMULUS: Pulso INFRAVERMELHO por %0d ciclos", $time, duracao);
        infravermelho = 1'b1;
        repeat(duracao) @(posedge clk);
        infravermelho = 1'b0;
    endtask

    task automatic simular_pulso_reset_release_8(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] Release 8 - **** RESET EVENT por %0d ciclos ****", $time, duracao);
        rst = 1'b1;
        repeat(duracao) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        
        total_testes++;
        if (led == 0 && saida == 0) begin
            testes_passaram++;
            $display("[%0t ns] [PASSOU] Release 8 - Reset: Led=0, Saida=0", $time);
        end else begin
            testes_falharam++;
            $display("[%0t ns] [FALHOU] Release 8 - Reset: Led=%b, Saida=%b", $time, led, saida);
        end
        
        resets_executados++;
    endtask

    task automatic gerador_troca_de_modo_release_8;
        fork
            begin
                repeat(15) begin // Limitar as iterações para não ficar infinito
                    int intervalo = $urandom_range(MAX_INTERVALO_TROCA_MODO, MIN_INTERVALO_TROCA_MODO);
                    repeat(intervalo) @(posedge clk);
                    simular_pulso_botao_release_8(5300, 5830);
                end
            end
        join_none
    endtask

    task automatic gerador_estimulos_de_modo_release_8;
        fork
            begin
                repeat(25) begin // Limitar as iterações
                    int intervalo = $urandom_range(MAX_INTERVALO_ESTIMULO, MIN_INTERVALO_ESTIMULO);
                    repeat(intervalo) @(posedge clk);
                    
                    if (led == 1) begin // Modo Manual
                        simular_pulso_botao_release_8(300, 5299);
                    end else begin // Modo Automático
                        simular_pulso_ir_release_8(1, 30000);
                    end
                end
            end
        join_none
    endtask

    task automatic gerador_de_resets_release_8;
        fork
            begin
                repeat (QTD_RESETS_TESTE) begin
                    int intervalo_reset = $urandom_range(MAX_INTERVALO_RESET, MIN_INTERVALO_RESET);
                    repeat(intervalo_reset) @(posedge clk);
                    simular_pulso_reset_release_8(MIN_DURACAO_RESET, MAX_DURACAO_RESET);
                end
                $display("[%0t ns] Release 8 - Gerador de resets completou %0d acionamentos", $time, QTD_RESETS_TESTE);
                ->teste_de_reset_concluido;
            end
        join_none
    endtask

    // ============================================
    // RELEASE 1: Teste de alternância de modos
    // ============================================
    task automatic teste_alternar_modos_release_1(input int qnt_pulsos);
        logic led_esperado = qnt_pulsos > PULSOS_TROCAR_MODO;
        static int num_teste = 1;

        resetar();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;

        total_testes++;
        $display("%s", separador_minor);
        
        if (led === led_esperado) begin
            testes_passaram++;
            $display("[PASSOU] Release 1 - Teste %0d: Pulsos: %0d | LED: %b | Esperado: %b",
                num_teste, qnt_pulsos, led, led_esperado);
        end else begin
            testes_falharam++;
            $display("[FALHOU] Release 1 - Teste %0d: Pulsos: %0d | LED: %b | Esperado: %b",
                num_teste, qnt_pulsos, led, led_esperado);
        end

        num_teste++;
        #5;
    endtask

    task automatic executar_testes_release_1;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 1: Alternância de Modos");
            $display("%s", separador);

            // Testes fixos
            teste_alternar_modos_release_1(5300);
            teste_alternar_modos_release_1(5301);
            teste_alternar_modos_release_1(5305);

            // Testes aleatórios
            gen_release_1 = new(INTERVALO_MIN_RELEASE_1, INTERVALO_MAX_RELEASE_1);
            $srandom(SEMENTE);

            repeat(QNT_ALEATORIOS) begin
                gen_release_1.randomize();
                teste_alternar_modos_release_1(gen_release_1.num);
            end
        end
    endtask

    // ============================================
    // RELEASE 2: Teste de controle manual
    // ============================================
    task automatic simular_teste_release_2(input int qnt_pulsos);
        logic lampada_esperado = (qnt_pulsos >= PULSOS_LIGAR_LAMPADA) ? 1'b1 : 1'b0;
        static int num_teste = 1;

        setarManual();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;

        total_testes++;
        $display("%s", separador_minor);

        if (saida === lampada_esperado) begin
            testes_passaram++;
            $display("[PASSOU] Release 2 - Teste %2d: Pulsos: %4d | SAIDA: %b | Esperado: %b | Estado: %s",
                num_teste, qnt_pulsos, saida, lampada_esperado, dut.sub_1.state.name());
        end else begin
            testes_falharam++;
            $display("[FALHOU] Release 2 - Teste %2d: Pulsos: %4d | SAIDA: %b | Esperado: %b | Estado: %s",
                num_teste, qnt_pulsos, saida, lampada_esperado, dut.sub_1.state.name());
        end

        num_teste++;
        #5;
    endtask

    task automatic executar_testes_release_2;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 2: Controle Manual");
            $display("%s", separador);

            // Testes fixos
            simular_teste_release_2(200);  // Deve ser ignorado
            simular_teste_release_2(300);  // Deve ser aceito
            simular_teste_release_2(500);  // Deve ser aceito

            // Testes aleatórios - valores que devem ser ignorados
            gen_ignora = new(INTERVALO_MIN_IGNORA, INTERVALO_MAX_IGNORA);
            repeat(5) begin
                gen_ignora.randomize();
                simular_teste_release_2(gen_ignora.num);
            end

            // Testes aleatórios - valores que devem ser aceitos
            gen_aceita = new(INTERVALO_MIN_ACEITA, INTERVALO_MAX_ACEITA);
            repeat(5) begin
                gen_aceita.randomize();
                simular_teste_release_2(gen_aceita.num);
            end
        end
    endtask

    // ============================================
    // RELEASE 3: Teste de sensor infravermelho
    // ============================================
    task simular_estimulo_proximidade_release_3(input int largura_pulso_ciclos);
        begin
            infravermelho = 1'b1;
            repeat(largura_pulso_ciclos) @(posedge clk);
            infravermelho = 1'b0;
            repeat(CICLOS_ESTABILIZACAO_SENSOR) @(posedge clk);
        end
    endtask

    task executar_teste_pulso_longo_release_3;
        begin
            $display("Release 3 - Cenário 1: Pulso único de longa duração");
            setarAutomatico();
            
            simular_estimulo_proximidade_release_3(DURACAO_PULSO_LONGO);
            $display("Sensor ativado, saída acionada. Status da Saída: %0d", saida);

            $display("Sensor desativado. Aguardando %0d ciclos...", TEMPO_ESPERA_EXTENSO);
            repeat(TEMPO_ESPERA_EXTENSO) @(posedge clk);

            total_testes++;
            if (saida == 0) begin
                testes_passaram++;
                $display("[PASSOU] Release 3 - Teste Pulso Longo: Saída desligou após timeout");
            end else begin
                testes_falharam++;
                $display("[FALHOU] Release 3 - Teste Pulso Longo: Saída não desligou após timeout");
            end
        end
    endtask

    task executar_teste_estimulos_intermitentes_release_3;
        begin
            $display("Release 3 - Cenário 2: Simulação de movimentos intermitentes");
            setarAutomatico();

            for (int i = 0; i < QTD_REPETICOES_TESTE_R3; i++) begin
                int duracao_pulso_rand, intervalo_rand;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
                intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

                simular_estimulo_proximidade_release_3(duracao_pulso_rand);
                $display("Release 3 - Movimento %2d/%d: Pulso %0d ciclos, pausa %0d ciclos. Saída: %0d", 
                    i+1, QTD_REPETICOES_TESTE_R3, duracao_pulso_rand, intervalo_rand, saida);

                repeat(intervalo_rand) @(posedge clk);
            end

            total_testes++;
            if (saida == 1) begin
                testes_passaram++;
                $display("[PASSOU] Release 3 - Estimulos Intermitentes: Saída permaneceu ligada");
            end else begin
                testes_falharam++;
                $display("[FALHOU] Release 3 - Estimulos Intermitentes: Saída não permaneceu ligada");
            end
        end
    endtask

    task automatic executar_testes_release_3;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 3: Sensor Infravermelho");
            $display("%s", separador);

            executar_teste_pulso_longo_release_3();
            executar_teste_estimulos_intermitentes_release_3();
        end
    endtask

    // ============================================
    // RELEASE 4: Teste de modo manual com IR
    // ============================================
    task simular_estimulo_proximidade_release_4(input int largura_pulso_ciclos);
        begin
            infravermelho = 1'b1;
            repeat(largura_pulso_ciclos) @(posedge clk);
            infravermelho = 1'b0;
            repeat(CICLOS_ESTABILIZACAO_SENSOR) @(posedge clk);
            #10;
        end
    endtask

    task executar_teste_estimulos_intermitentes_release_4;
        begin
            $display("Release 4 - Geração de 10 pulsos para o infravermelho em modo manual");

            for (int i = 0; i < QTD_REPETICOES_TESTE_R4; i++) begin
                int duracao_pulso_rand, intervalo_rand;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
                intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

                simular_estimulo_proximidade_release_4(duracao_pulso_rand);

                total_testes++;
                $display("Release 4 - Movimento %2d/%0d: Pulso %0d ciclos, pausa %0d ciclos", 
                    i+1, QTD_REPETICOES_TESTE_R4, duracao_pulso_rand, intervalo_rand);

                if (led == 1) begin
                    testes_passaram++;
                    $display("[PASSOU] SAÍDA: %0d | LED: %b", saida, led);
                end else begin
                    testes_falharam++;
                    $display("[FALHOU] SAÍDA: %0d | LED: %b", saida, led);
                end

                repeat(intervalo_rand) @(posedge clk);
            end
        end
    endtask

    task automatic executar_testes_release_4;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 4: Modo Manual com Infravermelho");
            $display("%s", separador);

            setarManual();
            $display("Release 4 - Modo manual ativado. LED: %b | Lampada: %b", led, saida);
            
            executar_teste_estimulos_intermitentes_release_4();
        end
    endtask

    // ============================================
    // RELEASE 5: Teste de botão em modo manual
    // ============================================
    task simular_pressionar_botao_release_5(input int largura_pulso_ciclos);
        begin
            push_button = 1'b1;
            repeat(largura_pulso_ciclos) @(posedge clk);
            push_button = 1'b0;
            #10;
        end
    endtask

    task executar_teste_estimulos_intermitentes_release_5;
        begin
            $display("Release 5 - Geração de 10 pulsos para o push button em modo manual");

            for (int i = 0; i < QTD_REPETICOES_TESTE_R5; i++) begin
                int duracao_pulso_rand;
                logic saida_anterior;

                saida_anterior = saida;
                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE_R5, MIN_DURACAO_INTERMITENTE_R5);

                simular_pressionar_botao_release_5(duracao_pulso_rand);
                @(posedge clk);

                total_testes++;
                $display("Release 5 - Pressionando %2d/%0d: Pulso %0d ciclos", 
                    i+1, QTD_REPETICOES_TESTE_R5, duracao_pulso_rand);
                $display("Saida: %b | saida anterior: %b", saida, saida_anterior);
                
                if (saida != saida_anterior) begin
                    testes_passaram++;
                    $display("[PASSOU] SAÍDA: %0d | LED: %b", saida, led);
                end else begin
                    testes_falharam++;
                    $display("[FALHOU] SAÍDA: %0d | LED: %b", saida, led);
                end
            end
        end
    endtask

    task automatic executar_testes_release_5;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 5: Botão em Modo Manual");
            $display("%s", separador);

            setarManual();
            $display("Release 5 - Modo manual ativado. LED: %b | Lampada: %b", led, saida);
            
            executar_teste_estimulos_intermitentes_release_5();
        end
    endtask

    // ============================================
    // RELEASE 6: Teste de botão em modo automático
    // ============================================
    task automatic simular_teste_release_6(input int qnt_pulsos);
        logic saida_esperado = 0; // Em modo automático, botão não deve afetar a saída
        static int num_teste = 1;

        setarAutomatico();
        push_button = 1;
        repeat(qnt_pulsos) @(posedge clk);
        push_button = 0;
        #10;

        total_testes++;
        $display("%s", separador_minor);

        if (saida === saida_esperado) begin
            testes_passaram++;
            $display("[PASSOU] Release 6 - Teste %2d: Pulsos: %4d | SAIDA: %b | Esperado: %b | Estado: %s",
                num_teste, qnt_pulsos, saida, saida_esperado, dut.sub_1.state.name());
        end else begin
            testes_falharam++;
            $display("[FALHOU] Release 6 - Teste %2d: Pulsos: %4d | SAIDA: %b | Esperado: %b | Estado: %s",
                num_teste, qnt_pulsos, saida, saida_esperado, dut.sub_1.state.name());
        end

        num_teste++;
        #5;
    endtask

    task automatic executar_testes_release_6;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 6: Botão em Modo Automático");
            $display("%s", separador);

            gen_release_6 = new(INTERVALO_MIN_RELEASE_6, INTERVALO_MAX_RELEASE_6);

            repeat(QNT_ALEATORIOS) begin
                gen_release_6.randomize();
                simular_teste_release_6(gen_release_6.num);
            end
        end
    endtask

    // ============================================
    // RELEASE 7: Teste de troca de modo após IR
    // ============================================
    task automatic acenderInfravermelho;
        begin
            infravermelho = 1;
            repeat(10) @(posedge clk);
            infravermelho = 0;
            #10;
            
            if (saida == 1) begin
                testes_passaram++;
                $display("[PASSOU] Release 7 - Infravermelho: SAIDA: %b | Estado: %s", saida, dut.sub_1.state.name());
            end else begin
                testes_falharam++;
                $display("[FALHOU] Release 7 - Infravermelho: SAIDA: %b | Estado: %s", saida, dut.sub_1.state.name());
            end
        end
    endtask

    task automatic trocarModo;
        begin
            push_button = 1;
            repeat(PULSOS_TROCAR_MODO + 10) @(posedge clk);
            push_button = 0;
            #10;
            
            if (led == 1) begin
                testes_passaram++;
                $display("[PASSOU] Release 7 - Trocar Modo: LED: %b | Estado: %s", led, dut.sub_1.state.name());
            end else begin
                testes_falharam++;
                $display("[FALHOU] Release 7 - Trocar Modo: LED: %b | Estado: %s", led, dut.sub_1.state.name());
            end
        end
    endtask

    task automatic simular_teste_release_7;
        begin
            setarAutomatico();
            total_testes++;
            #10;
            acenderInfravermelho();
            total_testes++;
            #10;
            trocarModo();
            total_testes++;
            #10;
        end
    endtask

    task automatic executar_testes_release_7;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 7: Troca de Modo após Infravermelho");
            $display("%s", separador);

            simular_teste_release_7();
        end
    endtask

    // ============================================
    // RELEASE 8: Teste de reset concorrente
    // ============================================
    task automatic executar_testes_release_8;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 8: Reset Concorrente");
            $display("%s", separador);

            // Inicializar sinais
            push_button = 1'b0;
            infravermelho = 1'b0;
            resets_executados = 0;

            $display("[%0t ns] Release 8 - Iniciando simulação concorrente de reset...", $time);

            // Inicia os processos paralelos
            gerador_troca_de_modo_release_8();
            gerador_estimulos_de_modo_release_8();
            gerador_de_resets_release_8();

            // Espera o sinal de que os resets foram concluídos
            @(teste_de_reset_concluido);

            $display("[%0t ns] Release 8 - Teste de %0d resets concluído", $time, QTD_RESETS_TESTE);
            
            // Pequena pausa antes do próximo teste
            #1000;
        end
    endtask

    // ============================================
    // SEQUÊNCIA PRINCIPAL DE EXECUÇÃO
    // ============================================
    initial begin
        resetar();
        #10;

        $display("==============================================================");
        $display("      INICIANDO TESTE COMPLETO DE TODAS AS RELEASES (1-8)");
        $display("==============================================================");
        $display("SAIDA: %b | LED: %b | ESTADO: %s\n", saida, led, dut.sub_1.state.name());

        // Executar todos os testes sequencialmente
        executar_testes_release_1();
        executar_testes_release_2();
        executar_testes_release_3();
        executar_testes_release_4();
        executar_testes_release_5();
        executar_testes_release_6();
        executar_testes_release_7();
        executar_testes_release_8();

        // Resumo final
        $display("%s", separador);
        $display("                    RESUMO FINAL DOS TESTES");
        $display("%s", separador);
        $display("Total de testes executados: %0d", total_testes);
        $display("Testes que passaram: %0d", testes_passaram);
        $display("Testes que falharam: %0d", testes_falharam);
        $display("Taxa de sucesso: %.1f%%", (real'(testes_passaram) / real'(total_testes)) * 100.0);
        $display("%s", separador);

        #100 $finish;
    end

endmodule