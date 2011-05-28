class C8_CPU
  attr_accessor :halted

  @@instructions = Hash.new

  class Register < Array
    def []=(n, val)
      super(n, val % 0x100)
    end
  end

  def initialize(bus = nil)
    @bus = bus
    reset
  end

  def connect_bus(bus)
    @bus = bus
  end

  def reset
    @registers = Register.new(16,0)
    @stack = []
    @pc = 0x200
    @halted = false
  end

  def dump
    "Registers: #{@registers.map{|n| n.to_s(16)}}\nStack: #{@stack}\nPC: #{@pc}"
  end

  def execute(opcode)
    found = false
    @@instructions.each do |k,(name, code)|
      if matches = opcode.match(k) then
        found = true
        matches = matches.to_a.map{|n| n.to_i(16)}
        puts "opcode is #{opcode}"
        puts "executing #{name} with #{matches}"
        instance_exec(matches[1..-1], &code)

        break
      end
    end
    raise "No instruction matches #{opcode}" unless found
  end

  def execute_next
    opcode = @bus.read_opcode_from_address(@pc)
    execute(opcode)
  end

  ## Instructions
  #
  def instructions
    @@instructions
  end

 def self.instruction(name, pattern, &block)
    @@instructions[pattern] = [name, block]
  end

  instruction "jump", /1(...)/ do |matches|
    address = matches[0]
    @pc = address
  end

  instruction "sub", /2(...)/ do |matches|
    address = matches[0]
    @stack.push @pc
    @pc = address
  end

  instruction "skeq", /3(.)(..)/ do |matches|
    register = matches[0]
    value = matches[1]
    @pc += @registers[register] == value ? 4 : 2
  end

  instruction "setra", /6(.)(..)/ do |matches|
    register = matches[0]
    value = matches[1]
    @registers[register] = value
    @pc += 2 
  end

  instruction "addra", /7(.)(..)/ do |matches|
    register = matches[0]
    value = matches[1]
    @registers[register] += value 
    @pc += 2 
  end

  instruction "setrr", /8(.)(.)0/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    @registers[reg_1] = @registers[reg_2]
    @pc += 2 
  end

  instruction "orrr", /8(.)(.)1/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    @registers[reg_1] |= @registers[reg_2]
    @pc += 2 
  end

  instruction "andrr", /8(.)(.)2/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    @registers[reg_1] &= @registers[reg_2]
    @pc += 2 
  end

  instruction "xorrr", /8(.)(.)3/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    @registers[reg_1] ^= @registers[reg_2]
    @pc += 2 
  end

  instruction "addrr", /8(.)(.)4/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    if @registers[reg_1] + @registers[reg_2] > 0xff
      @registers[0xf] = 1
    else
      @registers[0xf] = 0
    end
    @registers[reg_1] += @registers[reg_2]
    @pc += 2 
  end

  instruction "subrr", /8(.)(.)5/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    if @registers[reg_1] >= @registers[reg_2] 
      @registers[0xf] = 1
    else
      @registers[0xf] = 0
    end
    @registers[reg_1] -= @registers[reg_2]
    @pc += 2 
  end

  instruction "shiftr", /8(.)06/ do |matches|
    register = matches[0]
    @registers[0xf] = @registers[register] & 1
    @registers[register] >>= 1
    @pc += 2
  end

  instruction "subrrr", /8(.)(.)7/ do |matches|
    reg_1 = matches[0]
    reg_2 = matches[1]
    if @registers[reg_2] >= @registers[reg_1] 
      @registers[0xf] = 1
    else
      @registers[0xf] = 0
    end
    @registers[reg_1] = @registers[reg_2] - @registers[reg_1]
    @pc += 2 
  end

  instruction "shiftl", /8(.)0e/ do |matches|
    register = matches[0]
    @registers[0xf] = (@registers[register] & 0b10000000) >> 7
    @registers[register] <<= 1
    @pc += 2
  end

  instruction "rndr", /c(.)(..)/ do |matches|
    register = matches[0]
    @registers[register] = rand(0xff) & matches[1]
    @pc += 2
  end
    
  instruction "halt", /0000/ do 
    @halted = true
  end
end
