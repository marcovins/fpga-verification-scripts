module tb_decodificador;

    logic clk = 0;
    logic rst = 0;
    logic [3:0] col_matriz;
    logic [3:0] lin_matriz;
    logic [3:0] tecla_value;
    logic tecla_valid;

    // Contador de ciclos
    logic [12:0] cont;

    parameter int METADE_PERIODO = 1; // 1 ns -> periodo total 2 ns
    parameter int HOLD_VALID = 120;
    parameter int INTERVALO_MIN = 0;
    parameter int INTERVALO_MAX = 9;

    always #METADE_PERIODO clk = ~clk;

    decodificador_de_teclado #(.DEBOUNCE_P(100)) dut (
        .clk(clk),
        .rst(rst),
        .col_matriz(col_matriz),
        .lin_matriz(lin_matriz),
        .tecla_value(tecla_value),
        .tecla_valid(tecla_valid)
    );

    class GeradorAleatorio;

        // randc garante que cada valor na faixa será sorteado uma vez antes de repetir
        randc bit [12:0] num; // bit [12:0] pode representar valores de 0 a 8191

        int min, max;

        function new(input int min, input int max); // Define o construtor
            this.min = min;
            this.max = max;
        endfunction

        // Define a faixa de valores válidos
        constraint range_c { num inside {[min:max]}; }
    endclass

    task automatic resetar; begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        end
    endtask

    task automatic send_key(input int number);
        begin
            case (number)
                0: begin
                    wait (lin_matriz == 4'b0111);
                    col_matriz = 4'b1101;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                1: begin
                    wait (lin_matriz == 4'b1110);
                    col_matriz = 4'b1110;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                2: begin
                    wait (lin_matriz == 4'b1110);
                    col_matriz = 4'b1101;
                    repeat (HOLD_VALID) @(posedge clk);

                end
                3: begin
                    wait (lin_matriz == 4'b1110);
                    col_matriz = 4'b1011;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                4: begin
                    wait (lin_matriz == 4'b1101);
                    col_matriz = 4'b1110;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                5: begin
                    wait (lin_matriz == 4'b1101);
                    col_matriz = 4'b1101;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                6: begin
                    wait (lin_matriz == 4'b1101);
                    col_matriz = 4'b1011;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                7: begin
                    wait (lin_matriz == 4'b1011);
                    col_matriz = 4'b1110;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                8: begin
                    wait (lin_matriz == 4'b1011);
                    col_matriz = 4'b1101;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                9: begin
                    wait (lin_matriz == 4'b1011);
                    col_matriz = 4'b1011;
                    repeat (HOLD_VALID) @(posedge clk);
                end
                default:
                    col_matriz = 4'b1111;
            endcase
            @(posedge clk);
            col_matriz = 4'b1111;
        end
    endtask

    task automatic teste_multiplas_teclas(int num1, int num2);
        begin
            fork
                begin
                    $display("TIME: %0t - Enviando tecla %0d", $time, num1);
                    send_key(num1);
                end
                begin
                    @(posedge clk);
                    $display("TIME: %0t - Enviando tecla %0d", $time, num2);
                    send_key(num2);
                end
            join_any;
        end
    endtask

    task automatic executar_teste_release_4(int num1, int num2);
        begin
            $display("Iniciando Teste Múltiplas Teclas - Release 4");

            resetar();
            $display("\n -- Teste Múltiplas Teclas -- ");
            teste_multiplas_teclas(gen_1.num, gen_2.num);
            if (tecla_valid && tecla_value == gen_1.num) begin
                $display("[%0t] PASSOU! tecla_value: %0d | tecla_valid: %0d | Numero pressionado: %0d",
                $time, tecla_value, tecla_valid, gen_1.num);
            end else begin
                $display("[[%0t] FALHOU! tecla_value: %0d | tecla_valid: %0d | Numero pressionado: %0d",
                $time, tecla_value, tecla_valid, gen_1.num);
            end

        end
    endtask

    GeradorAleatorio gen_1;
    GeradorAleatorio gen_2;

    initial begin
        gen_1 = new(INTERVALO_MIN, INTERVALO_MAX);
        gen_2 = new(INTERVALO_MIN, INTERVALO_MAX);

        gen_1.randomize();
        gen_2.randomize();
        executar_teste_release_4(gen_1.num, gen_2.num);
        #1000;
        $finish;
    end

endmodule