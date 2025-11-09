`timescale 1ns/1ps

module tb;

    // --- Sinais de Interface ---
    logic clk = 0;
    logic rst;
    logic push_button;
    logic infravermelho;
    logic led;
    logic saida;

    // Evento para controlar o fim da simulação
    event teste_de_reset_concluido;

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

    // --- Tarefas Genéricas de Estímulo ---

    task initial_reset;
        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        $display("[%0t ns] INFO: Sistema resetado no início da simulação.", $time);
    endtask

    task automatic simular_pulso_botao(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] STIMULUS: Gerando pulso no PUSH_BUTTON por %0d ciclos.", $time, duracao);
        push_button = 1'b1;
        repeat(duracao) @(posedge clk);
        push_button = 1'b0;
    endtask

    task automatic simular_pulso_ir(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] STIMULUS: Gerando pulso no INFRAVERMELHO por %0d ciclos.", $time, duracao);
        infravermelho = 1'b1;
        repeat(duracao) @(posedge clk);
        infravermelho = 1'b0;
    endtask

    task automatic simular_pulso_reset(input int min_ciclos, max_ciclos);
        int duracao = $urandom_range(max_ciclos, min_ciclos);
        $display("[%0t ns] **** RESET EVENT: Acionando RESET por %0d ciclos ****", $time, duracao);
        rst = 1'b1;
        repeat(duracao) @(posedge clk);
        rst = 1'b0;
        @(posedge clk); // Garante que o DUT processe o fim do reset
        
        // Verificação imediata após o reset
        if (led == 0 && saida == 0) begin
            $display("[%0t ns] CHECK: Reset bem-sucedido! Sistema voltou ao estado de fábrica (Led=0, Saida=0). PASSOU!", $time);
        end else begin
            $display("[%0t ns] CHECK: Falha no reset! Estado incorreto (Led=%b, Saida=%b). FALHOU!", $time, led, saida);
        end
    endtask

    // --- Lógica Principal do Teste ---
    initial begin
        // 1. Inicializa todos os sinais de entrada
        push_button = 1'b0;
        infravermelho = 1'b0;
        rst = 1'b0;

        // 2. Aplica um reset inicial para garantir um estado conhecido
        initial_reset();
        
        $display("\n[%0t ns] INFO: Iniciando simulação concorrente de reset...", $time);

        // 3. Usa fork...join_none para iniciar os processos paralelos
        fork
            gerador_troca_de_modo();
            gerador_estimulos_de_modo();
            gerador_de_resets();
        join_none

        // 4. Espera o sinal de que os 10 resets foram concluídos
        @(teste_de_reset_concluido);

        $display("\n[%0t ns] INFO: Teste de 10 resets concluído. Finalizando a simulação.", $time);
        $finish;
    end
    
    // --- Definição dos Processos Paralelos ---

    // Processo 1: Gera pulsos longos para alternar entre modo manual/automático
    task automatic gerador_troca_de_modo;
        forever begin
            int intervalo = $urandom_range(8000, 2000); // Intervalo aleatório entre tentativas
            repeat(intervalo) @(posedge clk);
            simular_pulso_botao(5300, 5830);
        end
    endtask

    // Processo 2: Gera estímulos de acionamento (curtos no botão ou no IR)
    task automatic gerador_estimulos_de_modo;
        forever begin
            int intervalo = $urandom_range(4000, 500);
            repeat(intervalo) @(posedge clk);
            
            // Verifica o modo atual pelo LED
            if (led == 1) begin // Modo Manual
                simular_pulso_botao(300, 5299);
            end else begin // Modo Automático
                simular_pulso_ir(1, 30000);
            end
        end
    endtask

    // Processo 3: Gera 10 pulsos de reset e sinaliza o fim
    task automatic gerador_de_resets;
        repeat (10) begin
            // Intervalo aleatório ENTRE os resets
            int intervalo_reset = $urandom_range(10600, 5300);
            repeat(intervalo_reset) @(posedge clk);
            
            // Duração aleatória DO pulso de reset (conforme especificação > 300)
            simular_pulso_reset(301, 1000);
        end
        $display("[%0t ns] INFO: Gerador de resets completou 10 acionamentos.", $time);
        
        // Dispara o evento para sinalizar o fim da simulação
        ->teste_de_reset_concluido;
    endtask

endmodule