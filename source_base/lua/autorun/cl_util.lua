function util.PrecacheOther( szClassname )
	local pEntity = ents.Create( szClassname )
	
	-- pEntity:Precache() -- Fix: precache can't be invoked
	
	pEntity:Remove()
end