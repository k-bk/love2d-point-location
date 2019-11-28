child = {}
triangles = {}
color = {}
layer = 1

region_id = 1
function generate_id()
   region_id = region_id + 1
   return region_id
end

function neighbourhood(edges, vertex) 
   local n = {}
   for to,region in pairs(edges[vertex]) do
      table.insert(n, to)
   end
   table.sort(n, function(p,q) 
      local angle1 = math.atan2(vertex.y - p.y, vertex.x - p.x)
      local angle2 = math.atan2(vertex.y - q.y, vertex.x - q.x)
      return angle1 < angle2
   end)
   return n
end

function degree(edges, vertex) 
   local d = 0
   for _,_ in pairs(edges[vertex]) do d = d + 1 end
   return d
end

function inner(edges, vertex)
   if not edges[vertex] then return nil end

   for to,region in pairs(edges[vertex]) do
      if not (edges[to] and edges[to][vertex]) then
         return false
      end
   end
   return true
end

function nearest_to(vertex, polygon)
   local min = polygon[1]
   for _,v in ipairs(polygon) do
      if (vertex-v):len() < (vertex-min):len() then
         min = v
      end
   end
   return min
end

function ccw_triangle(points)
   local a = v2(points[1], points[2])
   local b = v2(points[3], points[4])
   local c = v2(points[5], points[6])
   if orient(a,b,c) == 1 then return a,c,b end
   if orient(a,b,c) ==-1 then return a,b,c end
end

function triangulate(edges, polygon, region)
   triangles[region] = {}
   -- convert polygon to format accepted by love.math.triangulate
   local p = {}
   for _,v in ipairs(polygon) do
      table.insert(p, v.x)
      table.insert(p, v.y)
   end
   local tri = love.math.triangulate(p)

   -- use new triangles to update the regions
   for _,t in ipairs(tri) do
      local a,b,c = ccw_triangle(t)
      a,b,c = nearest_to(a,polygon), nearest_to(b,polygon), nearest_to(c,polygon)
      edges[a] = edges[a] or {}
      edges[b] = edges[b] or {}
      edges[c] = edges[c] or {}
      edges[a][b] = region
      edges[b][c] = region
      edges[c][a] = region
      local new_tri = { {a,b}, {b,c}, {c,a}, layer = layer }
      table.insert(triangles[region], new_tri)
   end
end

function region_from_neighbours(edges, vertex)
   generate_id()
   child[region_id] = {}

   -- remove edges going to vertex
   for to,region in pairs(edges[vertex]) do
      edges[to][vertex] = nil
      child[region_id][region] = true
   end

   -- triangulate the new polygon
   triangulate(edges, neighbourhood(edges, vertex), region_id)

   -- remove edges going from vertex
   edges[vertex] = nil
end

function independent(edges)
   local blocked = {}
   local independent = {}
   for vertex,_ in pairs(edges) do
      if not blocked[vertex] 
         and inner(edges, vertex) 
         and degree(edges, vertex) > 1 
      then
         table.insert(independent, vertex)
         blocked[vertex] = true
         for to,_ in pairs(edges[vertex]) do
            blocked[to] = true
         end
      end
   end
   return independent
end

function step_algorithm(edges, independent_set)
   layer = layer + 1
   local new_edges = {}
   for from, to_set in pairs(edges) do
      new_edges[from] = {}
      for to,region in pairs(to_set) do
         new_edges[from][to] = region
      end
   end

   for _, to_remove in ipairs(independent_set) do
      region_from_neighbours(new_edges, to_remove)
   end
   return new_edges
end

function det3(a,b,c)
    return (a.x-c.x) * (b.y-c.y)
         - (a.y-c.y) * (b.x-c.x)
end

function orient(a,b,c)
   if a == b or b == c or c == a then return 0 end
   local d = det3(a,b,c)
   local eps = 1e-10
   if d > eps then
      return 1
   elseif d < -eps then
      return -1
   else
      return 0
   end
end

function point_in_triangle(point, tri)
   for _,e in ipairs(tri) do
      if orient(e[1], e[2], point) == 1 then return false end
   end
   return true
end

function find_point(point)
   -- find root regions
   local roots = {}
   for from,e in pairs(edges) do
      for to,region in pairs(e) do
         roots[region] = true
      end
   end

   for root,_ in pairs(roots) do
      local search = find_in_region(point, root)
      if search then return search end
   end
end

function find_in_region(point, region)
   local found = false
   for _,tri in ipairs(triangles[region]) do
      if point_in_triangle(point, tri) then
         found = true
      end
   end

   if found and (not child[region]) then return tostring(region) end
   if not found then return nil end

   for deeper,_ in pairs(child[region]) do
      local search = find_in_region(point, deeper)
      if search then
         return ("%d -> %s"):format(region, search)
      end
   end
end


-- Drawing procedures

function random_color()
   local r = function() return (love.math.random() + 1) / 2 end
   return { r(), r(), r(), 1 }
end

function to_table(edges)
   local tab = {}
   for _,e in ipairs(edges) do
      table.insert(tab, e[1].x)
      table.insert(tab, e[1].y)
   end
   return tab
end

function arrows(t)
   for i = 1,#t,2 do
      local from = v2(t[i], t[i+1])
      local to = v2(t[(i+1) % #t + 1], t[(i+2) % #t + 1])
      local arr = (0.2 * from) + (0.8 * to)
      love.graphics.setColor(1,.8,0)
      love.graphics.circle("fill", arr.x, arr.y, 7)
      love.graphics.setColor(0,0,0)
      love.graphics.circle("fill", arr.x, arr.y, 7)
   end
end

function draw_region(region, drawn_layer)
   local r,g,b = love.graphics.getColor()
   local lw = love.graphics.getLineWidth()
   love.graphics.setLineWidth(2)
   for _,tri in ipairs(triangles[region]) do
      if tri.layer == drawn_layer then
         local t = to_table(tri)
         local mid_x = .5 * (.5 * (t[1] + t[3]) + t[5])
         local mid_y = .5 * (.5 * (t[2] + t[4]) + t[6])
         color[region] = color[region] or random_color()
         love.graphics.setColor(color[region])
         love.graphics.polygon("fill", t)
         love.graphics.setColor(0,0,0,1)
         love.graphics.polygon("line", t)
         if debug then arrows(t) end
         love.graphics.print(tostring(region), mid_x, mid_y)
      end
   end
   love.graphics.setLineWidth(lw)
   love.graphics.setColor(r,g,b)
end
