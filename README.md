# programmable_delay
FPGA design to allow for programmable delay on a single signal. Implemented and tested on **CMOD_A7**

**Rising Delay** (yellow is "signal_in" input and blue is "delayed_out" output)

![picture](https://github.com/charkster/programmable_delay/blob/main/scope_captures/prog_delay_1000_rise.png)

**Falling Delay** (yellow is "signal_in" input and blue is "delayed_out" output)

![picture](https://github.com/charkster/programmable_delay/blob/main/scope_captures/prog_delay_1000_fall.png)

My CMOD A7 has been modified to have a 100MHz oscillator on the board (stock one is 12MHz)... this should not be a big deal for a stock CMOD A7, as the internal PLL should be able to reach 400MHz from a 12MHz source. My internal clock used for counting is **400MHz** (**1 count = 2.5ns**). Looks like there is **11ns** ([**rise**](https://github.com/charkster/programmable_delay/blob/main/scope_captures/prog_delay_zero_rise.png)) and **13ns** ([**fall**](https://github.com/charkster/programmable_delay/blob/main/scope_captures/prog_delay_zero_fall.png)) delay from input to output before any counting is done. I have a **16bit** counter which allow for a **65,535 max** count (163us maximum delay). The counter could be modified to be any width... I just chose 2 bytes. The FPGA's **UART** interface is used to change the programmable delay. There is no clock-crossing for the programmed delay and the high-speed 400MHz clock... just **don't change the delay on the fly**.

CMOD A7 **"BTN1"** (button_1) can be used to generate a sample **"signal_in"** when those **2 pins are connected**. I used this button to capture the oscilloscope waveforms of various programmable delays. **"BTN0"** is the asynch **reset**. 

**Pin 1** is synchronized **BTN1 output**, **pin 2** is the **signal_in input** and **pin 3** is the **delayed_out output**.

The sample Python code uses the pyftdi module... the generic serial module could be used, but I have better reliability with pyftdi.

I did try this RTL on my Tang Nano 9k, but the implementation had problems... I though it might be the programmable delay clock-crossing, but when I used a static value for the delay it still did not work. Anyways, Gowin's tool gave a bad implementation and I don't want to debug it further when Vivado's CMOD A7 implementation works perfectly. If you have installed **openFPGAloader**, [**this**](https://github.com/charkster/programmable_delay/blob/main/fpga/run_openFPGAloader_cmod_a7.sh) bash script can be used to program the CMOD A7's flash memory.

This helped me to resolve a PCB board timing problem, and that was my motivation for building this.
