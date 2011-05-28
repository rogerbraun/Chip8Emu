class C8_Memory
  
  def initialize
    @bytes = Array.new(3584) # From 0x200 to 0xfff
  end
  def read(addr)
    @bytes[addr]
  end

  def write(addr, data)
    if data > 0xff
      raise "Data to large"
    else
      @bytes[addr] = data
    end
  end

  def connect_bus(bus)
    @bus = bus
  end
end

class C8_Bus

  def initialize(cpu, memory)
    @cpu = cpu
    @memory = memory
    @cpu.connect_bus self
    @memory.connect_bus self
  end

  def read_from_address(addr)
    if addr >= 0x200
      @memory.read(addr - 0x200)
    end
  end

  def read_opcode_from_address(addr)
    opcode = read_from_address(addr) << 8
    opcode += read_from_address(addr + 1)
    "%04x" % opcode
  end

  def write_to_address(addr, data)
    if addr >= 0x200
      @memory.write(addr - 0x200, data)
    end
  end

end

class C8_Machine
  def initialize
    @cpu = C8_CPU.new
    @memory = C8_Memory.new
    @bus = C8_Bus.new(@cpu, @memory)
  end

  def reset_cpu
    @cpu.reset
  end

  def load_file(file)
    data = File.read(file)
    data.unpack("C*").each_with_index do |data, index|
      @memory.write(index, data)
    end
  end

  def run(debug = false)
    until @cpu.halted do 
      @cpu.execute_next
      puts @cpu.dump if debug
    end
  end  
end
