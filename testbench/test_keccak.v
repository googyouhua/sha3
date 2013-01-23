/*
 * Copyright 2013, Homer Hsing <homer.hsing@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`timescale 1ns / 1ps
`define P 20

module test_keccak;

	// Inputs
	reg clk;
	reg reset;
	reg [63:0] in;
	reg in_ready;
	reg is_last;
	reg [2:0] byte_num;

	// Outputs
	wire ack;
	wire [511:0] out;
	wire out_ready;

    // Var
    integer i;

	// Instantiate the Unit Under Test (UUT)
	keccak uut (
		.clk(clk), 
		.reset(reset), 
		.in(in), 
		.in_ready(in_ready), 
		.is_last(is_last), 
		.byte_num(byte_num), 
		.ack(ack), 
		.out(out), 
		.out_ready(out_ready)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		in = 0;
		in_ready = 0;
		is_last = 0;
		byte_num = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        @ (negedge clk);

        // hash an string "\xA1\xA2\xA3\xA4\xA5", len == 5
        reset = 1; #(`P); reset = 0;
        #(7*`P); // wait some cycles
        in = 64'hA5A4A3A2A1;
        byte_num = 5;
        in_ready = 1;
        is_last = 1;
        #(`P);
        in = 64'h12345678; // next input
        in_ready = 1;
        is_last = 1;
        #(`P/2);
        if (ack === 1) error; // should be 0
        #(`P/2);
        in_ready = 0;
        is_last = 0;

        while (out_ready !== 1)
            #(`P);
        check(512'h12f4a85b68b091e8836219e79dfff7eb9594a42f5566515423b2aa4c67c454de83a62989e44b5303022bfe8c1a9976781b747a596cdab0458e20d8750df6ddfb);
        for(i=0; i<5; i=i+1)
            if (ack === 1) error; // should be 0

        // hash an empty string, should not eat next input
        reset = 1; #(`P); reset = 0;
        #(7*`P); // wait some cycles
        in = 64'h12345678; // should not be eat
        byte_num = 0;
        in_ready = 1;
        is_last = 1;
        #(`P);
        in = 64'hddddd; // should not be eat
        in_ready = 1; // next input
        is_last = 1;
        #(`P/2);
        if (ack === 1) error; // should be 0
        #(`P/2);
        in_ready = 0;
        is_last = 0;

        while (out_ready !== 1)
            #(`P);
        check(512'h0eab42de4c3ceb9235fc91acffe746b29c29a8c366b7c60e4e67c466f36a4304c00fa9caf9d87976ba469bcbe06713b435f091ef2769fb160cdab33d3670680e);
        for(i=0; i<5; i=i+1)
            if (ack === 1) error; // should be 0

        // hash an (576-8) bit string
        reset = 1; #(`P); reset = 0;
        #(4*`P); // wait some cycles
        in_ready = 1;
        byte_num = 7; /* should have no effect */
        is_last = 0;
        for (i=0; i<8; i=i+1)
          begin
            in = 64'h1234567890ABCDEF;
            #(`P);
          end
        is_last = 1;
        #(`P);
        in_ready = 0;
        is_last = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'hf7f6b44069dba8900b6711ffcbe40523d4bb718cc8ed7f0a0bd28a1b18ee9374359f0ca0c9c1e96fcfca29ee2f282b46d5045eff01f7a7549eaa6b652cbf6270);

        // pad an (576-64) bit string
        reset = 1; #(`P); reset = 0;
        // don't wait any cycle
        in_ready = 1;
        byte_num = 7; /* should have no effect */
        is_last = 0;
        for (i=0; i<8; i=i+1)
          begin
            in = 64'h1234567890ABCDEF;
            #(`P);
          end
        is_last = 1;
        byte_num = 0;
        #(`P);
        in_ready = 0;
        is_last = 0;
        in = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'hccd91653872c106f6eea1b8b68a4c2901c8d9bed9c180201f8a6144e7e6e6c251afcb6f6da44780b2d9aabff254036664719425469671f7e21fb67e5280a27ed);

        // pad an (576*2-16) bit string
        reset = 1; #(`P); reset = 0;
        in_ready = 1;
        byte_num = 1; /* should have no effect */
        is_last = 0;
        for (i=0; i<9; i=i+1)
          begin
            in = 64'h1234567890ABCDEF;
            #(`P/2);
            while (ack !== 1) #(`P); // wait
            #(`P/2);
          end
        #(`P/2);
        if (ack !== 0) error; // should not eat
        #(`P/2);
        in = 64'h999; // should not eat this
        in_ready = 0;
        #(`P/2);
        if (ack !== 0) error; // should not eat
        #(`P/2);
        #(`P);
        // feed next (576-16) bit
        in_ready = 1;
        for (i=0; i<8; i=i+1)
          begin
            in = 64'h1234567890ABCDEF;
            #(`P/2);
            while (ack !== 1) #(`P); // wait
            #(`P/2);
          end
        byte_num = 6;
        is_last = 1;
        in = 64'h1234567890ABCDEF;
        #(`P/2);
        while (ack !== 1) #(`P); // wait
        #(`P/2);
        is_last = 0;
        in_ready = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'h0f385323604e279251e80f928cfd9ce9492ba5df775063ea106eebe2a2c7785a3e33b4397fca66e90f67470334c66ea12016cb1f06170b9b033f158a7c01933e);

        $display("Good!");
        $finish;
	end

    always #(`P/2) clk = ~ clk;

    task error;
        begin
              $display("E");
              $finish;
        end
    endtask

    task check;
        input [511:0] wish;
        begin
          if (out !== wish)
            begin
              $display("%h %h", out, wish); error;
            end
        end
    endtask
endmodule

`undef P
