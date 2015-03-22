`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Dept. Architecture and Computing Technology. University of Seville
// Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
// 
// Create Date:    19:13:39 4-Apr-2012 
// Design Name:    ZX Spectrum
// Module Name:    ram32k
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 1.00 - File Created
// Additional Comments: GPL License policies apply to the contents of this file.
//
//////////////////////////////////////////////////////////////////////////////////

/*
This module generates a high level on "isfalling" when "a" changes from high to low.
*/
module getfedge (
	input clk,
	input a,
	output isfalling
	);
	
	reg sh = 1'b1;
	assign isfalling = sh & ~a;
	always @(posedge clk)
		sh <= a;
endmodule


/*
This module implements a shared RAM controller. The Spartan 3 Starter Kit has two 256Kx16 SRAM chips.
It uses half the size of one of these chips (8 bit data bus instead of 16).
As the ZX Spectrum needs two independent memory banks, and bus cycles may happen to both at the same
time, it's necessary to emulate those two banks with one chip.

I tried a simple round-robin multiplexing, but didn't work as expected. This module is a bit more complicated
as it implements a first-come-first-serve approach, with fixed priority scheme when several petitions happen
at the same time.

Each bank can be up to 64Kx8, so implementing a 128K memory scheme is very easy (I hope so) using this module
and the external SRAM on board.

This may be my first 100% synchronous implementation for a FPGA (that is, only one clock and all the ff's are
activated at the same edge)

*/
module ram_controller (
	input clk,
	// Bank 1 (VRAM)
	input [15:0] a1,
	input cs1_n,
	input oe1_n,
	input we1_n,
	input [7:0] din1,
	output [7:0] dout1,
	// Bank 2 (upper RAM)
	input [15:0] a2,
	input cs2_n,
	input oe2_n,
	input we2_n,
	input [7:0] din2,
	output [7:0] dout2,
	// Outputs to actual SRAM on board
	output [17:0] sa,
	inout [7:0] sd,
	output sramce,
	output sramub,
	output sramlb,
	output sramoe,
	output sramwe
	);
	
	// Permanently enable SRAM and set it to use only LSB
	assign sramub = 1;
	assign sramlb = 0;
	assign sramce = 0;
	assign sramoe = 0;
	
	reg rsramwe = 1;
	assign sramwe = rsramwe;
	
	reg [17:0] rsa;
	reg [7:0] rsd;
	assign sa = rsa;
	assign sd = rsd;

	// set when there has been a high to low transition in the corresponding signal
	wire bank1read, bank1write, bank2read, bank2write;
	getfedge detectbank1read (clk, cs1_n | oe1_n, bank1read);
	getfedge detectbank2read (clk, cs2_n | oe2_n, bank2read);
	getfedge detectbank1write (clk, cs1_n | we1_n, bank1write);
	getfedge detectbank2write (clk, cs2_n | we2_n, bank2write);

	reg [15:0] ra1;
	reg [15:0] ra2;
	reg [7:0] rdin1;
	reg [7:0] rdin2;
	
	reg [7:0] rdout1;
	assign dout1 = rdout1;
	reg [7:0] rdout2;
	assign dout2 = rdout2;

	// ff's to store pending memory requests
	reg pendingreadb1 = 0;
	reg pendingwriteb1 = 0;
	reg pendingreadb2 = 0;
	reg pendingwriteb2 = 0;
	
	// ff's to store current memory requests
	reg reqreadb1 = 0;
	reg reqreadb2 = 0;
	reg reqwriteb1 = 0;
	reg reqwriteb2 = 0;

	reg state = 1;
	always @(posedge clk) begin
		// get requests from the two banks
		if (bank1read) begin
			ra1 <= a1;
			pendingreadb1 <= 1;
			pendingwriteb1 <= 0;
		end
		else if (bank1write) begin
			ra1 <= a1;
			rdin1 <= din1;
			pendingwriteb1 <= 1;
			pendingreadb1 <= 0;
		end
		if (bank2read) begin
			ra2 <= a2;
			pendingreadb2 <= 1;
			pendingwriteb2 <= 0;
		end
		else if (bank2write) begin
			ra2 <= a2;
			rdin2 <= din2;
			pendingwriteb2 <= 1;
			pendingreadb2 <= 0;
		end
		
		// reads from bank1 have the higher priority, then writes to bank1,
		// the reads from bank2, then writes from bank2.
		// Reads and writes to bank2 are mutually exclusive, though, as only the CPU
		// performs those operations. So they are with respect to bank1.
		case (state)
			0 : begin
					if (reqreadb1 || reqwriteb1) begin
						rsa <= {2'b00,ra1};	// operation to bank1 accepted. We put the memory address on the SRAM address bus
						if (reqwriteb1) begin  // if this is a write operation...
							pendingwriteb1 <= 0;   // accept it, and mark pending operation as cleared
							rsd <= rdin1;       // put the data to be written in the SRAM data bus
							rsramwe <= 0;		  // pulse /WE in SRAM to begin write
						end
						else begin
							pendingreadb1 <= 0;  // else, this is a read operation...
							rsd <= 8'bzzzzzzzz;  // disconnect the output bus from the data register to the SRAM data bus, so
							rsramwe <= 1;        // we can read from the SRAM data bus itself. Deassert /WE to enable data output bus
						end
						state <= 1;             // if either request has been accepted, proceed to next phase.
				   end
				   else if (reqreadb2 || reqwriteb2) begin	// do the same with requests to bank 2...
						rsa <= {2'b01,ra2};
						if (reqwriteb2) begin
							pendingwriteb2 <= 0;
							rsd <= rdin2;
							rsramwe <= 0;
						end
						else begin
							pendingreadb2 <= 0;
							rsd <= 8'bzzzzzzzz;
							rsramwe <= 1;
						end
						state <= 1;
					end
				  end
			1 : begin
					if (reqreadb1) begin		// for read requests, read the SRAM data bus and store into the corresponding data output register
						rdout1 <= sd;
					end
					else if (reqreadb2) begin
						rdout2 <= sd;
					end
					if (reqwriteb1) begin	// for write requests, deassert /WE, as writting has already been happened.
						rsramwe <= 1;
					end
					else if (reqwriteb2) begin
						rsramwe <= 1;
					end
					reqreadb1 <= pendingreadb1;	// current request has finished, so update current requests with pending requests to serve  the next one
					reqreadb2 <= pendingreadb2;
					reqwriteb1 <= pendingwriteb1;					
					reqwriteb2 <= pendingwriteb2;
					if (pendingreadb1 || pendingreadb2 || pendingwriteb1 || pendingwriteb2)
						state <= 0;
				 end
		endcase
	end
endmodule
