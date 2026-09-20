-- Shared geometry only. Server independently validates every placement.
local Placement = { MaxDistance = 30, Gap = 0.25 }

function Placement.GetFrame(place, point, size)
	local localPoint = place.CFrame:PointToObjectSpace(point)
	return place.CFrame * CFrame.new(localPoint.X, place.Size.Y / 2 + size.Y / 2, localPoint.Z)
end

function Placement.IsValid(plot, point, size, rootPosition)
	local place = plot:FindFirstChild("Place")
	local eggs = plot:FindFirstChild("PlacedEggs")
	if not place or not place:IsA("BasePart") or not eggs then return false end
	local p = place.CFrame:PointToObjectSpace(point)
	if math.abs(p.Y - place.Size.Y / 2) > 0.15 then return false end
	if math.abs(p.X) + size.X / 2 > place.Size.X / 2
		or math.abs(p.Z) + size.Z / 2 > place.Size.Z / 2 then return false end
	if (point - rootPosition).Magnitude > Placement.MaxDistance then return false end
	if #eggs:GetChildren() >= (plot:GetAttribute("SlotCapacity") or 6) then return false end
	for _, egg in ipairs(eggs:GetChildren()) do
		if egg:IsA("Model") then
			local frame, otherSize = egg:GetBoundingBox()
			local other = place.CFrame:PointToObjectSpace(frame.Position)
			if math.abs(p.X - other.X) < (size.X + otherSize.X) / 2 + Placement.Gap
				and math.abs(p.Z - other.Z) < (size.Z + otherSize.Z) / 2 + Placement.Gap then
				return false
			end
		end
	end
	return true
end

function Placement.Move(model, boundingFrame)
	local current = model:GetBoundingBox()
	model:PivotTo(boundingFrame * current:ToObjectSpace(model:GetPivot()))
end

return Placement
