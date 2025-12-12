`timescale 1ns/1ns

module testbench_operacional;
    logic clk;
    logic rst;
    logic sensor_contato;
    logic botao_interno;
    logic botao_bloqueio;
    logic botao_config;
    setupPac_t data_setup_new;
    logic data_setup_ok;
    senhaPac_t digitos_value;
    logic digitos_valid;
    bcdPac_t bcd_pac;
    logic teclado_en;
    logic display_en;
    logic setup_on;
    logic tranca;
    logic bip;

    int num_teste;

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

    task automatic reset();
        rst = 1;
        repeat(5) @(posedge clk);
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

    task automatic execute_tests_release1();
        logic [3:0] senha1 [8] = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};

        for (int i = 0; i < 8; i++) begin
            // Inserção parcial da senha 1
            if (i == 5)
                break;

            send_digit(senha1[i]);
        end

        // Presionar ´#´
        send_digit(4'hB);

        repeat(2) @(posedge clk);

        num_teste = 1;
        print_teste(digitos_value.digits == '1, num_teste, "Valores não foram apagados");

        // Tentar enviar senha (*)
        send_digit(4'hA);
        
        @(posedge clk);

        num_teste = num_teste + 1;

        print_teste(tranca == 1, num_teste, "A senha foi considerada");
    endtask

    initial begin
        clk = 0;
        rst = 0;
        data_setup_ok = 0;
        digitos_value = '1;

        reset();
        @(posedge clk);
        data_setup_new.senha_1 = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, default: 4'hf};
        data_setup_ok = 1;
        @(posedge clk);
        data_setup_ok = 0;

        execute_tests_release1();

        #100 $finish;
    end

endmodule
