function AngleVectors( angles )

	local sy = math.sin( math.rad( angles.yaw ) )
	local cy = math.cos( math.rad( angles.yaw ) )
	local sp = math.sin( math.rad( angles.pitch ) )
	local cp = math.cos( math.rad( angles.pitch ) )
	local sr = math.sin( math.rad( angles.roll ) )
	local cr = math.cos( math.rad( angles.roll ) )

	local forward = Vector( 0, 0, 0 )
	forward.x = cp * cy
	forward.y = cp * sy
	forward.z = -sp

	local right = Vector( 0, 0, 0 )
	right.x = (-1) * sr * sp * cy + (-1) * cr * (-sy)
	right.y = (-1) * sr * sp * sy + (-1) * cr * cy
	right.z = (-1) * sr * cp

	local up = Vector( 0, 0, 0 )
	up.x = cr * sp * cy + (-sr) * (-sy)
	up.y = cr * sp * sy + (-sr) * cy
	up.z = cr * cp
	
	return forward, right, up
end