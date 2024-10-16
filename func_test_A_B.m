function [Result] = func_test_A_B(data)
   data = 23;
   Result = B(100) + C(data);
end

function [Result_B] = B(data)
    Result_B = data;
end

function [Result_B] = C(data)
    Result_B = data;
end