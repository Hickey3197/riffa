// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
// Modules in this file:
//    pe(_pass): an empty, passthrough Stream PE
// ----------------------------------------------------------------------

`default_nettype none

module pe #
  ( parameter Stages=4 )
   (
    input wire         CLK, SYS_RST,
    input wire         PE_RST,

    output wire        D_BP,    D2_BP,
    input wire [63:0]  D,       D2,
    input wire         D_VALID, D2_VALID,

    input wire         Q_BP,    Q2_BP,
    output wire [63:0] Q,       Q2,
    output wire        Q_VALID, Q2_VALID
   );


   generate
      genvar           i;
      
      if (Stages == 0) begin
         assign D_BP     = Q_BP;
         assign Q        = D;
         assign Q_VALID  = D_VALID;

         assign D2_BP    = Q2_BP;
         assign Q2       = D2;
         assign Q2_VALID = D2_VALID;
      end else begin
         reg [127:0] D_R [Stages-1:0];
         reg [1:0]   D_VALID_R [Stages-1:0];
         reg [1:0]   Q_BP_R;

         always @ (posedge CLK) begin
            if (SYS_RST | PE_RST) begin
               D_VALID_R[0] <= 0;
            end else begin
               D_R      [0] <= { D,       D2       };
               D_VALID_R[0] <= { D_VALID, D2_VALID };
               Q_BP_R       <= { Q_BP,    Q2_BP    };
            end
         end
         
         for (i=1; i<=Stages-1; i=i+1) begin : sr_gen
            always @ (posedge CLK) begin
               if (SYS_RST | PE_RST) begin
                  D_VALID_R[i] <= 0;
               end else begin
                  D_R[i]       <= D_R      [i-1];
                  D_VALID_R[i] <= D_VALID_R[i-1];
               end
            end
         end

         assign { D_BP, D2_BP }      = Q_BP_R;
         assign { Q_VALID, Q2_VALID} = D_VALID_R[Stages-1];
         assign { Q,       Q2      } = D_R      [Stages-1];
      end
   endgenerate
endmodule // pe

`default_nettype wire
