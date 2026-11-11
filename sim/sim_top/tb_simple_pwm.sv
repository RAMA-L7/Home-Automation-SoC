module simple_pwm (
    input  logic         pclk,
    input  logic         presetn,
    output logic [3:0]   pwm_out
);

    logic [15:0] period0;
    logic [15:0] duty0;
    logic [15:0] cnt0;
    logic        enable0;

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            cnt0    <= 16'd0;
            pwm_out[0] <= 1'b0;
        end else if (enable0) begin
            if (cnt0 >= period0) cnt0 <= 16'd0;
            else                 cnt0 <= cnt0 + 1'b1;
            pwm_out[0] <= duty0 != 0 && cnt0 < duty0;
        end else begin
            cnt0    <= 16'd0;
            pwm_out[0] <= 1'b0;
        end
    end

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            period0 <= 16'd0;
            duty0   <= 16'd0;
            enable0 <= 1'b0;
        end
    end

endmodule
