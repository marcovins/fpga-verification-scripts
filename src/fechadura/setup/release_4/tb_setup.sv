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

    task automatic enter_setup();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
    endtask

    task send_digit(input logic [3:0] digit);
        digitos_value = digit;
        digitos_valid = 1'b1;
        @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);
    endtask

    task automatic verifificar_valor_salvo();
        if(bcd_pac.BCD5 == 4'd1 && bcd_pac.BCD0 == data_setup_new.bip_status) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD5, bcd_pac.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD5, bcd_pac.BCD0);
        end
    endtask

    task automatic validar_entrada(input logic [3:0] digit);
        send_digit(digit);
        @(posedge clk);
        if(bcd_pac.BCD5 == 4'd1 && bcd_pac.BCD0 == ((digit < 2)? digit : data_setup_new.bip_status)) begin
            $display("[%0t] PASSOU! Numero pressionado: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, digit, digitos_valid, bcd_pac.BCD5, bcd_pac.BCD0);
        end else begin
            $display("[%0t] FALHOU! Numero pressionado: %0d | tecla_valid: %0d | BCD5: %0d | BCD0 : %0d", $time, digit, digitos_valid, bcd_pac.BCD5, bcd_pac.BCD0);
        end
    endtask

    function automatic bit compare_configs(setupPac_t a, setupPac_t b);
    return
        (a.bip_time === b.bip_time) &&
        (a.tranca_aut_time === b.tranca_aut_time) &&
        (a.senha_master.digits === b.senha_master.digits) &&
        (a.senha_1.digits === b.senha_1.digits) &&
        (a.senha_2.digits === b.senha_2.digits) &&
        (a.senha_3.digits === b.senha_3.digits) &&
        (a.senha_4.digits === b.senha_4.digits);
    endfunction

    task automatic execute_tests_release_4();
        old_configs = data_setup_new;
        enter_setup();
        verifificar_valor_salvo();

        validar_entrada(4'b0001);
        validar_entrada(4'b0000);

        for (int i = 2; i < 10; i++) begin
            validar_entrada(i);
        end

        send_digit(4'hA);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
            end
            begin
                #1000;
                $display("Timeout esperando data_setup_ok!");
            end
        join_any
        disable fork;

        if(data_setup_new.bip_status === 4'b0000 && compare_configs(data_setup_new, old_configs)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end

    endtask

    initial begin
        clk = 0;
        rst = 0;
        setup_on = 0;
        digitos_value = '0;
        digitos_valid = 0;
        execute_tests_release_4();
        #100 $finish;
    end

endmodule
