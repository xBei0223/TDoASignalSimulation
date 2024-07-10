function estimatedPosition = locatePosition(receiverPositions, estTDoA)

x1 = receiverPositions(1, 1);
y1 = receiverPositions(1, 2);
x2 = receiverPositions(2, 1);
y2 = receiverPositions(2, 2);
x3 = receiverPositions(3, 1);
y3 = receiverPositions(3, 2);
c = 3e8;

r21 = c* estTDoA(2);
r31 = c* estTDoA(3);

 
x21 = x2 - x1;
x31 = x3 - x1;
y21 = y2 - y1;
y31 = y3 - y1;

 
K1  = x1^2 + y1^2;
K2  = x2^2 + y2^2;
K3  = x3^2 + y3^2;

% xy猜测值
x = 2500;
y = 2500;


maxIter = 50000;
tol = 100;


for iter = 1:maxIter  
    r1_new = sqrt((x1-x)^2 + (y1-y)^2);

    B = [0.5*(K2-K1-r21^2)-r21*r1_new;
         0.5*(K3-K1-r31^2)-r31*r1_new];

    A = [x21, y21;
         x31, y31];
    solution = A\B;

    x_new = solution(1);
    y_new = solution(2);

    if norm([x_new - x, y_new - y]) < tol
        break;
    end
    x = x_new;
    y = y_new;
end

if(norm([x_new, y_new]))>50000
    x = 0;
    y = 0;
end

if isnan([x,y])
    x = 0;
    y = 0;
end


estimatedPosition = [x,y];

end
