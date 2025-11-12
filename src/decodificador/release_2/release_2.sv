`timescale 1ns/1ns

module tb_teclado;
    // Sinais principais
    logic clk = 0, rst = 1;
    logic [3:0] col_matriz, lin_matriz, tecla_value;
    logic tecla_valid;

    always #1 clk = ~clk;

    localparam DEBOUNCE = 100;

    decodificador_de_teclado #(.DEBOUNCE_P(DEBOUNCE)) 
    dut (
        .clk(clk),
        .rst(rst),
        .col_matriz(col_matriz),
        .lin_matriz(lin_matriz),
        .tecla_value(tecla_value),
        .tecla_valid(tecla_valid)
    );

    task automatic reset();
        rst = 1;
        repeat(5) @(posedge clk);
        col_matriz = 4'b1111;
        rst = 0;
    endtask

    task automatic press_key(input logic [3:0] key, input int pulses);
        col_matriz = key;
        repeat(pulses) @(posedge clk);
        col_matriz = 4'b1111;
    endtask

    function automatic void shuffle16x2(ref logic [1:0] arr[16]);
        for (int i = 15; i > 0; i--) begin
            int j = $urandom_range(0, i);
            logic [1:0] tmp = arr[i];
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

    function automatic decode(logic [3:0] line, logic [3:0] col_pressed);
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

    const logic [3:0] col_patterns [4] = '{4'b1110, 4'b1101, 4'b1011, 4'b0111};
    const logic [3:0] row_patterns [4] = '{4'b0111, 4'b1011, 4'b1101, 4'b1110};

    logic [3:0] expected_value;
    logic found_event;
    logic [3:0] expected_row, pressed_col;
    int time_;

    initial begin
        reset();

        for (int row_idx = 0; row_idx < 4; row_idx++) begin
            for (int col_idx = 0; col_idx < 4; col_idx++) begin
                
                expected_row = row_patterns[row_idx];
                pressed_col = col_patterns[col_idx];

                wait (lin_matriz == expected_row);

                expected_value = decode(expected_row, pressed_col);

                // 3. Inicia o pressionamento da tecla em BACKGROUND
                fork
                    press_key(pressed_col, DEBOUNCE + 1);
                join_none

                found_event = 0;
                time_ = 0;

                repeat(DEBOUNCE + 20) @(posedge clk) begin
                    if (tecla_valid) begin
                        time_ = time_ + 1;
                        found_event = 1;

                        if (tecla_value == expected_value && time_ <= 110) begin
                            $display("[PASSOU] Teste (L: %0d, C: %0d)", row_idx, col_idx);
                        end else begin
                            $display("[FALHOU] Teste (L: %0d, C: %0d)", row_idx, col_idx);
                        end
                        break;
                    end
                end

                if (!found_event) begin
                    $display("[FALHOU] Teste (L: %0d, C: %0d)", row_idx, col_idx);
                end

                wait (col_matriz == 4'b1111);
                
                repeat(10) @(posedge clk);
                
            end
        end
        $finish;
    end
endmodule