
`timescale 1 ns / 1 ps

    module myip_AXI4_Lite_Master_v1_0_M00_AXI #
    (
        // Users to add parameters here
        // User parameters ends
        // Do not modify the parameters beyond this line

        // The master requires a target slave base address.
        // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
        parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
        // Width of M_AXI address bus.
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
        parameter integer C_M_AXI_ADDR_WIDTH	= 32,
        // Width of M_AXI data bus.
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
        parameter integer C_M_AXI_DATA_WIDTH	= 32,
        // Transaction number is the number of write
    // and read transactions the master will perform as a part of this example memory test.
        parameter integer C_M_TRANSACTIONS_NUM	= 4
    )
    (
        // Users to add ports here
        input wire [1:0] C_M_MODE,  // 0: IDLE, 1: LOAD_DATA, 2: WRITE_DATA
        input wire [C_M_AXI_DATA_WIDTH-1 : 0] C_M_OFF_MEM_ADDRA,
        input wire [C_M_AXI_DATA_WIDTH-1 : 0] C_M_OFF_MEM_ADDRB,
        input wire [C_M_AXI_DATA_WIDTH*C_M_TRANSACTIONS_NUM-1 : 0] C_M_WDATA,
        output wire [C_M_AXI_DATA_WIDTH*C_M_TRANSACTIONS_NUM-1 : 0] C_M_RDATA,
        // User ports ends
        // Do not modify the ports beyond this line

        // Enable AXI transactions
        input wire  AXI_TXN_EN,
        // Asserts when ERROR is detected
        output reg  ERROR,
        // Asserts when AXI transactions is complete
        //output wire  TXN_DONE,
        // Asserts when instruction (batch of AXI transactions) is complete
        output wire INST_DONE,
        // AXI clock signal
        input wire  M_AXI_ACLK,
        // AXI active low reset signal
        input wire  M_AXI_ARESETN,
        // Master Interface Write Address Channel ports. Write address (issued by master)
        output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
        // Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
        output wire [2 : 0] M_AXI_AWPROT,
        // Write address valid.
    // This signal indicates that the master signaling valid write address and control information.
        output wire  M_AXI_AWVALID,
        // Write address ready.
    // This signal indicates that the slave is ready to accept an address and associated control signals.
        input wire  M_AXI_AWREADY,
        // Master Interface Write Data Channel ports. Write data (issued by master)
        output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
        // Write strobes.
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
        output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
        // Write valid. This signal indicates that valid write data and strobes are available.
        output wire  M_AXI_WVALID,
        // Write ready. This signal indicates that the slave can accept the write data.
        input wire  M_AXI_WREADY,
        // Master Interface Write Response Channel ports.
    // This signal indicates the status of the write transaction.
        input wire [1 : 0] M_AXI_BRESP,
        // Write response valid.
    // This signal indicates that the channel is signaling a valid write response
        input wire  M_AXI_BVALID,
        // Response ready. This signal indicates that the master can accept a write response.
        output wire  M_AXI_BREADY,
        // Master Interface Read Address Channel ports. Read address (issued by master)
        output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
        // Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
        output wire [2 : 0] M_AXI_ARPROT,
        // Read address valid.
    // This signal indicates that the channel is signaling valid read address and control information.
        output wire  M_AXI_ARVALID,
        // Read address ready.
    // This signal indicates that the slave is ready to accept an address and associated control signals.
        input wire  M_AXI_ARREADY,
        // Master Interface Read Data Channel ports. Read data (issued by slave)
        input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
        // Read response. This signal indicates the status of the read transfer.
        input wire [1 : 0] M_AXI_RRESP,
        // Read valid. This signal indicates that the channel is signaling the required read data.
        input wire  M_AXI_RVALID,
        // Read ready. This signal indicates that the master can accept the read data and response information.
        output wire  M_AXI_RREADY
    );

    // function called clogb2 that returns an integer which has the
    // value of the ceiling of the log base 2

     function integer clogb2 (input integer bit_depth);
         begin
         for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
             bit_depth = bit_depth >> 1;
         end
     endfunction

    // TRANS_NUM_BITS is the width of the index counter for
    // number of write or read transaction.
     localparam integer TRANS_NUM_BITS = clogb2(C_M_TRANSACTIONS_NUM-1);
     // 0, 2, 4, 6: Write addr of off-mem(slv_reg1)
     // 1, 3, 5, 7: Read data from off-mem(BRAM[slv_reg2]->slv_reg2->M00)
     // 8: Write data to UB
     localparam integer LOAD_DATA_DONE  = 9-1;    // 9-cycle
     // 0, 2, 4, 6: Write addr of off-mem(slv_reg3)
     // 1, 3, 5, 7: Write data(M00->slv_reg4->BRAM[slv_reg3])
     localparam integer WRITE_DATA_DONE  = 8-1;   // 8-cycle

    // Example State machine to initialize counter, initialize write transactions,
    // initialize read transactions and comparison of read data with the
    // written data words.
    parameter [1:0] IDLE = 2'b00,
                    LOAD_DATA   = 2'b01, // This state initializes load data instruction,
                    // 8 times of writes and reads done, the state machine
                    // changes state to IDLE state
                    WRITE_DATA  = 2'b10; // This state initializes write data instruction
                    // 8 times of writes and reads done, the state machine
                    // changes state to IDLE state

    reg [3:0] mst_exec_state;

    // AXI4LITE signals
    //write address valid
    reg  	axi_awvalid;
    //write data valid
    reg  	axi_wvalid;
    //read address valid
    reg  	axi_arvalid;
    //read data acceptance
    reg  	axi_rready;
    //write response acceptance
    reg  	axi_bready;
    //write address
    reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    //write data
    reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
    //read addresss
    reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    //Asserts when there is a write response error
    wire  	write_resp_error;
    //Asserts when there is a read response error
    wire  	read_resp_error;
    //A pulse to initiate a write transaction
    reg  	start_single_write;
    //A pulse to initiate a read transaction
    reg  	start_single_read;
    //index counter to track the number of write transaction issued
    reg [TRANS_NUM_BITS : 0] 	write_index;
    //index counter to track the number of read transaction issued
    reg [TRANS_NUM_BITS : 0] 	read_index;
    reg [3:0] minor_state;
    reg [C_M_AXI_DATA_WIDTH-1 : 0] C_M_RDATA_PARSED [C_M_TRANSACTIONS_NUM-1 : 0];
    wire [C_M_AXI_DATA_WIDTH-1 : 0] C_M_WDATA_PARSED [C_M_TRANSACTIONS_NUM-1 : 0];
    reg inst_done;
    reg txn_done;
    reg [C_M_AXI_DATA_WIDTH-1 : 0] 	c_m_off_mem_addra_reg;
    reg [C_M_AXI_DATA_WIDTH-1 : 0] 	c_m_off_mem_addrb_reg;

    // I/O Connections assignments

    //Adding the offset address to the base addr of the slave
    assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr;
    //AXI 4 write data
    assign M_AXI_WDATA	= axi_wdata;
    assign M_AXI_AWPROT	= 3'b000;
    assign M_AXI_AWVALID	= axi_awvalid;
    //Write Data(W)
    assign M_AXI_WVALID	= axi_wvalid;
    //Set all byte strobes in this example
    assign M_AXI_WSTRB	= 4'b1111;
    //Write Response (B)
    assign M_AXI_BREADY	= axi_bready;
    //Read Address (AR)
    assign M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_araddr;
    assign M_AXI_ARVALID	= axi_arvalid;
    assign M_AXI_ARPROT	= 3'b001;
    //Read and Read Response (R)
    assign M_AXI_RREADY	= axi_rready;
    //Example design I/O
    //assign TXN_DONE         = txn_done;
    assign C_M_RDATA = {C_M_RDATA_PARSED[3], C_M_RDATA_PARSED[2], C_M_RDATA_PARSED[1], C_M_RDATA_PARSED[0]};
    for (genvar i = 0; i < C_M_TRANSACTIONS_NUM; i = i + 1) begin
        assign C_M_WDATA_PARSED[i] = C_M_WDATA[i * C_M_AXI_DATA_WIDTH + : C_M_AXI_DATA_WIDTH];
    end
    assign INST_DONE = inst_done;


    //--------------------
    //Write Address Channel
    //--------------------

    // The purpose of the write address channel is to request the address and
    // command information for the entire transaction.  It is a single beat
    // of information.

    // Note for this example the axi_awvalid/axi_wvalid are asserted at the same
    // time, and then each is deasserted independent from each other.
    // This is a lower-performance, but simplier control scheme.

    // AXI VALID signals must be held active until accepted by the partner.

    // A data transfer is accepted by the slave when a master has
    // VALID data and the slave acknoledges it is also READY. While the master
    // is allowed to generated multiple, back-to-back requests by not
    // deasserting VALID, this design will add rest cycle for
    // simplicity.

    // Since only one outstanding transaction is issued by the user design,
    // there will not be a collision between a new request and an accepted
    // request on the same clock cycle.

    always @(posedge M_AXI_ACLK) begin
        //Only VALID signals must be deasserted during reset per AXI spec
        //Consider inverting then registering active-low reset for higher fmax
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            axi_awvalid <= 1'b0;
        end
        //Signal a new address/data command is available by user logic
        else begin
            if (start_single_write) begin
                axi_awvalid <= 1'b1;
            end
            //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
            else if (M_AXI_AWREADY && axi_awvalid) begin
                axi_awvalid <= 1'b0;
            end
        end
    end


    // start_single_write triggers a new write
    // transaction. write_index is a counter to
    // keep track with number of write transaction
    // issued/initiated
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            write_index <= 0;
        end
        // Signals a new write address/ write data is
        // available by user logic
        else if (start_single_write) begin
            write_index <= write_index + 1;
        end
    end


    //--------------------
    //Write Data Channel
    //--------------------

    //The write data channel is for transfering the actual data.
    //The data generation is speific to the example design, and
    //so only the WVALID/WREADY handshake is shown here

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            $display("[AXI4_Lite_Master:Write_Data_Channel] Reset or Init");
            axi_wvalid <= 1'b0;
        end
        //Signal a new address/data command is available by user logic
        else if (start_single_write) begin
            axi_wvalid <= 1'b1;
        end
        //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)
        else if (M_AXI_WREADY && axi_wvalid) begin
            axi_wvalid <= 1'b0;
        end
    end


    //----------------------------
    //Write Response (B) Channel
    //----------------------------

    //The write response channel provides feedback that the write has committed
    //to memory. BREADY will occur after both the data and the write address
    //has arrived and been accepted by the slave, and can guarantee that no
    //other accesses launched afterwards will be able to be reordered before it.

    //The BRESP bit [1] is used indicate any errors from the interconnect or
    //slave for the entire write burst. This example will capture the error.

    //While not necessary per spec, it is advisable to reset READY signals in
    //case of differing reset latencies between master/slave.

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            axi_bready <= 1'b0;
        end
        // accept/acknowledge bresp with axi_bready by the master
        // when M_AXI_BVALID is asserted by slave
        else if (M_AXI_BVALID && ~axi_bready) begin
            axi_bready <= 1'b1;
        end
        // deassert after one clock cycle
        else if (axi_bready) begin
            axi_bready <= 1'b0;
        end
        // retain the previous value
        else
            axi_bready <= axi_bready;
    end

    //Flag write errors
    assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);


    //----------------------------
    //Read Address Channel
    //----------------------------

    //start_single_read triggers a new read transaction. read_index is a counter to
    //keep track with number of read transaction issued/initiated

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            read_index <= 0;
        end
        // Signals a new read address is
        // available by user logic
        else if (start_single_read) begin
            read_index <= read_index + 1;
        end
    end

    // A new axi_arvalid is asserted when there is a valid read address
    // available by the master. start_single_read triggers a new read
    // transaction
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            axi_arvalid <= 1'b0;
        end
        //Signal a new read address command is available by user logic
        else if (start_single_read) begin
            axi_arvalid <= 1'b1;
        end
        //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
        else if (M_AXI_ARREADY && axi_arvalid) begin
            axi_arvalid <= 1'b0;
        end
        // retain the previous value
    end


    //--------------------------------
    //Read Data (and Response) Channel
    //--------------------------------

    //The Read Data channel returns the results of the read request
    //The master will accept the read data by asserting axi_rready
    //when there is a valid read data available.
    //While not necessary per spec, it is advisable to reset READY signals in
    //case of differing reset latencies between master/slave.

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0 || txn_done == 1'b1) begin
            axi_rready <= 1'b0;
        end
        // accept/acknowledge rdata/rresp with axi_rready by the master
        // when M_AXI_RVALID is asserted by slave
        else if (M_AXI_RVALID && ~axi_rready) begin
            axi_rready <= 1'b1;
        end
        // deassert after one clock cycle
        else if (axi_rready) begin
            axi_rready <= 1'b0;
        end
        // retain the previous value
    end

    //Flag write errors
    assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);


    //--------------------------------
    //User Logic

    // Transaction done check
    always @ (posedge M_AXI_ACLK) begin : TXN_DONE_CHECK
        if (M_AXI_ARESETN == 1'b0 || txn_done == 1'b1) begin
            txn_done <= 1'b0;
        end else if ((M_AXI_BVALID && axi_bready) || (M_AXI_BVALID && axi_bready)) begin
            txn_done <= 1'b1;
        end
    end

    // State machine
    always @ (posedge M_AXI_ACLK) begin : STATE_MACHINE
        if (M_AXI_ARESETN == 1'b0 || inst_done == 1'b1) begin
            $display("[AXI4_Lite_Master:STATE_MACHINE] Reset");
            // Reset condition
            // All the signals are assigned default values under reset condition
            mst_exec_state      <= IDLE;
            minor_state         <= 'd0;
            axi_awaddr          <= 32'h00000000;
            C_M_RDATA_PARSED[0] <= 32'h00000000;
            C_M_RDATA_PARSED[1] <= 32'h00000000;
            C_M_RDATA_PARSED[2] <= 32'h00000000;
            C_M_RDATA_PARSED[3] <= 32'h00000000;
            axi_araddr          <= 32'h00000000;
            start_single_write  <= 1'b0;
            start_single_read   <= 1'b0;
            ERROR               <= 1'b0;
            inst_done           <= 1'b0;
        end else if (AXI_TXN_EN) begin
            // State logic
            case (mst_exec_state)
            IDLE : begin
                $display("[AXI4_Lite_Master:STATE_MACHINE] IDLE");
                // This state is responsible to initiate
                mst_exec_state  <= C_M_MODE;
                ERROR <= 1'b0;
            end
            LOAD_DATA  : begin
                $display("[AXI4_Lite_Master:STATE_MACHINE] LOAD_DATA");
                case (minor_state)
                LOAD_DATA_DONE : begin  // Write data to UB (inst_done <= 1'b1)
                    mst_exec_state  <= IDLE;
                    minor_state     <= 'd0;
                    axi_awaddr      <= 'd0;
                    inst_done       <= 1'b1;
                end

                0, 2, 4, 6 : begin  // Write off-mem read addr (ADDRB)
                    $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem read addr(ADDRB)");
                    axi_awaddr <= 1;    // Write addr (slv_reg1)
                    // Write and state control logic
                    if (M_AXI_BVALID && axi_bready) begin
                        // Write addr(slv_reg1) valid & ready : Write done normally.
                        $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem done(0)");
                        minor_state     <= minor_state + 1;
                    end else begin
                        if (~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write) begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem init(0)");
                            if (minor_state == 0) begin
                                c_m_off_mem_addrb_reg <= C_M_OFF_MEM_ADDRB + 1;
                                axi_wdata <= C_M_OFF_MEM_ADDRB;
                            end else begin
                                c_m_off_mem_addrb_reg <= c_m_off_mem_addrb_reg + 1;
                                axi_wdata <= c_m_off_mem_addrb_reg;
                            end
                            start_single_write  <= 1'b1;
                        end else begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Negate to generate a pulse(0)");
                            start_single_write  <= 1'b0; //Negate to generate a pulse
                        end
                    end
                end

                1, 3, 5, 7 : begin  // Read data from off-mem (slv_reg2)
                    $display("[AXI4_Lite_Master:STATE_MACHINE] Read data from off-mem (slv_reg2)");
                    axi_araddr <= 2;
                    // Read and state control logic
                    if (M_AXI_RVALID && axi_rready) begin
                        // Read data(slv_reg2) valid & ready : Read done Normaly
                        C_M_RDATA_PARSED[minor_state >> 1] = M_AXI_RDATA;
                        minor_state     <= minor_state + 1;
                    end else begin
                        if (~axi_arvalid && ~M_AXI_RVALID && ~start_single_read) begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Read off-mem init(0)");
                            start_single_read <= 1'b1;
                        end else begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Negate to generate a pulse(1)");
                            start_single_read <= 1'b0; //Negate to generate a pulse
                        end
                    end
                end
                endcase
            end

            WRITE_DATA : begin
                $display("[AXI4_Lite_Master:STATE_MACHINE] WRITE_DATA");
                case (minor_state)
                WRITE_DATA_DONE : begin
                    mst_exec_state  <= IDLE;
                    minor_state     <= 'd0;
                    axi_awaddr      <= 'd0;
                    inst_done       <= 1'b1;
                end

                0, 2, 4, 6 : begin  // Write off-mem write addr (ADDRA)
                    $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem write addr (ADDRA)");
                    axi_awaddr <= 3;
                    // Write and state control logic
                    if (M_AXI_BVALID && axi_bready) begin
                        // Write addr(slv_reg1) valid & ready : Write done normally.
                        $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem done(2)");
                        minor_state     <= minor_state + 1;
                    end else begin
                        if (~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write) begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem init(2)");
                            if (minor_state == 0) begin
                                c_m_off_mem_addra_reg <= C_M_OFF_MEM_ADDRA + 1;
                                axi_wdata <= C_M_OFF_MEM_ADDRA;
                            end else begin
                                c_m_off_mem_addra_reg <= c_m_off_mem_addra_reg + 1;
                                axi_wdata <= c_m_off_mem_addra_reg;
                            end
                            start_single_write  <= 1'b1;
                        end else begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Negate to generate a pulse(2)");
                            start_single_write <= 1'b0; //Negate to generate a pulse
                        end
                    end
                end
                1, 3, 5, 7 : begin  // Write off-mem data (slv_reg4)
                    $display("[AXI4_Lite_MasterSTATE_MACHINE] Write off-mem data (slv_reg4)");
                    axi_awaddr <= 4;
                    // Write and state control logic
                    if (M_AXI_BVALID && axi_bready) begin
                        // Write addr(slv_reg1) valid & ready : Write done normally.
                        $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem done(3)");
                        minor_state     <= minor_state + 1;
                    end else begin
                        if (~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write) begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Write off-mem init(3)");
                            axi_wdata           <= C_M_WDATA_PARSED[minor_state >> 1];
                            start_single_write  <= 1'b1;
                        end else begin
                            $display("[AXI4_Lite_Master:STATE_MACHINE] Negate to generate a pulse(3)");
                            start_single_write <= 1'b0; //Negate to generate a pulse
                        end
                    end
                end
                endcase
            end
            default : begin
                mst_exec_state <= IDLE;
            end
            endcase
        end else begin
            mst_exec_state <= IDLE;
        end
    end

    
    // User logic ends

    endmodule
