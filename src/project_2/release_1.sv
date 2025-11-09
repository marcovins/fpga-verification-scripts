// Debounce das teclas

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

    function automatic void shuffle(ref logic [3:0] arr[4]);
        for (int i = 0; i < 4; i++) begin
            int j = $urandom_range(0, 3);
            logic [3:0] tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
        end
    endfunction

    logic [3:0] keys [4] = '{4'b1110, 4'b1101, 4'b1011, 4'b0111};
    int num_test;

    initial begin
        reset();
        shuffle(keys);

        // Percorrendo todas as teclas
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                wait (lin_matriz == keys[j]);

                press_key(keys[i], DEBOUNCE - 5);
                num_test = i + j + 1;

                repeat(5) @(posedge clk);

                if (tecla_valid)
                    $display("TESTE %0d.1 FALHOU!", num_test);
                else
                    $display("TESTE %0d.1 PASSOU!", num_test);

                wait (lin_matriz == keys[j]);

                press_key(keys[i], DEBOUNCE + 10);

                repeat(2) @(posedge clk);

                if (tecla_valid)
                    $display("TESTE %0d.2 PASSOU!", num_test);
                else
                    $display("TESTE %0d.2 FALHOU!", num_test);
            end
        end
        $finish;
    end
endmodule