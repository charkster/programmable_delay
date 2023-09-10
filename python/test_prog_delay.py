import time
from scarf_uart_slave import scarf_uart_slave

prog = scarf_uart_slave(slave_id=0x01, num_addr_bytes=1, debug=False)
print(prog.read_list(addr=0x00, num_bytes=2))
prog.write_list(addr=0x00, write_byte_list=[0x01, 0x02])
print(prog.read_list(addr=0x00, num_bytes=2))
#print(prog.read_id())
