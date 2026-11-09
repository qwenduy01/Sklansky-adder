module precom #(
    parameter WIDTH = 32
)(input [WIDTH-1: 0] a, b,
output [WIDTH-1: 0] p, g);
assign p = a | b;
assign g = a & b;
endmodule

module postcom #(
    parameter WIDTH = 32
)(input [WIDTH-1 : 0] a, b, g,
output [WIDTH-1 : 0] s);
assign s = g ^ (a ^ b);
endmodule

module black (input up_p, low_p, up_g, low_g,
output p, g );
assign p = up_p & low_p;
assign g = up_g | up_p & low_g;
endmodule

module prefix_adder #(parameter WIDTH = 32)(
    input [WIDTH-1:0] a, b,
    input cin,
    output [WIDTH-1:0] s,
    output cout
);
localparam LAYER = $clog2(WIDTH);
wire [WIDTH-1:0] p [0:LAYER];
wire [WIDTH-1:0] g [0:LAYER];
wire [WIDTH-1:0] pre_p;
wire [WIDTH-1:0] pre_g;
precom #(WIDTH) l_0 (.a(a), .b(b), .p(pre_p), .g(pre_g));

assign p[0] = {{pre_p[WIDTH-2:0]}, 1'b0};
assign g[0] = {{pre_g[WIDTH-2:0]}, cin};

genvar lvl, idx;
generate
    for (lvl =1; lvl <= LAYER; lvl = lvl+1) begin : ROW
        for(idx  =WIDTH-1; idx >=0; idx = idx-1 ) begin: col
            if (idx % (1 << lvl) >= (1<<(lvl-1))) begin : comb
                black comb_0(
                    .up_p(p[lvl-1][idx]),
                    .low_p(p[lvl-1][idx-(idx % (1<<(lvl-1)))-1]),
                    .up_g(g[lvl-1][idx]),
                    .low_g(g[lvl-1][idx-(idx % (1<<(lvl-1)))-1]),
                    .p(p[lvl][idx]),
                    .g(g[lvl][idx])
                );
            end
            else begin: pass
                assign p[lvl][idx] = p[lvl-1][idx];
                assign g[lvl][idx] = g[lvl-1][idx];
            end
        end
    end
endgenerate

postcom #(WIDTH) p_1 (.a(a), .b(b), .g(g[LAYER]), .s(s));

assign cout = pre_g[WIDTH-1] | pre_p[WIDTH-1] & g[LAYER][WIDTH-1];
endmodule