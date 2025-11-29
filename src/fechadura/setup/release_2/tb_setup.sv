`timescale 1ns/1ns

module testbench_setup;
    logic clk;
    logic rst;
    logic setup_on;
    senhaPac_t digitos_value;
    logic digitos_valid;
    logic display_en;
    bcdPac_t bcd_pac;
    setupPac_t data_setup_new;
    setupPac_t old_configs;
    logic data_setup_ok;

    always #1 clk = ~clk;

    setup dut (
        .clk(clk),
        .rst(rst),
        .setup_on(setup_on),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .display_en(display_en),
        .bcd_pac(bcd_pac),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok)
    );

    task automatic reset();
        rst = 1;
        repeat(5000) @(posedge clk);
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

    task automatic enter_setup();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
    endtask

    task automatic print_teste(input bit condicao, input int num_teste, input string msg_erro);
        if (condicao)
            $display("Teste %0i: PASSOU!", num_teste);
        else
            $display("Teste %0i: FALHOU! %s", num_teste, msg_erro);
    endtask

    task automatic execute_tests_release_2();
        // Reset
        reset();

        // Guardando as configurações inicial do setup
        old_configs = data_setup_new;

        // 1. Entrar no setup (setup_on = 1)
        enter_setup();

        // Inserir master
        send_digit(4'h1);
        send_digit(4'h2);
        send_digit(4'h3);
        send_digit(4'h4);
        send_digit(4'hA);

        int num_teste = 1;

        print_teste(bcd_pac.BCD5 == 1, num_teste, "BCD5 = 0");

        // 2. Enviar tecla '*' até chegar na configuração 8
        for (int i = 1; i < 9; i++) begin
            num_teste = num_teste + 1;

            @(posedge clk);
            
            print_teste(bcd_pac.BCD5 == i, num_teste, "BCD5 diferente do valor esperado");
            send_digit(4'hA);
        end

        // Enviar '*'
        send_digit(4'hA);
        
        @(posedge clk);

        num_teste = num_teste + 1;

        // Verificar sem nenhum valor do setup foi alterado
        print_teste(old_configs == data_setup_new, num_teste, "Valor alterado no setup");

        num_teste = num_teste + 1;

        // Verificar se voltou para o modo operacional
        print_teste(display_en == 0, num_teste, "Permaneceu no Setup");

    endtask

    initial begin
        clk = 0;
        rst = 0;
        digitos_value.digits = '1;
        digitos_valid = 0;
        execute_tests_release_2();

        #100 $finish;
    end

endmodule
