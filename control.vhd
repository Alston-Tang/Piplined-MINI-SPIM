library ieee;
use ieee.std_logic_1164.all;

entity control is
	port(
		InstOp		:	in std_logic_vector(5 downto 0);
		RegDst		:	out std_logic;
		AluSrc		:	out std_logic;
		MemReg		:	out std_logic;
		RegWr		:	out std_logic;
		MemWrite	:	out std_logic;
		Branch		:	out std_logic;
		Jump		:	out std_logic;
		AluOp		:	out std_logic_vector(1 downto 0);
		excep		:	out std_logic
	);
end control;

architecture arch_control of control is
begin
	process(InstOp)
	variable excepv		:	std_logic;
	begin
		excepv := '0';
		if InstOp = "000000" then
			-- r type --
			RegDst <= '1';
			AluSrc <= '0';
			MemReg <= '0';
			RegWr <= '1';
			MemWrite <= '0';
			Branch <= '0';
			Jump <= '0';
			AluOp <= "10";
		elsif InstOp = "001000" then
			-- addi --
			RegDst <= '0';
			AluSrc <= '1';
			MemReg <= '0';
			RegWr <= '1';
			MemWrite <= '0';
			Branch <= '0';
			Jump <= '0';
			AluOp <= "11";
		elsif InstOp = "100011" then
			-- lw --
			RegDst <= '0';
			AluSrc <= '1';
			MemReg <= '1';
			RegWr <= '1';
			MemWrite <= '0';
			Branch <= '0';
			Jump <= '0';
			AluOp <= "00";
		elsif InstOp = "101011" then
			-- sw --
			AluSrc <= '1';
			RegWr <= '0';
			MemWrite <= '1';
			Branch <= '0';
			Jump <= '0';
			AluOp <= "00";
		elsif InstOp = "000100" then
			-- beq --
			AluSrc <= '0';
			RegWr <= '0';
			MemWrite <= '0';
			Branch <= '1';
			Jump <= '0';
			AluOp <= "01";
		elsif InstOp = "000010" then
			-- j --
			RegWr <= '0';
			MemWrite <= '0';
			Branch <= '0';
			Jump <= '1';
			
		else
			-- Unknown Instruction Exception --
			excepv := '1';
		end if;
		excep <= excepv;
	end process;
end arch_control;
