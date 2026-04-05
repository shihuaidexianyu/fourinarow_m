function cm = deg2cm(theta_deg, distance_cm)
%DEG2CM Convert visual angle (deg) to physical size (cm).

cm = 2 .* distance_cm .* tan(deg2rad(theta_deg ./ 2));
end
