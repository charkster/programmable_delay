// "signal_in" will be synchronized and then put through an edge detect
// when an edge is seen the fast counter will start counting up to a programmable "delay_value"
// when the counter has reached "delay_value" the delayed_out will sample the synhronized "signal_in"
// the assumption is that "signal_in" will not change before it reaches the "delay_value" count
// the rising delay and falling delay is presently symetrical (another "delay_value" could be added)

module prog_delay_top (
  input  logic  clk_100mhz,
  input  logic  button_0,
  input  logic  button_1, // this is used for testing
  input  logic  uart_rx,
  output logic  uart_tx,
  input  logic  signal_in,
  output logic  delayed_out,
  output logic  button_1_sync // this is used for testing
);

  parameter NUM_ADDR_BYTES = 1;
  parameter SLAVE_ID       = 7'd01;

  logic       clk_400mhz;
  logic       rst_n;
  logic       rst_n_sync;
  logic       rst_n_sync_400mhz;
  logic       valid_slave_id;
  logic       rx_data_valid;
  logic [7:0] rx_data_out;
  logic       rx_block_timeout;
  logic       tx_trig;
  logic       tx_bsy;
  logic       write_enable;
  logic       read_enable;
  logic [7:0] send_data;
  logic [6:0] slave_id;
  logic       send_slave_id;
  logic [7:0] regmap_read_data;
  logic       regmap_read_enable;
  logic       regmap_write_enable;

  logic [15:0] delay_value;
  logic [15:0] counter_value;
  logic        signal_in_sync;
  logic        edge_det;

  logic [NUM_ADDR_BYTES*8-1:0] address;

  // button_s2 is normally high unless it is pressed
  synchronizer u_synchronizer_button_s2_sync
    ( .clk      (clk_100mhz),     // input
      .rst_n    (rst_n_sync),    // input
      .data_in  (button_1),     // input
      .data_out (button_1_sync) // output
     );
     
 clk_wiz_0 u_clk_wiz_0_400mhz
 ( .clk_out1 (clk_400mhz), // output
   .clk_in1  (clk_100mhz)  // input
 );

  assign rst_n = ~button_0;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_100mhz), // input
      .rst_n    (rst_n),     // input
      .data_in  (1'b1),      // input
      .data_out (rst_n_sync) // output
     );

  synchronizer u_synchronizer_rst_n_sync_300mhz
    ( .clk      (clk_400mhz),       // input
      .rst_n    (rst_n),            // input
      .data_in  (1'b1),             // input
      .data_out (rst_n_sync_400mhz) // output
     );

  assign valid_slave_id = (slave_id == SLAVE_ID);

  uart_tx 
  # ( .SYSCLOCK( 100.0 ), .BAUDRATE( 1.0 ) ) // MHz and Mbits
  u_uart_tx
    ( .clk       (clk_100mhz),                 // input
      .rst_n     (rst_n_sync),                // input
      .send_trig (tx_trig && valid_slave_id), // input
      .send_data,                             // input [7:0]
      .tx        (uart_tx),                   // output
      .tx_bsy                                 // output
     );

  uart_rx
  # ( .SYSCLOCK( 100.0 ), .BAUDRATE( 1.0 ) ) // MHz and Mbits
  u_uart_rx
    ( .clk           (clk_100mhz),        // input
      .rst_n         (rst_n_sync),       // input
      .rx            (uart_rx),          // input
      .rx_bsy        (),                 // output
      .block_timeout (rx_block_timeout), // output
      .data_valid    (rx_data_valid),    // output
      .data_out      (rx_data_out)       // output [7:0]
     );

  // this block can allow for multiple memories to be accessed,
  // but as the address width is fixed, smaller memories will need to
  // zero pad the upper address bits not used (this is done in python)
  uart_byte_regmap_interface
  # ( .NUM_ADDR_BYTES(NUM_ADDR_BYTES) )
  u_uart_byte_regmap_interface
    ( .clk          (clk_100mhz),  // input
      .rst_n        (rst_n_sync), // input
      .rx_data_out,               // input [7:0]
      .rx_data_valid,             // input
      .rx_block_timeout,          // input
      .tx_bsy,                    // input
      .tx_trig,                   // output
      .slave_id,                  // output [6:0]
      .address,                   // output [NUM_ADDR_BYTES*8-1:0]
      .write_enable,              // output
      .read_enable,               // output
      .send_slave_id              // output
     );
  
  // first uart byte of data to send is an read_enable and slave_id, then requested read data will be sent
  assign send_data = (send_slave_id) ? {read_enable,slave_id} : regmap_read_data;

  assign regmap_write_enable = write_enable && (slave_id == SLAVE_ID);
  assign regmap_read_enable  = read_enable  && (slave_id == SLAVE_ID);

  parameter MAX_ADDRESS = 8'd1;
  logic [7:0] registers[1:0];
    
  assign regmap_read_data = (regmap_read_enable) ? registers[address] : 8'd0;
    
  integer i;
  always_ff @(posedge clk_100mhz, negedge rst_n_sync)
    if (~rst_n_sync) for (i=0; i<=MAX_ADDRESS; i=i+1) registers[i]       <= 8'h00;
    else if (regmap_write_enable)                     registers[address] <= rx_data_out;

  // this is in clk_100mhz domain, this should be stable before any signal_in has any edges
  always_comb
    delay_value = {registers[1][7:0], registers[0][7:0]};

  synchronizer u_synchronizer_signal_in_sync
    ( .clk      (clk_400mhz),        // input
      .rst_n    (rst_n_sync_400mhz), // input
      .data_in  (signal_in),         // input
      .data_out (signal_in_sync)     // output
     );

  assign edge_det = (delayed_out != signal_in_sync);

  always_ff @(posedge clk_400mhz, negedge rst_n_sync_400mhz)
    if (~rst_n_sync_400mhz)                                                 counter_value <= 16'd0;
    else if (edge_det && (delay_value > 16'd0) && (counter_value == 16'd0)) counter_value <= 16'd1;
    else if ((counter_value > 16'd0) && (counter_value < delay_value))      counter_value <= counter_value + 16'd1;
    else                                                                    counter_value <= 16'd0;

  always_ff @(posedge clk_400mhz, negedge rst_n_sync_400mhz)
    if (~rst_n_sync_400mhz)                delayed_out <= 0;
    else if (counter_value == delay_value) delayed_out <= signal_in_sync;

endmodule
