library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculator is
  port(
    instr : in std_logic_vector(7 downto 0);
    clk : in std_logic
  );
end entity calculator;


architecture structural of calculator is
  component ALU is
      port(
          input_a, input_b : in std_logic_vector(7 downto 0);
          addsub_sel : in std_logic;
          sum : out std_logic_vector(7 downto 0)
        );
  end component ALU;

  component reg_file is
    port(
      reg_a : in std_logic_vector(1 downto 0);
      reg_b : in std_logic_vector(1 downto 0);
      reg_write : in std_logic_vector(1 downto 0);
      write_data : in std_logic_vector(7 downto 0);
      clk : in std_logic;
      write_enable : in std_logic;
      reg_a_data : out std_logic_vector(7 downto 0);
      reg_b_data : out std_logic_vector(7 downto 0)
    );
  end component reg_file;


signal write_enable, display, write_data_sel, skipcount : std_logic;
signal reg_a, reg_b, reg_write : std_logic_vector(1 downto 0);
signal write_data, reg_a_data, reg_b_data, sign_ext, ALU_out: std_logic_vector(7 downto 0);

begin
  if((instr(7) = '0') and (instr(6) = '0') and (instr(5) = '1")) then
    skipcount <= instr(4);
  endif;

  if(ALU_out = "00000000") then
    if(skipcount = '1') then
      write_enable <= '0';
    elsif(skipcount = '0') then
      write_enable <= '0';
    end if;
  end if;

  if(skipcount = '1' and write_enable = '0') then
    skipcount <= '0';
  elsif(skipcount = '0' and write_enable = '0') then
    write_enable <= '1';
  end if;  

  reg_file_0 : reg_file port map(reg_a, reg_b, reg_write, write_data, write_enable, reg_a_data, reg_b_data);
  ALU0 : ALU port map(reg_a_data, reg_b_data, instr(7), ALU_out);

  reg_b <= instr(1 downto 0);
  reg_write <= instr(5 downto 4);

  display <= not (instr(7) or instr(6) or instr(5));

  with display select reg_a <=
    instr(3 downto 2) when '0',
    instr(4 downto 3) when others;

  sign_ext(3 downto 0) <= instr(3 downto 0);
  with instr(3) select sign_ext(7 downto 4) <=
    "1111" when '1',
    "0000" when others;

  write_data_sel <= not(instr(7) and instr(6));
  with write_data_sel select write_data <=
    sign_ext when '0',
    ALU_out when others;

  process(display) is
    variable int_val : integer;
    begin
      if((clk'event and clk = '1') and (display = '1') and (write_enable = '1') then
        int_val := to_integer(signed(reg_a_data));
        if(int_val >= 0) then
          if(int_val < 10) then
            report "   " & integer'image(int_val) severity note;
          elsif(int_val < 100) then
            report "  " & integer'image(int_val) severity note;
          else
            report " " & integer'image(int_val) severity note;
          end if;
        else
          if(int_val > -10) then
            report "  " & integer'image(int_val) severity note;
          elsif(int_val > -100) then
            report " " & integer'image(int_val) severity note;
          else
            report integer'image(int_val) severity note;
          end if;
        end if;
      end if;
  end process;
end architecture structural;
