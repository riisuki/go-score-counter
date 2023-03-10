function ret = isPointInCircle(x, y, radiiArr, centerArr)
    % Return true if point is inside one of the circles
    % Return false if point not inside one of the circles

    ret = false;
    for i = 1:length(radiiArr)
        x0 = centerArr(i,1);
        y0 = centerArr(i,2);
        r = radiiArr(i);
        if ((x-x0)^2 + (y-y0)^2 <= r^2)
            ret = true;
            break;
        end
    end
end
