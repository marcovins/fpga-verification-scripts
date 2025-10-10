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

    class GeradorAleatorio;
        int min, max;
        int valores[];     // Array dinâmico
        int indice = 0;    // Índice do próximo número a ser retornado

        // Construtor
        function new(int min, int max);
            this.min = min;
            this.max = max;
            valores = new[max - min + 1]; // aloca tamanho
            for (int i = 0; i <= (max - min); i++)
                valores[i] = min + i;
            embaralhar();
        endfunction

        // Função para embaralhar
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

        // Próximo valor
        function int proximo();
            if (indice >= valores.size())
                embaralhar();
            return valores[indice++];
        endfunction
    endclass

    // Função para converter string para maiúsculas
    function string to_upper(string s);
        int i;
        for (i = 0; i < s.len(); i++) begin
            if (s[i] >= "a" && s[i] <= "z")
                s[i] = s[i] - 32;
        end
        return s;
    endfunction

    // --- Instâncias dos Geradores ---
    GeradorAleatorio gen_release_1;
    GeradorAleatorio gen_ignora;
    GeradorAleatorio gen_aceita;
    GeradorAleatorio gen_release_6;

    // --- Eventos para Release 8 ---
    event teste_de_reset_concluido;

    // --- Tasks Comuns ---
    task automatic resetar; 
        begin
            pressionar_reset(3);
            #10;
        end
    endtask

    task automatic pressionar_push_button(input int duracao);
        begin
            push_button = 1'b1;
            repeat(duracao) @(posedge clk);
            push_button = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic simular_deteccao_infravermelho(input int duracao);
        begin
            infravermelho = 1'b1;
            repeat(duracao) @(posedge clk);
            infravermelho = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic pressionar_reset(input int duracao);
        begin
            rst = 1'b1;
            repeat(duracao) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
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
            pressionar_push_button(PULSOS_TROCAR_MODO + 10);
            #10;
            if (led != 1) begin
                $display("[ERRO] Falha ao setar modo manual! Estado atual: %s", dut.sub_1.state.name());
                testes_falharam++;
            end
        end
    endtask

    // --- Tasks específicas da Release 8 ---
    task automatic simular_pulso_botao_release_8(input int min_ciclos, input int max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        pressionar_push_button(duracao);
    endtask

    task automatic simular_pulso_ir_release_8(input int min_ciclos, input int max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        simular_deteccao_infravermelho(duracao);
    endtask

    task automatic simular_pulso_reset_release_8(input int min_ciclos, input int max_ciclos);
        static int resets_executados = 1;
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("                      **** RESET EVENT por %0d ciclos ****        ", duracao);
        pressionar_reset(duracao);
        
        validar_teste(
            .num_teste(resets_executados),
            .pulsos(duracao),
            .sinal_esperado(1'b0),
            .release_teste(8),
            .sinal_tipo("reset")
        );
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
    // Task de monitorar estabilidade da saida
    // ============================================
    task automatic monitorar_sinal(
        input  string      sinal,
        output logic       sinal_amostra,
        output bit         sinal_estavel
    );
        int unsigned tempo = 0;
        logic sinal_anterior = (sinal == "led") ? led : saida;
        sinal_estavel = 1'b1;

        while (tempo < TEMPO_ESTAVEL) begin
            @(posedge clk);
            sinal_amostra = (sinal == "led") ? led : saida;
            if (sinal_amostra !== sinal_anterior) begin
                sinal_estavel = 1'b0;
                return;
            end
            tempo++;
        end
    endtask

    // ============================================
    // Task de monitorar timeout de resposta
    // ============================================
    task automatic monitorar_timeout(
        input   string    sinal,
        input   logic     sinal_esperado,
        output  logic     sinal_amostra,
        output  bit       timeout
    );
        int unsigned tempo = 0;
        timeout = 1'b0;

        while (tempo < TIMEOUT) begin
            @(posedge clk);
            sinal_amostra = (sinal == "led") ? led : saida;
            if (sinal_amostra === sinal_esperado) begin
                return;
            end
            tempo++;
        end

        timeout = 1'b1;
        @(posedge clk);
    endtask

    // ============================================
    // Task para validar o teste e exibir o resultado
    // ============================================
    task automatic validar_teste(
        inout int num_teste,
        input int pulsos,
        input logic sinal_esperado,
        input int release_teste,
        input string sinal_tipo
    );
        bit sinal_estavel;
        bit timeout;
        logic sinal_amostra;

        monitorar_timeout(
            .sinal(sinal_tipo),
            .sinal_esperado(sinal_esperado),
            .sinal_amostra(sinal_amostra),
            .timeout(timeout)
        );
        if (!timeout) begin
            monitorar_sinal(
                .sinal(sinal_tipo),
                .sinal_amostra(sinal_amostra),
                .sinal_estavel(sinal_estavel)
            );
            if (sinal_estavel)begin
                testes_passaram++;
                if (sinal_tipo == "reset") begin
                    $display("[PASSOU] RELEASE %0d - RESET %0d: Pulsos: %0d | LED: %b | Esperado: %b | SAIDA: %b | Esperado: %b",
                    release_teste, num_teste, pulsos, led, sinal_esperado, saida, sinal_esperado);
                end else begin
                    $display("[PASSOU] RELEASE %0d - Teste %0d: Pulsos: %0d | %s: %b | Esperado: %b",
                    release_teste, num_teste, pulsos, to_upper(sinal_tipo), sinal_amostra, sinal_esperado);
                end
            end else begin
                testes_falharam++;
                if (sinal_tipo == "reset") begin
                    $display("[FALHOU] RELEASE %0d - RESET %0d: Pulsos: %0d | LED: %b | Esperado: %b | SAIDA: %b | Esperado: %b",
                    release_teste, num_teste, pulsos, led, sinal_esperado, saida, sinal_esperado);
                end else begin
                    $display("[FALHOU] RELEASE %0d - Teste %0d: Pulsos: %0d | %s: %b | Esperado: %b | %s não permaneceu estável por %0d ciclos",
                    release_teste, num_teste, pulsos, to_upper(sinal_tipo), sinal_amostra, TEMPO_ESTAVEL, to_upper(sinal_tipo), TEMPO_ESTAVEL);
                end
            end
        end else begin
            testes_falharam++;
            if (sinal_tipo == "reset") begin
                $display("[FALHOU] RELEASE %0d - RESET %0d: Pulsos: %0d | LED: %b | Esperado: %b | SAIDA: %b | Esperado: %b",
                release_teste, num_teste, pulsos, led, sinal_esperado, saida, sinal_esperado);
            end else begin
                $display("[FALHOU] RELEASE %0d - Teste %0d: Pulsos: %0d | %s: %b | Esperado: %b | %s não atingiu estado esperado dentro de %0d ciclos",
                release_teste, num_teste, pulsos, to_upper(sinal_tipo), sinal_amostra, sinal_esperado, to_upper(sinal_tipo),TIMEOUT);
            end
        end;

        $display("%s", separador_minor);
        total_testes++;
        num_teste++;
        #5;
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
        @(posedge clk);

        validar_teste(
            .num_teste(num_teste),
            .pulsos(qnt_pulsos),
            .sinal_esperado(led_esperado),
            .release_teste(1),
            .sinal_tipo("led")
        );

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
                int valor = gen_release_1.proximo();
                teste_alternar_modos_release_1(valor);
            end
        end
    endtask

    // ============================================
    // RELEASE 2: Teste de controle manual
    // ============================================
    task automatic simular_teste_release_2(input int qnt_pulsos);
        logic lampada_esperado = (qnt_pulsos >= PULSOS_LIGAR_LAMPADA) ? 1'b1 : 1'b0;
        logic lampada_temp;
        static int num_teste = 1;

        bit saida_estavel;
        bit timeout;

        setarManual();

        pressionar_push_button(qnt_pulsos);

        validar_teste(
            .num_teste(num_teste),
            .pulsos(qnt_pulsos),
            .sinal_esperado(lampada_esperado),
            .release_teste(2),
            .sinal_tipo("saida")
        );

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
                int valor = gen_ignora.proximo();
                simular_teste_release_2(valor);
            end

            // Testes aleatórios - valores que devem ser aceitos
            gen_aceita = new(INTERVALO_MIN_ACEITA, INTERVALO_MAX_ACEITA);
            repeat(5) begin
                int valor = gen_aceita.proximo();
                simular_teste_release_2(valor);
            end
        end
    endtask

    // ============================================
    // RELEASE 3: Teste de sensor infravermelho
    // ============================================
    task executar_teste_pulso_longo_release_3;
        int num_teste;
        begin
            num_teste = 1;
            $display("Release 3 - Cenário 1: Pulso único de longa duração");
            setarAutomatico();
            
            simular_deteccao_infravermelho(DURACAO_PULSO_LONGO);

            repeat(TEMPO_ESPERA_EXTENSO) @(posedge clk);

            validar_teste(
                .num_teste(num_teste),
                .pulsos(DURACAO_PULSO_LONGO),
                .sinal_esperado(1'b0),
                .release_teste(3),
                .sinal_tipo("saida")
            );
        end
    endtask

    task executar_teste_estimulos_intermitentes_release_3;
        int num_teste;
        begin
            num_teste = 2;
            $display("Release 3 - Cenário 2: Simulação de movimentos intermitentes");
            setarAutomatico();

            for (int i = 0; i < QTD_REPETICOES_TESTE_R3; i++) begin
                int duracao_pulso_rand, intervalo_rand;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
                intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

                simular_deteccao_infravermelho(duracao_pulso_rand);
                repeat(intervalo_rand) @(posedge clk);
            end

            validar_teste(
                .num_teste(num_teste),
                .pulsos(QTD_REPETICOES_TESTE_R3),
                .sinal_esperado(1'b1),
                .release_teste(3),
                .sinal_tipo("saida")
            );
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
    task executar_teste_estimulos_intermitentes_release_4;
        int num_teste;
        begin
            num_teste = 1;

            for (int i = 0; i < QTD_REPETICOES_TESTE_R4; i++) begin
                int duracao_pulso_rand, intervalo_rand;

                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE, MIN_DURACAO_INTERMITENTE);
                intervalo_rand = $urandom_range(MAX_INTERVALO_INTERMITENTE, MIN_INTERVALO_INTERMITENTE);

                simular_deteccao_infravermelho(duracao_pulso_rand);

                validar_teste(
                    .num_teste(num_teste),
                    .pulsos(duracao_pulso_rand),
                    .sinal_esperado(saida), // Em modo manual, a lâmpada deve permanecer inalterada
                    .release_teste(4),
                    .sinal_tipo("saida")
                );

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
            executar_teste_estimulos_intermitentes_release_4();
        end
    endtask

    // ============================================
    // RELEASE 5: Teste de botão em modo manual
    // ============================================
    task executar_teste_estimulos_intermitentes_release_5;
        int num_teste;
        begin
            $display("Release 5 - Geração de 10 pulsos para o push button em modo manual");
            num_teste = 1;

            for (int i = 0; i < QTD_REPETICOES_TESTE_R5; i++) begin
                int duracao_pulso_rand;
                logic saida_anterior;

                saida_anterior = saida;
                duracao_pulso_rand = $urandom_range(MAX_DURACAO_INTERMITENTE_R5, MIN_DURACAO_INTERMITENTE_R5);

                pressionar_push_button(duracao_pulso_rand);

                validar_teste(
                    .num_teste(num_teste),
                    .pulsos(duracao_pulso_rand),
                    .sinal_esperado(~saida_anterior), // A saída deve alternar
                    .release_teste(5),
                    .sinal_tipo("saida")
                );
            end
        end
    endtask

    task automatic executar_testes_release_5;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 5: Botão em Modo Manual");
            $display("%s", separador);

            setarManual();
            
            executar_teste_estimulos_intermitentes_release_5();
        end
    endtask

    // ============================================
    // RELEASE 6: Teste de botão em modo automático
    // ============================================
    task automatic simular_teste_release_6(input int qnt_pulsos);
        static int num_teste = 1;

        setarAutomatico();
        pressionar_push_button(qnt_pulsos);

        validar_teste(
            .num_teste(num_teste),
            .pulsos(qnt_pulsos),
            .sinal_esperado(0),
            .release_teste(6),
            .sinal_tipo("saida")
        );

    endtask

    task automatic executar_testes_release_6;
        begin
            $display("%s", separador);
            $display("EXECUTANDO TESTES DA RELEASE 6: Botão em Modo Automático");
            $display("%s", separador);

            gen_release_6 = new(INTERVALO_MIN_RELEASE_6, INTERVALO_MAX_RELEASE_6);

            repeat(QNT_ALEATORIOS) begin
                int valor = gen_release_6.proximo();
                simular_teste_release_6(valor);
            end
        end
    endtask

    // ============================================
    // RELEASE 7: Teste de troca de modo após IR
    // ============================================
    task automatic acenderInfravermelho;
        int num_teste;
        begin
            num_teste = 1;
            simular_deteccao_infravermelho(5);
            
            validar_teste(
                .num_teste(num_teste),
                .pulsos(5),
                .sinal_esperado(1'b1),
                .release_teste(7),
                .sinal_tipo("saida")
            );
        end
    endtask

    task automatic trocarModo;
        int num_teste;
        begin
            num_teste = 2;
            pressionar_push_button(PULSOS_TROCAR_MODO + 10);

            validar_teste(
                .num_teste(num_teste),
                .pulsos(PULSOS_TROCAR_MODO + 10),
                .sinal_esperado(1'b1),
                .release_teste(7),
                .sinal_tipo("led")
            );
        end
    endtask

    task automatic simular_teste_release_7;
        begin
            setarAutomatico();
            acenderInfravermelho();
            trocarModo();
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

            // Inicia os processos paralelos
            gerador_troca_de_modo_release_8();
            gerador_estimulos_de_modo_release_8();
            gerador_de_resets_release_8();

            // Espera o sinal de que os resets foram concluídos
            @(teste_de_reset_concluido);
            #5;
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