`timescale 1ns/1ns

module tb_completo;
    
    // ========================================
    // Sinais principais
    // ========================================
    logic clk = 0, rst = 1;
    logic [3:0] col_matriz, lin_matriz, tecla_value;
    logic tecla_valid;
    
    // Parâmetros de teste
    localparam DEBOUNCE = 100;
    localparam METADE_PERIODO = 1; // 1 ns -> período total 2 ns
    localparam HOLD_VALID = 120;
    localparam INTERVALO_MIN = 0;
    localparam INTERVALO_MAX = 9;
    
    // Clock generation
    always #METADE_PERIODO clk = ~clk;
    
    // Instanciação do DUT
    decodificador_de_teclado #(.DEBOUNCE_P(DEBOUNCE)) 
    dut (
        .clk(clk),
        .rst(rst),
        .col_matriz(col_matriz),
        .lin_matriz(lin_matriz),
        .tecla_value(tecla_value),
        .tecla_valid(tecla_valid)
    );
    
    // ========================================
    // Classes auxiliares
    // ========================================
    class GeradorAleatorio;
        randc bit [12:0] num; // bit [12:0] pode representar valores de 0 a 8191
        int min, max;
        
        function new(input int min, input int max);
            this.min = min;
            this.max = max;
        endfunction
        
        constraint range_c { num inside {[min:max]}; }
    endclass
    
    // ========================================
    // Variáveis globais para as tasks
    // ========================================
    logic [3:0] keys [4];
    logic [3:0] col_patterns [4];
    logic [3:0] row_patterns [4];
    int num_test;
    int time_count;
    logic [3:0] expected_value;
    logic found_event;
    logic [3:0] expected_row, pressed_col;
    bit finished_first;
    logic [3:0] first_key_value;
    GeradorAleatorio gen_num, gen_cycles, gen_1, gen_2;
    
    // ========================================
    // Tasks auxiliares
    // ========================================
    task automatic reset();
        $display("[%0t] INFO: Aplicando reset do sistema", $time);
        rst = 1;
        repeat(5) @(posedge clk);
        col_matriz = 4'b1111;
        rst = 0;
        $display("[%0t] INFO: Reset aplicado com sucesso", $time);
    endtask
    
    task automatic press_key(input logic [3:0] key, input int pulses);
        col_matriz = key;
        repeat(pulses) @(posedge clk);
        col_matriz = 4'b1111;
    endtask
    
    task automatic press_key_extended(input int number, input int hold_time);
        case (number)
            0: begin
                wait (lin_matriz == 4'b0111);
                col_matriz = 4'b1101;
                repeat (hold_time) @(posedge clk);
            end
            1: begin
                wait (lin_matriz == 4'b1110);
                col_matriz = 4'b1110;
                repeat (hold_time) @(posedge clk);
            end
            2: begin
                wait (lin_matriz == 4'b1110);
                col_matriz = 4'b1101;
                repeat (hold_time) @(posedge clk);
            end
            3: begin
                wait (lin_matriz == 4'b1110);
                col_matriz = 4'b1011;
                repeat (hold_time) @(posedge clk);
            end
            4: begin
                wait (lin_matriz == 4'b1101);
                col_matriz = 4'b1110;
                repeat (hold_time) @(posedge clk);
            end
            5: begin
                wait (lin_matriz == 4'b1101);
                col_matriz = 4'b1101;
                repeat (hold_time) @(posedge clk);
            end
            6: begin
                wait (lin_matriz == 4'b1101);
                col_matriz = 4'b1011;
                repeat (hold_time) @(posedge clk);
            end
            7: begin
                wait (lin_matriz == 4'b1011);
                col_matriz = 4'b1110;
                repeat (hold_time) @(posedge clk);
            end
            8: begin
                wait (lin_matriz == 4'b1011);
                col_matriz = 4'b1101;
                repeat (hold_time) @(posedge clk);
            end
            9: begin
                wait (lin_matriz == 4'b1011);
                col_matriz = 4'b1011;
                repeat (hold_time) @(posedge clk);
            end
            default:
                col_matriz = 4'b1111;
        endcase
        @(posedge clk);
        col_matriz = 4'b1111;
    endtask
    
    function automatic void shuffle(ref logic [3:0] arr[4]);
        for (int i = 0; i < 4; i++) begin
            int j = $urandom_range(0, 3);
            logic [3:0] tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
        end
    endfunction
    
    function automatic logic [1:0] decode_line(input logic [3:0] row);
        logic [1:0] encode_custom;
        case (row)
            4'b0111: encode_custom = 2'b00;
            4'b1011: encode_custom = 2'b01;
            4'b1101: encode_custom = 2'b10;
            4'b1110: encode_custom = 2'b11;
            default: encode_custom = 2'bxx;
        endcase
        return encode_custom;
    endfunction
    
    function automatic logic [3:0] decode_key_value(logic [3:0] line, logic [3:0] col_pressed);
        logic [3:0] value;
        logic [1:0] dec_line = decode_line(line);
        
        case (dec_line)
            0: begin
                case (col_pressed)
                    4'b1110: value = 4'h1;
                    4'b1101: value = 4'h2;
                    4'b1011: value = 4'h3;
                    4'b0111: value = 4'hA;
                endcase
            end
            1: begin
                case (col_pressed)
                    4'b1110: value = 4'h4;
                    4'b1101: value = 4'h5;
                    4'b1011: value = 4'h6;
                    4'b0111: value = 4'hB;
                endcase
            end
            2: begin
                case (col_pressed)
                    4'b1110: value = 4'h7;
                    4'b1101: value = 4'h8;
                    4'b1011: value = 4'h9;
                    4'b0111: value = 4'hC;
                endcase
            end
            3: begin
                case (col_pressed)
                    4'b1110: value = 4'hF;
                    4'b1101: value = 4'h0;
                    4'b1011: value = 4'hE;
                    4'b0111: value = 4'hD;
                endcase
            end
        endcase
        
        return value;
    endfunction
    
    // ========================================
    // RELEASE 1: Teste de Debounce
    // ========================================
    task automatic teste_release_1();
        $display("\n========================================");
        $display("INICIANDO RELEASE 1: TESTE DE DEBOUNCE");
        $display("========================================");
        
        // Inicializar array de teclas
        keys[0] = 4'b1110;
        keys[1] = 4'b1101;
        keys[2] = 4'b1011;
        keys[3] = 4'b0111;
        
        reset();
        shuffle(keys);
        
        // Percorrendo todas as teclas
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                wait (lin_matriz == keys[j]);
                
                // Teste com tempo insuficiente (deve falhar)
                press_key(keys[i], DEBOUNCE - 5);
                num_test = i * 4 + j + 1;
                
                repeat(5) @(posedge clk);
                
                if (tecla_valid)
                    $display("[%0t] FALHOU: R1.T%0d.1 - Debounce insuficiente gerou tecla_valid", $time, num_test);
                else
                    $display("[%0t] PASSOU: R1.T%0d.1 - Debounce insuficiente não gerou tecla_valid", $time, num_test);
                
                wait (lin_matriz == keys[j]);
                
                // Teste com tempo suficiente (deve passar)
                press_key(keys[i], DEBOUNCE + 10);
                
                repeat(2) @(posedge clk);
                
                if (tecla_valid)
                    $display("[%0t] PASSOU: R1.T%0d.2 - Debounce suficiente gerou tecla_valid", $time, num_test);
                else
                    $display("[%0t] FALHOU: R1.T%0d.2 - Debounce suficiente não gerou tecla_valid", $time, num_test);
            end
        end
        
        $display("[%0t] INFO: RELEASE 1 concluída", $time);
    endtask
    
    // ========================================
    // RELEASE 2: Teste de Decodificação
    // ========================================
    task automatic teste_release_2();
        $display("\n========================================");
        $display("INICIANDO RELEASE 2: TESTE DE DECODIFICAÇÃO");
        $display("========================================");
        
        // Inicializar arrays de padrões
        col_patterns[0] = 4'b1110;
        col_patterns[1] = 4'b1101;
        col_patterns[2] = 4'b1011;
        col_patterns[3] = 4'b0111;
        
        row_patterns[0] = 4'b0111;
        row_patterns[1] = 4'b1011;
        row_patterns[2] = 4'b1101;
        row_patterns[3] = 4'b1110;
        
        reset();
        
        for (int row_idx = 0; row_idx < 4; row_idx++) begin
            for (int col_idx = 0; col_idx < 4; col_idx++) begin
                
                expected_row = row_patterns[row_idx];
                pressed_col = col_patterns[col_idx];
                
                wait (lin_matriz == expected_row);
                
                expected_value = decode_key_value(expected_row, pressed_col);
                
                // Inicia o pressionamento da tecla em background
                fork
                    press_key(pressed_col, DEBOUNCE + 1);
                join_none
                
                found_event = 0;
                time_count = 0;
                
                repeat(DEBOUNCE + 20) @(posedge clk) begin
                    if (tecla_valid) begin
                        time_count = time_count + 1;
                        found_event = 1;
                        
                        if (tecla_value == expected_value && time_count <= 110) begin
                            $display("[%0t] PASSOU: R2.T%0d.%0d - Tecla (L:%0d,C:%0d) = 0x%X (esperado: 0x%X)", 
                                    $time, row_idx+1, col_idx+1, row_idx, col_idx, tecla_value, expected_value);
                        end else begin
                            $display("[%0t] FALHOU: R2.T%0d.%0d - Tecla (L:%0d,C:%0d) = 0x%X (esperado: 0x%X)", 
                                    $time, row_idx+1, col_idx+1, row_idx, col_idx, tecla_value, expected_value);
                        end
                        break;
                    end
                end
                
                if (!found_event) begin
                    $display("[%0t] FALHOU: R2.T%0d.%0d - Tecla (L:%0d,C:%0d) não gerou evento válido", 
                            $time, row_idx+1, col_idx+1, row_idx, col_idx);
                end
                
                wait (col_matriz == 4'b1111);
                repeat(10) @(posedge clk);
            end
        end
        
        $display("[%0t] INFO: RELEASE 2 concluída", $time);
    endtask
    
    // ========================================
    // RELEASE 3: Teste de Reset Durante Operação
    // ========================================
    task automatic verificar_reset(input bit running);
        if (running) begin
            $display("[%0t] INFO: Aplicando reset durante operação", $time);
            rst = 1;
            @(posedge clk);
            rst = 0;
            @(posedge clk);
            if (tecla_valid == 1'b0) begin
                if (tecla_value == 4'hF) begin
                    if (lin_matriz == 4'b1110) begin
                        $display("[%0t] PASSOU: R3 - Reset durante operação: sinais resetados corretamente", $time);
                    end else begin
                        $display("[%0t] FALHOU: R3 - Reset durante operação: lin_matriz não está no estado inicial", $time);
                    end
                end else begin
                    $display("[%0t] FALHOU: R3 - Reset durante operação: tecla_value não está no estado inicial", $time);
                end
            end else begin
                $display("[%0t] FALHOU: R3 - Reset durante operação: tecla_valid ainda está alta", $time);
            end
        end
    endtask
    
    task automatic teste_pressionar_com_reset(int num1, int wait_cycles, int test_num);
        bit running = 1;
        fork
            begin
                $display("[%0t] INFO: R3.T%0d - Enviando tecla %0d", $time, test_num, num1);
                press_key_extended(num1, HOLD_VALID);
                running = 0;
            end
            begin
                repeat (wait_cycles) @(posedge clk);
                verificar_reset(running);
            end
        join_any;
    endtask
    
    task automatic teste_release_3();
        $display("\n========================================");
        $display("INICIANDO RELEASE 3: TESTE DE RESET DURANTE OPERAÇÃO");
        $display("========================================");
        
        // Inicializar geradores aleatórios
        gen_num = new(INTERVALO_MIN, INTERVALO_MAX);
        gen_cycles = new(1, 120);
        
        reset();
        
        for (int i = 0; i < 10; i++) begin
            $display("\n[%0t] --- Iniciando Teste R3.%0d ---", $time, i+1);
            gen_num.randomize();
            gen_cycles.randomize();
            teste_pressionar_com_reset(gen_num.num, gen_cycles.num, i+1);
            repeat(10) @(posedge clk);
        end
        
        $display("[%0t] INFO: RELEASE 3 concluída", $time);
    endtask
    
    // ========================================
    // RELEASE 4: Teste de Múltiplas Teclas
    // ========================================
    task automatic teste_multiplas_teclas(int num1, int num2, int test_num);
        
        // Inicializar variável local
        finished_first = 0;
        
        fork
            begin
                $display("[%0t] INFO: R4.T%0d - Enviando tecla %0d (primeira)", $time, test_num, num1);
                press_key_extended(num1, HOLD_VALID);
                finished_first = 1;
            end
            begin
                @(posedge clk);
                $display("[%0t] INFO: R4.T%0d - Enviando tecla %0d (segunda)", $time, test_num, num2);
                press_key_extended(num2, HOLD_VALID);
            end
        join_any;
        
        // Verifica se o primeiro sinal foi detectado corretamente
        repeat(5) @(posedge clk);
        if (tecla_valid && finished_first) begin
            $display("[%0t] PASSOU: R4.T%0d - Múltiplas teclas: primeira tecla (%0d) detectada corretamente (valor=0x%X)", 
                    $time, test_num, num1, tecla_value);
        end else begin
            $display("[%0t] FALHOU: R4.T%0d - Múltiplas teclas: primeira tecla (%0d) não foi detectada corretamente", 
                    $time, test_num, num1);
        end
    endtask
    
    task automatic teste_release_4();
        $display("\n========================================");
        $display("INICIANDO RELEASE 4: TESTE DE MÚLTIPLAS TECLAS");
        $display("========================================");
        
        // Inicializar geradores aleatórios
        gen_1 = new(INTERVALO_MIN, INTERVALO_MAX);
        gen_2 = new(INTERVALO_MIN, INTERVALO_MAX);
        
        reset();
        
        for (int i = 0; i < 5; i++) begin
            $display("\n[%0t] --- Iniciando Teste R4.%0d ---", $time, i+1);
            gen_1.randomize();
            gen_2.randomize();
            teste_multiplas_teclas(gen_1.num, gen_2.num, i+1);
            repeat(20) @(posedge clk);
        end
        
        $display("[%0t] INFO: RELEASE 4 concluída", $time);
    endtask
    
    // ========================================
    // Sequência principal de testes
    // ========================================
    initial begin
        $display("========================================");
        $display("INICIANDO TESTBENCH COMPLETO - DECODIFICADOR DE TECLADO");
        $display("Data/Hora: %0t", $time);
        $display("Parâmetros: DEBOUNCE=%0d, HOLD_VALID=%0d", DEBOUNCE, HOLD_VALID);
        $display("========================================");
        
        // Executar todos os testes em sequência
        teste_release_1();
        teste_release_2();
        teste_release_3();
        teste_release_4();
        
        $display("\n========================================");
        $display("TESTBENCH COMPLETO FINALIZADO");
        $display("Tempo total: %0t", $time);
        $display("========================================");
        
        #1000;
        $finish;
    end
    
endmodule