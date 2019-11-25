child = {}
triangles = {}
color = {}

region_id = 0
function generate_id()
   region_id = region_id + 1
   return region_id
end

function neighbourhood(edges, vertex) 
   local n = {}
   for _,e in pairs(edges[vertex]) do
      table.insert(n, e.to)
   end
   return table.sort(vertex, function(p,q) 
      local angle1 = math.atan2(vertex.y - p.y, vertex.x - p.x)
      local angle2 = math.atan2(vertex.y - q.y, vertex.x - q.x)
      return angle1 < angle2
   end)
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
   local from, to
   for _,t in ipairs(tri) do
      local new_tri = {}
      for _,i in ipairs{ {1,5},{5,3},{3,1} } do
         local x1,y1 = i[1], i[1]+1
         local x2,y2 = i[2], i[2]+1
         from = nearest_to(v2(t[x1],t[y1]), polygon)
         to   = nearest_to(v2(t[x2],t[y2]), polygon)
         edges[from] = edges[from] or {}
         edges[from][to] = region
         table.insert(new_tri, { from, to })
      end
      table.insert(triangles[region], new_tri)
   end
end

function region_from_neighbours(edges, vertex)
   local new_region = generate_id()
   child[new_region] = {}

   -- remove edges going to vertex
   for to,region in pairs(edges[vertex]) do
      edges[to][vertex] = nil
      child[new_region][region] = true
   end

   -- triangulate the new polygon
   triangulate(edges, neighbourhood(edges, vertex), new_region)
end

----

function random_color()
   local r = love.math.random
   return { r(), r(), r(), .5 }
end

function to_table(edges)
   local tab = {}
   for _,e in ipairs(edges) do
      table.insert(tab, e[1].x)
      table.insert(tab, e[1].y)
   end
   return tab
end

function draw_region(region)
   local r,g,b = love.graphics.getColor()
   for _,tri in ipairs(triangles[region]) do
      local t = to_table(tri)
      local mid_x = .5 * (.5 * (t[1] + t[3]) + t[5])
      local mid_y = .5 * (.5 * (t[2] + t[4]) + t[6])
      color[region] = color[region] or random_color()
      love.graphics.setColor(color[region])
      love.graphics.polygon("fill", t)
      love.graphics.setColor(0,0,0,1)
      love.graphics.polygon("line", t)
      love.graphics.print(tostring(region), mid_x, mid_y)
   end
   love.graphics.setColor(r,g,b)
end
