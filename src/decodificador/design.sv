module decodificador_de_teclado #(
    parameter DEBOUNCE_P = 100)
  
   (input logic clk,
    input logic rst,
    input logic [3:0] col_matriz,
    output logic [3:0] lin_matriz,
    output logic [3:0] tecla_value,
    output logic tecla_valid);
	
	
	bit[6:0] Tp;
	enum logic [4:0] {ESPERANDO, DEBOUNCE, DECOD, SAIDA, VALID} Estado;
	
  	bit[3:0] lin, col_apertada;
	logic [3:0] value;
	
	always_ff @ (posedge clk or posedge rst) begin
		if (rst == 1) begin
			Estado <= ESPERANDO;
			lin <= 0;
			Tp <= 0;
		end
		else
			case(Estado)
				ESPERANDO: begin
					Tp <= 0;
                    if(col_matriz != 4'b1111) begin
                          col_apertada = col_matriz;
                          Estado <= DEBOUNCE;
                    end else
                  		lin <= (lin + 1) % 4;
				end
				DEBOUNCE: begin
					Tp <= Tp + 1;
					if(Tp >= DEBOUNCE_P)
						Estado <= DECOD;
					else if(col_matriz == 4'b1111)
						Estado <= ESPERANDO;
				end
				DECOD: begin
                  	if(col_matriz == 4'b1111)
						Estado <= ESPERANDO;
                    else begin
						case (lin)
							0: begin
								case (col_apertada)
								    4'b1110: value <= 4'h1;
								    4'b1101: value <= 4'h2;
								    4'b1011: value <= 4'h3;
								    4'b0111: value <= 4'hA;
								endcase
							end
							1: begin
								case (col_apertada)
								    4'b1110: value <= 4'h4;
								    4'b1101: value <= 4'h5;
								    4'b1011: value <= 4'h6;
								    4'b0111: value <= 4'hB;
								endcase
							end
							2: begin 
								case (col_apertada)
								    4'b1110: value <= 4'h7;
								    4'b1101: value <= 4'h8;
								    4'b1011: value <= 4'h9;
								    4'b0111: value <= 4'hC;
								endcase
							end
							3: begin
								case (col_apertada)
								    4'b1110: value <= 4'hF;
								    4'b1101: value <= 4'h0;
								    4'b1011: value <= 4'hE;
								    4'b0111: value <= 4'hD;
								endcase
							end
							default: value <= 4'hF;
						endcase
						Estado <= SAIDA;
					end
				end
				SAIDA: begin
					if(col_matriz == 4'b1111)
						Estado <= ESPERANDO;
                  	else
						Estado <= VALID; 
				end
				VALID: begin
					if(col_matriz == 4'b1111)
						Estado <= ESPERANDO;	
				end
				default: Estado <= ESPERANDO;
			endcase
	end
	
	always_comb begin
		if(rst) begin
			lin_matriz = 4'b1110;
			tecla_value = 4'hF;
			tecla_valid = 0;
		end
		else
			case(Estado) 
				ESPERANDO:begin
                  tecla_value = 4'hF;
                  tecla_valid = 0;
					if(lin == 0)
						lin_matriz = 4'b1110;
					else if(lin == 1)
						lin_matriz = 4'b1101;
					else if(lin == 2)
						lin_matriz = 4'b1011;
					else if(lin == 3)
						lin_matriz = 4'b0111;		
				end
				DEBOUNCE: begin
					tecla_value = 4'hF;
					tecla_valid = 0;
				end
				DECOD: begin
					tecla_value = 4'hF;
					tecla_valid = 0;
				end
				SAIDA: begin
					tecla_value = value;
					tecla_valid = 0;
				end
				VALID: begin
					tecla_value = value;
					tecla_valid = 1;
				end
				default: begin
					lin_matriz = 4'b1110;
					tecla_value = 4'hF;
					tecla_valid = 0;
				end
			endcase
	end

endmodule
