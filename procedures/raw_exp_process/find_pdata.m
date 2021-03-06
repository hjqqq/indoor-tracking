% function pdata_out = find_pdata(FNid, c, pdata_in, counter_max, given_points)
% input: pdata_in, format: (point ; time, counter, distance, beacon id, listener id)
%        FNid (beacon id)
%        c (x y z)
%        counter_max (scalar) (this is the max counter value if you reset on every orbit)
%        given_points (counter, x, y, z)

% output: pdata_out, format: (x, y, z) (indexed by counter value + 1: i.e. 0 to counter_max corresponds here to 1 to counter_max+1)

given_points = zeros(1,4);

known = given_points;
if nnz(known(1,:)) > 0
    pdata_cnt = size(known,1)+1;
else
    pdata_cnt = 1;
end
for i=1:size(pdata_in,1)
    known(pdata_cnt,1) = pdata_in(i,1,2);
    known(pdata_cnt,1) = pdata_in(i,2,1);
    
    known(pdata_cnt,2:4) = point_fix_zero(FNid, c, squeeze(pdata_in(i,3:4,:))');
%     known(pdata_cnt,2:4) = point_fix_zero(FNid, c, squeeze(pdata_in(i,:,3:4)));
    if nnz(known(pdata_cnt,2:4)) > 0  %only if we get a decent answer (resnorm < 1000)        
        pdata_cnt = pdata_cnt + 1;
    end
end
if pdata_cnt == size(known,1)
    known = known(1:size(known,1)-1,:);
end

% now we have the points that we know in 'known' -> extrapolate the rest
% assume first track is same as track_size+1

if size(known,1) < 3
    error('Too few known p-data points');
end
known = sortrows(known,1);
pdata_out = zeros(counter_max+1,3);
for i=1:size(known,1)
    pdata_out(known(i,1)+1,:) = known(i,2:4);
end

% no claim of efficiency here : )
for i=1:counter_max+1
    if nnz(pdata_out(i,:)) == 0 % that is, all columns in this row are zero
        
        %find next point
        next_point = 0;
        for j=i+1:counter_max+1
            if nnz(pdata_out(j,:)) > 0
                next_point = j;
                break
            end
        end
        if next_point == 0
            for j=1:i-1
                if nnz(pdata_out(j,:)) > 0
                    next_point = j;
                    break
                end
            end
        end
        
        %find prev point
        prev_point = 0;
        for j=i-1:-1:1
            if nnz(pdata_out(j,:)) > 0
                prev_point = j;
                break
            end
        end
        if prev_point == 0
            for j=counter_max+1:-1:i+1
                if nnz(pdata_out(j,:)) > 0
                    prev_point = j;
                    break
                end
            end
        end
        
        if next_point > i
            next_weight = next_point - i;
        else
            next_weight = (counter_max+1 - i) + next_point;
        end
        
        if prev_point < i
            prev_weight = i - prev_point;
        else
            prev_weight = i + (counter_max+1 - prev_point);
        end
        
        if prev_weight < next_weight
            ratio_weight = 1 - prev_weight / next_weight;
        else
            ratio_weight = next_weight / prev_weight;
        end
        
        for j=1:2 % we can skip 3 since that's the z coord and will always come back zero -> some optimization : )
            pdata_out(i,j) = pdata_out(next_point,j) - (pdata_out(next_point,j) - pdata_out(prev_point,j)) * ratio_weight;
        end
        
    end
end
pdata = pdata_out;
see_pdata