library ieee;
use ieee.std_logic_1164.all;

entity alu_control is
	port (
		ALUOp		:	in std_logic_vector(1 downto 0);
		func		:	in std_logic_vector(5 downto 0);
		control		:	out std_logic_vector(3 downto 0);
		excep		:	out std_logic
	);
end alu_control;

architecture arch_alu_control of alu_control is
begin
	process(ALUOp, func)
	variable funcl		:	std_logic_vector(3 downto 0);
	variable controlv	:	std_logic_vector(3 downto 0);
	variable excepv		:	std_logic;
	begin
		excepv := '0';
		funcl := func(3 downto 0);
		if ALUOp = "00" then
			-- lw sw --
			controlv := "0110";
		elsif ALUOp = "01" then
			-- beq --
			controlv := "1110";
		elsif ALUOp = "10" then
			-- r type --
			if funcl = "0000" then
				-- add --
				controlv := "0110";
			elsif funcl = "0010" then
				-- sub --
				controlv := "1110";
			elsif funcl = "0100" then
				-- and --
				controlv := "0000";
			elsif funcl = "0101" then
				-- or --
				controlv := "0001";
			elsif funcl = "0110" then
				-- xor --
				controlv := "0010";
			elsif funcl = "0111" then
				-- nor --
				controlv := "0011";
			elsif funcl = "1010" then
				-- slt --
				controlv := "1111";
			else
				-- Unknown Instruction Exception --
				excepv := '1';
			end if;
		elsif ALUOp = "11" then
			-- addi --
			controlv := "0110";
		end if;
		control <= controlv;
		excep <= excepv;
	end process;
end arch_alu_control;
		