-- dredwork Geography — Map Graph
-- Manages regions and their spatial relationships (adjacency/distance).

local Biomes = require("dredwork_geography.biomes")

local Map = {}

--- Create a new region.
function Map.create_region(id, label, biome_key)
    local biome = Biomes[biome_key] or Biomes.temperate
    return {
        id = id,
        label = label,
        biome = biome_key,
        upkeep_mod = biome.upkeep_mod,
        rumor_speed = biome.rumor_speed,
        adjacent = {}, -- Map of id -> distance
        tags = biome.tags
    }
end

--- Link two regions.
function Map.link(region_a, region_b, distance)
    distance = distance or 1
    region_a.adjacent[region_b.id] = distance
    region_b.adjacent[region_a.id] = distance
end

--- Find distance between regions (simple BFS for now).
function Map.get_distance(regions, start_id, end_id)
    if start_id == end_id then return 0 end
    
    local queue = {{ id = start_id, dist = 0 }}
    local visited = { [start_id] = true }
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local region = regions[current.id]
        
        for adj_id, weight in pairs(region.adjacent) do
            if adj_id == end_id then
                return current.dist + weight
            end
            if not visited[adj_id] then
                visited[adj_id] = true
                table.insert(queue, { id = adj_id, dist = current.dist + weight })
            end
        end
    end
    
    return 999 -- Unreachable
end

return Map
