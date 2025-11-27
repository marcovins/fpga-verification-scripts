typedef struct packed {
	logic [3:0] BCD0;
    logic [3:0] BCD1;
    logic [3:0] BCD2;
    logic [3:0] BCD3;
    logic [3:0] BCD4;
    logic [3:0] BCD5;
} bcdPac_t;

typedef struct packed {
    logic [19:0] [3:0] digits;
} senhaPac_t;

typedef struct packed {
	logic bip_status;
	logic [5:0] bip_time;
	logic [5:0]  tranca_aut_time;
    senhaPac_t senha_master;
    senhaPac_t senha_1;
    senhaPac_t senha_2;
    senhaPac_t senha_3;
    senhaPac_t senha_4;
} setupPac_t;

module operacional(
    input		logic		clk,
	input		logic		rst,
	input		logic		sensor_contato,
	input		logic		botao_interno,
	input		logic		botao_bloqueio,
	input		logic		botao_config,
    input		setupPac_t 	data_setup_new,
	input		logic		data_setup_ok,
	input		senhaPac_t	digitos_value,
	input		logic		digitos_valid,
	output		bcdPac_t	bcd_pac,
	output 	    logic 		teclado_en,
	output		logic		display_en,
	output		logic		setup_on,
    output		logic		tranca,
	output		logic		bip
);
endmodule
