CREATE OR REPLACE FUNCTION check_sim_card_validity(p_iccid bytea)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
	_num			text;
	_sum_odd		int;
	_temp_se		int;
	_sum_even		int;
	
	_i				int;
begin
	/* Algorithm as per https://www.red-gate.com/simple-talk/blogs/the-luhn-algorithm-in-sql/ */
	_sum_odd := 0;
	_sum_even := 0;
	--	Take out the spaces from the string containing the credit card numbers
	_num := replace(encode(p_iccid, 'escape'), ' ', '');

	if (length(_num) >= 19 and _num~E'^\\d+$') then
		--	Reverse the string containing the credit card numbers.
		_num := reverse(_num);
	
		for _i in 1 .. length(_num)
		loop
			--	Check if position is odd or even
			if (_i % 2 <> 0) then
				-- Sum every digit whose order in the sequence is an odd number (1,3,5,7 …) to create a partial sum s1
				_sum_odd := _sum_odd + substring(_num, _i, 1)::int;
			else
				-- Multiply each even digit by two, 
				_temp_se := (substring(_num, _i, 1)::int) * 2 ;
				-- and then sum the digits of the number if the answer is greater than nine. (e,g if digit is 8 then 8*2=16, then add the resulting digits: 1+6=7).
				if (_temp_se > 9) then
					_temp_se := 1 + mod(_temp_se, 10);
				end if;
				-- Sum the partial sums of the even digits to form s2
				_sum_even := _sum_even + _temp_se;
			end if;
		end loop;
		-- if s1 + s2 ends in zero then the original number is in the form of a valid credit card number as verified by the Luhn test.
		return mod(_sum_odd + _sum_even, 10) = 0;
	else
		return false;
	end if;
end;
$function$
;
