library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity processor_core is
	port (
		clk		:	in std_logic;
		rst		:	in std_logic;
		run		:	in std_logic;
		instaddr	:	out std_logic_vector(31 downto 0);
		inst		:	in std_logic_vector(31 downto 0);
		memwen		:	out std_logic;
		memaddr		:	out std_logic_vector(31 downto 0);
		memdw		:	out std_logic_vector(31 downto 0);
		memdr		:	in std_logic_vector(31 downto 0);
		fin		:	out std_logic;
		PCout		:	out std_logic_vector(31 downto 0);
		regaddr		:	in std_logic_vector(4 downto 0);
		regdout		:	out std_logic_vector(31 downto 0)
	);
end processor_core;

architecture arch_processor_core of processor_core is
	-- Add the register table here
	component regtable
		port(
			clk		:	in std_logic;
			rst		:	in std_logic;
			raddrA		:	in std_logic_vector(4 downto 0);
			raddrB		:	in std_logic_vector(4 downto 0);
			wen		:	in std_logic;
			waddr		:	in std_logic_vector(4 downto 0);
			din		:	in std_logic_vector(31 downto 0);
			doutA		:	out std_logic_vector(31 downto 0);
			doutB		:	out std_logic_vector(31 downto 0);
			extaddr		:	in std_logic_vector(4 downto 0);
			extdout		:	out std_logic_vector(31 downto 0)
		);
	end component;
	signal regraddrA	:	std_logic_vector(4 downto 0);
	signal regraddrB	:	std_logic_vector(4 downto 0);
	signal regwen		:	std_logic;
	signal regwaddr		:	std_logic_vector(4 downto 0);
	signal regdw		:	std_logic_vector(31 downto 0);
	signal regdrA		:	std_logic_vector(31 downto 0);
	signal regdrB		:	std_logic_vector(31 downto 0);
	signal regexaddr	:	std_logic_vector(4 downto 0);
	signal regexdr		:	std_logic_vector(31 downto 0);

	component control is
		port(
			instOp		:	in std_logic_vector(5 downto 0);
			regDst		:	out std_logic;
			aluSrc		:	out std_logic;
			memReg		:	out std_logic;
			regWr		:	out std_logic;
			memWrite	:	out std_logic;
			branch		:	out std_logic;
			jump		:	out std_logic;
			aluOp		:	out std_logic_vector(1 downto 0);
			excep		:	out std_logic
		);
	end component;
	signal regDst, aluSrc, memReg, regWr, memWrite, branch, jump, contrExcep
				:	std_logic;
	signal aluOp		:	std_logic_vector(1 downto 0);

	component alu is
		port(
			inputA		:	in std_logic_vector(31 downto 0);
			inputB		:	in std_logic_vector(31 downto 0);
			control		:	in std_logic_vector(3 downto 0);
			res		:	out std_logic_vector(31 downto 0);
			zero		:	out std_logic;
			overflow	:	out std_logic
		);
	end component;
	signal inputA, inputB, res	:	std_logic_vector(31 downto 0);
	signal aluControl		:	std_logic_vector(3 downto 0);
	signal zero, overflow		:	std_logic;

	component alu_control is
		port(
			ALUOp		:	in std_logic_vector(1 downto 0);
			func		:	in std_logic_vector(5 downto 0);
			control		:	out std_logic_vector(3 downto 0);
			excep		:	out std_logic
		);
	end component;
	signal aluContrExcep		:	std_logic;
-- Add signals here
-- Global --
	signal running		:	std_logic := '0';
-- IF/ID Signals --
	signal pcNext		:	unsigned(31 downto 0);
	signal pc		:	unsigned(31 downto 0);
	signal instOp, if_id_func	
				:	std_logic_vector(5 downto 0);
	signal rsaddr, rtaddr, rdaddr
				:	std_logic_vector(4 downto 0);
	signal if_id_regwen, if_id_memreg, if_id_branch, if_id_memwen
				:	std_logic;
	signal if_id_aluop		:	std_logic_vector(1 downto 0);

-- ID/EX Signals --
	signal inputBt			:	std_logic_vector(31 downto 0);
	signal iext, iextshf, jextshf	:	std_logic_vector(31 downto 0);
	signal id_ex_regwen, id_ex_memreg, id_ex_memwrite, id_ex_branch, id_ex_memwen		
					:	std_logic;
	signal id_ex_regwaddr		:	std_logic_vector(4 downto 0);
	signal func			: 	std_logic_vector(5 downto 0);
	signal id_ex_regdrB		:	std_logic_vector(31 downto 0);
-- EX/MEM Signals
	signal branchTar	:	unsigned(31 downto 0);
	signal ex_mem_regwen
				:	std_logic;
	signal ex_mem_regwaddr	:	std_logic_vector(4 downto 0);
	signal ex_mem_res	:	std_logic_vector(31 downto 0);
-- MEM/WB Signals

begin
	-- Reg Table Map
	REG:	regtable
	port map(
		clk	=>	clk,
		rst	=>	rst,
		raddrA	=>	regraddrA,
		raddrB	=>	regraddrB,
		wen	=>	regwen,
		waddr	=>	regwaddr,
		din	=>	regdw,
		doutA	=>	regdrA,
		doutB	=>	regdrB,
		extaddr	=>	regexaddr,
		extdout	=>	regexdr
	);

	-- Main Control Map
	CONTR:	control
	port map(
		instOp	=>	instOp,
		regDst	=>	regDst,
		aluSrc	=>	alusrc,
		memReg	=>	if_id_memreg,
		regWr	=>	if_id_regwen,
		branch	=>	if_id_branch,
		memWrite=>	if_id_memwen,
		jump	=>	jump,
		aluOp	=>	if_id_aluop,
		excep	=>	contrExcep
	);
	
	-- ALU Map --
	ALUP:	alu
	port map(
		inputA	=>	inputA,
		inputB	=>	inputB,
		control =>	aluControl,
		res	=>	res,
		zero	=>	zero,
		overflow=>	overflow
	);

	ALUCONTR:	alu_control
	port map(
		ALUOp	=>	aluOp,
		func	=>	func,
		control	=>	aluControl,
		excep	=>	aluContrExcep
	);


-- Processor Core Behaviour
	-- Set Running Status --
	process(run)
	begin
		if run = '1' then
			running <= '1';
		end if;
	end process;
	-- IF --
	process(clk)
	begin
		if running = '1' and rising_edge(clk) then
			instaddr <= std_logic_vector(pc);
			pcNext <= pc + 4;
		end if;
	end process;
	-- ID --
	process(clk)
	variable ioriv			:	std_logic_vector(15 downto 0);
	variable joriv			:	std_logic_vector(25 downto 0);
	begin
		if running = '1' and rising_edge(clk) then
			func <= if_id_func;
			aluOp <= if_id_aluop;
			inputA <= regdrA;
			inputB <= inputBt;
			id_ex_regwen <= if_id_regwen;
			id_ex_memwen <= if_id_memwen;
			id_ex_memreg <= if_id_memreg;
			id_ex_branch <= if_id_branch;
			id_ex_regwen <= if_id_regwen;
			id_ex_regdrB <= regdrB;
		end if;
	end process;
	-- EX --
	process(clk)
	begin
		if running = '1' and rising_edge(clk) then
			memwen <= id_ex_memwen;
			memaddr <= res;
			memdw <= id_ex_regdrB;

			ex_mem_regwen <= id_ex_regwen;
			memReg <= id_ex_memreg;
			ex_mem_regwaddr <= id_ex_regwaddr;
			ex_mem_res <= res;
			
		end if;
	end process;
	-- MEM --
	process(clk)
	begin
		if running = '1' and rising_edge(clk) then
			regwen <= ex_mem_regwen;
			regwaddr <= ex_mem_regwaddr;
		end if;
	end process;
	-- Jump Mutex --
	process(jump, branchTar, jextshf)
	begin
		if running = '1' then
			if jump = '1' then
				pc <= unsigned(jextshf);
			else
				pc <= unsigned(branchTar);
			end if;
		else
			pc <= x"00004000";
		end if;
	end process;
	-- Alu Src Mutex --
	process(aluSrc, regdrB, iext)
	begin
		if aluSrc = '1' then
			inputBt <= iext;
		else
			inputBt <= regdrB;
		end if;
	end process;
	-- Decoding --
	process(inst)
	begin
		instOp <= inst(31 downto 26);
		rsaddr <= inst(25 downto 21);
		rtaddr <= inst(20 downto 16);
		rdaddr <= inst(15 downto 11);
		if_id_func <= inst(5 downto 0);
	end process;
	-- Sign Extent --
	process(inst)
	variable ioriv	:	std_logic_vector(15 downto 0);
	variable joriv	:	std_logic_vector(25 downto 0);
	begin
		ioriv := inst(15 downto 0);
		joriv := inst(25 downto 0);
		iext <= std_logic_vector(resize(signed(ioriv), 32));
		iextshf <= std_logic_vector(resize(signed(ioriv & "00"), 32));
		jextshf(31 downto 28) <= std_logic_vector(pcNext(31 downto 28));
		jextshf(27 downto 2) <= joriv;
		jextshf(1 downto 0) <= "00";
	end process;
	-- Reg Read Addr Pass --
	process(rsaddr)
	begin
		regraddrA <= rsaddr;
	end process;
	process(rtaddr)
	begin
		regraddrB <= rtaddr;
	end process;	
	-- PC Src Mutex --
	process(branch, zero, iextshf, pcNext)
	begin
		if branch = '1' and zero = '1' then
			branchTar <= unsigned(iextshf);
		else
			branchTar <= pcNext;
		end if;
	end process;
	-- Mem to Reg Mutex --
	process(memReg, ex_mem_res, memdr)
	begin
		if memReg = '1' then
			regdw <= memdr;
		else
			regdw <= ex_mem_res;
		end if;
	end process;
	-- Reg Dst Mutex --
	process(regDst, rtaddr, rdaddr)
	begin
		if regDst = '0' then
			id_ex_regwaddr <= rtaddr;
		else
			id_ex_regwaddr <= rdaddr;
		end if;
	end process;
			
end arch_processor_core;
