function [cm] = tensor_center_of_mass(matrix)
    total_mass = sum(sum(sum(matrix)));
    [r,c,h] = size(matrix);
    x_cm = 0;
    y_cm = 0;
    z_cm = 0;
    for i = 1:r
        for j = 1:c
            for k=1:h
                x_cm = x_cm + i * matrix(i, j,k);
                y_cm = y_cm + j * matrix(i, j,k);
                z_cm = z_cm + k * matrix(i, j,k);
            end 
        end
    end
    x_cm = x_cm / total_mass;
    y_cm = y_cm / total_mass;
    z_cm = z_cm / total_mass;
    cm = [x_cm, y_cm,z_cm];
end

