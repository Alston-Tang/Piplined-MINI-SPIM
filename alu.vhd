library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity alu is
	port (
		inputA		:	in std_logic_vector(31 downto 0);
		inputB		:	in std_logic_vector(31 downto 0);
		control		:	in std_logic_vector(3 downto 0);
		res		:	out std_logic_vector(31 downto 0);
		zero		:	out std_logic;
		overflow	:	out std_logic
	);
	type res8 is array(0 to 7) of std_logic_vector(31 downto 0);
end alu;

architecture arch_alu of alu is
begin
	process(inputA, inputB, control)
		variable isAdd 		:	std_logic;
		variable op		:	unsigned(2 downto 0);
		variable tempRes	:	res8;
		variable tempOp		:	signed(31 downto 0);
		variable resv		:	std_logic_vector(31 downto 0);
	begin
		isAdd := control(3);
		op := unsigned(control(2 downto 0));
		if isAdd = '0' then
			tempOp := signed(inputA) + signed(inputB);
		else
			tempOp := signed(inputA) - signed(inputB);
		end if;
		tempRes(0) := inputA and inputB;
		tempRes(1) := inputA or inputB;
		tempRes(2) := inputA xor inputB;
		tempRes(3) := inputA nor inputB;
		tempRes(6) := std_logic_vector(tempOp);
		if tempOp < 0 then
			tempRes(7) := x"00000001";
		else
			tempRes(7) := x"00000000";
		end if;
		resv := tempRes(conv_integer(op));
		res <= resv;
		if (resv = x"00000000") then
			zero <= '1';
		else
			zero <= '0';
		end if;
		
	end process;
end arch_alu;