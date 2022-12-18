function ret = fillBoard(boardArray)
    % Fill empty points with either black territory (3) or white territory(4)
    % using a simple filling algorithm.
    % Neutral territory (0) is defined territory with both black and white bounds.

    ret = boardArray;
    mark = 5;
    for i = 1:size(ret,1)
        for j = 1:size(ret,2)
            % Get area
            curPoint = ret(i,j);
            if curPoint == 0
                % If point empty, group area
                if i>1 && ret(i-1,j)>2
                    fillWith = ret(i-1,j);
                elseif j>1 && ret(i,j-1)>2
                    fillWith = ret(i,j-1);
                else
                    fillWith = mark;
                    mark = mark + 1;
                end
                ret(i,j) = fillWith;
            end
        end
    end

    for k=5:mark-1
        % Iterate all area marks
        isWhiteTerritory = false;
        isBlackTerritory = false;
        for i = 1:size(ret,1)
            for j = 1:size(ret,2)
                curPoint = ret(i,j);
                if curPoint == k
                    % Current area
                    if(i>1)
                        if ret(i-1,j) == 1
                            isBlackTerritory = true;
                        elseif ret(i-1,j) == 2
                            isWhiteTerritory = true;
                        elseif ret(i-1,j) > 4
                            ret(ret==ret(i-1,j))=k;
                        end
                    end

                    if(i<size(ret,1))
                        if ret(i+1,j) == 1
                            isBlackTerritory = true;
                        elseif ret(i+1,j) == 2
                            isWhiteTerritory = true;
                        elseif ret(i+1,j) > 4
                            ret(ret==ret(i+1,j))=k;
                        end
                    end

                    if(j>1)
                        if ret(i,j-1) == 1
                            isBlackTerritory = true;
                        elseif ret(i,j-1) == 2
                            isWhiteTerritory = true;
                        elseif ret(i,j-1) > 4
                            ret(ret==ret(i,j-1))=k;
                        end
                    end

                    if(j<size(ret,2))
                        if ret(i,j+1) == 1
                            isBlackTerritory = true;
                        elseif ret(i,j+1) == 2
                            isWhiteTerritory = true;
                        elseif ret(i,j+1) > 4
                            ret(ret==ret(i,j+1))=k;
                        end
                    end

                end
            end
        end

        % Replace value
        if(isBlackTerritory && isWhiteTerritory)
            newValue = 0;
        elseif(isBlackTerritory)
            newValue = 3;
        elseif(isWhiteTerritory)
            newValue = 4;
        else
            newValue = 0;
        end

        ret(ret==k)=newValue;
    end
end
