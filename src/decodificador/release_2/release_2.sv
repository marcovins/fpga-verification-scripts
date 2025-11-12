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

    function automatic void shuffle16(ref logic [1:0] arr[16][2]);
        for (int i = 15; i > 0; i--) begin
            int j = $urandom_range(0, i);
            logic [1:0] tmp[2]; 
            
            tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
        end
    endfunction

    function automatic logic [3:0] decode(input logic [3:0] line, input logic [3:0] col_pressed);
        logic [3:0] value;

        case (line)
            4'b1110: begin
                case (col_pressed)
                    4'b1110: value = 4'h1;
                    4'b1101: value = 4'h2;
                    4'b1011: value = 4'h3;
                    4'b0111: value = 4'hA;
                endcase
            end
            4'b1101: begin
                case (col_pressed)
                    4'b1110: value = 4'h4;
                    4'b1101: value = 4'h5;
                    4'b1011: value = 4'h6;
                    4'b0111: value = 4'hB;
                endcase
            end
            4'b1011: begin 
                case (col_pressed)
                    4'b1110: value = 4'h7;
                    4'b1101: value = 4'h8;
                    4'b1011: value = 4'h9;
                    4'b0111: value = 4'hC;
                endcase
            end
            4'b0111: begin
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

    int num_test, pos, fail;

    logic [1:0] matrix [16][2];
    logic [1:0] lin, col;
    logic [3:0] cont_l, expected_row, result;

    initial begin
        reset();

        lin = 0;
        col = 0;

        cont_l = 1;
        for (int i = 0; i < 16; i++) begin

            matrix[i][0] = lin;
            matrix[i][1] = col;

            if (cont_l % 4 == 0) begin
                lin = lin + 1;
                col = 0;    
            end
            else
                col = col + 1;
            
            cont_l = cont_l + 1;
        end
        
        // Embaralhando a matriz
        shuffle16(matrix);

        for (int i = 0; i < 16; i++) begin
            fail = 1;
            
            expected_row = ~(4'b0001 << matrix[i][0]);

            wait (lin_matriz == expected_row);

            // Antes do debounce
            col_matriz = ~(4'b0001 << matrix[i][1]);
            $display("LINHA: %4b | COLUNA: %4b", lin_matriz, col_matriz);

            repeat(DEBOUNCE) @(posedge clk);

            // Depois do debounce
            repeat(10) begin
                @(posedge clk);
                result = decode(lin_matriz, col_matriz);

                if (tecla_valid && result == tecla_value) begin
                    fail = 0;
                    break;
                end
            end

            // Soltando a tecla
            col_matriz = 4'b1111;

            if (fail)
                $display("FALHOU");
            else
                $display("PASSOU");

            repeat(5) @(posedge clk);
        end

        $finish;
    end
endmodule