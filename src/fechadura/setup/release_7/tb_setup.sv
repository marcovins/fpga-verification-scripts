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
    senhaPac_t saved_senha_master;
    senhaPac_t saved_senha_1;
    senhaPac_t saved_senha_2;
    senhaPac_t saved_senha_3;
    senhaPac_t saved_senha_4;

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

    // ====================================================
    // Classe geradora (mantive igual)
    // ====================================================
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

    // ----------------------------------------------------
    // Handles para os geradores — instancio em runtime
    // ----------------------------------------------------
    GeradorAleatorio gen_descarta;
    GeradorAleatorio gen_14;
    GeradorAleatorio gen_qtd;
    GeradorAleatorio gen_between_4_12;

    // qtd_nova será definido em runtime (não pode ser localparam obtido por proximo() em declaração)
    int qtd_nova;

    // Arrays com tamanho fixo máximo (12). Usaremos apenas os primeiros qtd_nova posições quando aplicável.
    int gerados_qtd[12] = '{default: 4'hF};
    int gerados[12]     = '{default: 4'hF};

    // ====================================================
    // Tasks / functions
    // ====================================================
    task automatic enter_setup(int steps);
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        repeat(steps) begin
            send_digit(4'hA);
            @(posedge clk);
        end
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

    task automatic verificar_deslocamento(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        if (bcd_pac.BCD1 == expected_BCD1 && bcd_pac.BCD0 == expected_BCD0) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD1, bcd_pac.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD1, bcd_pac.BCD0);
        end
    endtask

    task automatic verificar_bcd(logic [4:0] expected_BCD5);
        if (bcd_pac.BCD5 == expected_BCD5) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente. BCD5: %0d", $time, bcd_pac.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente. BCD5: %0d", $time, bcd_pac.BCD5);
        end
    endtask

    function automatic bit compare_configs(
        setupPac_t a,
        senhaPac_t expected_senha_1,
        senhaPac_t expected_senha_2,
        senhaPac_t expected_senha_3,
        senhaPac_t expected_senha_4,
        senhaPac_t expected_senha_master
    );
        return
            (a.senha_master.digits === expected_senha_master.digits) &&
            (a.senha_1.digits    === expected_senha_1.digits) &&
            (a.senha_2.digits    === expected_senha_2.digits) &&
            (a.senha_3.digits    === expected_senha_3.digits) &&
            (a.senha_4.digits    === expected_senha_4.digits);
    endfunction

    task automatic return_to_operational(
        senhaPac_t expected_senha_1,
        senhaPac_t expected_senha_2,
        senhaPac_t expected_senha_3,
        senhaPac_t expected_senha_4,
        senhaPac_t expected_senha_master
    );
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                $display("[%0t] PASSOU! retornou ao operacional com sucesso.", $time);
            end
            begin
                #1000;
                $display("[%0t] FALHOU! nao retornou ao operacional em tempo.", $time);
            end
        join_any
        disable fork;

        if (compare_configs(data_setup_new, expected_senha_1, expected_senha_2, expected_senha_3, expected_senha_4, expected_senha_master)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end
    endtask

    task automatic test_limits(logic [4:0] input_value, logic [4:0] expected_value);
        send_digit(input_value[3:0]);
        send_digit({1'b0, input_value[4]});
        send_digit(4'hA);
        @(posedge clk);

        if (data_setup_new.tranca_aut_time === expected_value) begin
            $display("[%0t] PASSOU! Limite testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end else begin
            $display("[%0t] FALHOU! Limite nao testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end
    endtask

    task automatic verificar_descarte(senhaPac_t senha, senhaPac_t senha_old);
        if (senha.digits === senha_old.digits) begin
            $display("[%0t] PASSOU! Senha nao foi alterada apos entrada incompleta.", $time);
        end else begin
            $display("[%0t] FALHOU! Senha foi alterada apos entrada incompleta.", $time);
        end
    endtask

    task automatic validar_senha(senhaPac_t senha, int gerados_in[]);
        // Assume que gerados_in tem tamanho suficiente; comparar pelo campo digits
        if (senha.digits === {gerados_in[0], gerados_in[1], gerados_in[2], gerados_in[3],
                              gerados_in[4], gerados_in[5], gerados_in[6], gerados_in[7],
                              gerados_in[8], gerados_in[9], gerados_in[10], gerados_in[11]}) begin
            $display("[%0t] PASSOU! Senha alterada corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Senha nao alterada corretamente.", $time);
        end
    endtask

    function automatic senhaPac_t get_senha_by_index(setupPac_t cfg, int idx);
        case (idx)
            0: return cfg.senha_1;
            1: return cfg.senha_2;
            2: return cfg.senha_3;
            3: return cfg.senha_4;
            4: return cfg.senha_master;
            default: return '0;
        endcase
    endfunction

    // ====================================================
    // Tarefa principal de testes (corrigida para instanciar geradores em runtime)
    // ====================================================
    task automatic executar_testes_release_7();
        old_configs = data_setup_new;

        for (int i = 0; i < 5; i++) begin
            // determinar qtd_nova dinamicamente neste ponto
            gen_qtd = new(4, 12);
            qtd_nova = gen_qtd.proximo(); // qtd entre 4 e 12

            enter_setup(3 + i);

            // 1) teste de descarte (3 dígitos) + "*" (4'hA)
            gen_descarta = new(0, 9);
            repeat (3) begin
                int valor = gen_descarta.proximo();
                send_digit(valor[3:0]);
            end
            send_digit(4'hA);  // Enviar "*" após os 3 dígitos
            verificar_descarte(get_senha_by_index(data_setup_new, i), get_senha_by_index(old_configs, i));

            // 2) gerar 14 dígitos, capturar últimos 12
            gen_14 = new(0, 9);
            // zera gerados antes de preencher (opcional)
            for (int z = 0; z < 12; z++) gerados[z] = 4'hF;

            for (int j = 0; j < 14; j++) begin
                int valor = gen_14.proximo();
                if (j >= 2)  // Capturar os últimos 12 dígitos (índices 2 a 13)
                    gerados[j - 2] = valor;
                send_digit(valor[3:0]);
            end

            send_digit(4'hA);
            validar_senha(get_senha_by_index(data_setup_new, i), gerados);

            // 3) gerar qtd_nova dígitos (entre 4 e 12)
            gen_between_4_12 = new(0, 9);  // usamos 0..9 para cada dígito válido
            // inicializa vetor de qtd com default
            for (int z = 0; z < 12; z++) gerados_qtd[z] = 4'hF;

            for (int k = 0; k < qtd_nova; k++) begin
                int valor = gen_between_4_12.proximo();
                gerados_qtd[k] = valor;
                send_digit(valor[3:0]);
            end
            send_digit(4'hA);
            // Passa o vetor completo (função compara concatenando os 12 valores)
            validar_senha(get_senha_by_index(data_setup_new, i), gerados_qtd);

            // salvar senhas para uso posterior
            saved_senha_1 = data_setup_new.senha_1;
            saved_senha_2 = data_setup_new.senha_2;
            saved_senha_3 = data_setup_new.senha_3;
            saved_senha_4 = data_setup_new.senha_4;
            saved_senha_master = data_setup_new.senha_master;

        end // for i

        // 4) retornar ao operacional e verificar configurações salvas
        return_to_operational(saved_senha_1, saved_senha_2, saved_senha_3, saved_senha_4, saved_senha_master);

    endtask

    // ====================================================
    // Inicialização
    // ====================================================
    initial begin
        clk = 0;
        rst = 0;
        setup_on = 0;
        digitos_value = '0;
        digitos_valid = 0;

        executar_testes_release_7();
        #100 $finish;
    end

endmodule
