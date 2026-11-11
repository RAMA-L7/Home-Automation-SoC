module minimal (
    input  logic         clk,
    input  logic         reset_n,
    output logic         out
);

    logic [15:0] cnt;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cnt   <= 16'd0;
            out   <= 1'b0;
        end else begin
            cnt   <= cnt + 1'b1;
            out   <= cnt[0];
        end
    end

endmodule
