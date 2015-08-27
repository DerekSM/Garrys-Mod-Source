g_ProficiencyNames = 
{
	[ 0 ] = "Poor",
	"Average",
	"Good",
	"Very Good",
	"Perfect"
};

function GetWeaponProficiencyName( proficiency )
	if ( proficiency < 0 or proficiency > WEAPON_PROFICIENCY_PERFECT ) then
		return "<<Invalid>>"
	end
	
	return g_ProficiencyNames[proficiency]
end
