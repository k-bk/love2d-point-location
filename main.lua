UI = require "lib.UI"
v2 = require "lib.v2"
require "kirkpatrick"

font_body = love.graphics.newFont("Cantarell-Regular.otf", 15)
font_title = love.graphics.newFont("Cantarell-Regular.otf", 18)
love.graphics.setLineJoin("bevel")

UI.font = font_body

function love.load()
   canvas = love.graphics.newCanvas(2000, 2000)
   love.graphics.setBackgroundColor{ 1,1,1 }
   state = "drawing"
   drawn_layer = layer

   debug = false
   removed = {}
   edges = {}
   polygon = {}
   layers = {}
   mouse_position = v2(0,0)
   ui_width = 0
end

function love.mousepressed(x, y, button)
   if button == 1 then
      UI.mousepressed { x = x, y = y }
   end
end

function love.mousereleased(x, y, button)
   if button == 1 then
      UI.mousereleased { x = x, y = y }
      if state == "none" then
         -- do nothing
      elseif state == "search" then
         point_to_find = mouse_position
         state = "none"
      elseif state == "drawing" and mouse_position.x > ui_width + 10 then

         local to = mouse_position
         first = first or to

         if last and ((to-last):len() < 15 or (to-first):len() < 15) 
            and #polygon > 2 
         then
            triangulate(edges, polygon, region_id)
            polygon = {}
            first = nil
            last = nil
            generate_id()
         else
            last = to
            table.insert(polygon, to)
         end

         if edges then removed[layer] = independent(edges) end
      end
   end
end

function love.mousemoved(x, y)
   mouse_position = v2(x,y)

   snapped = false
   local min_dist = math.huge
   for point,_ in pairs(edges) do
      local dist = (mouse_position - point):len()
      if dist < 15 then
         snapped = true
         if dist < min_dist then
            min_dist = dist
            mouse_position = point
         end
      end
   end

   UI.mousemoved { x = x, y = y }
end


-- Polygon

function process_polygon()
   local to = v2(x,y)
   first = first or to
   if last then
      edges[last] = edges[last] or {}
      edges[last][to] = region_id
   end
   last = to
   table.insert(polygon, to)
   print(to)
end


-- Drawing
local view = {}

function love.draw()
   love.graphics.setCanvas(canvas)
   love.graphics.clear()
   for l = 1,drawn_layer do
      for i = 1,region_id do
         if triangles[i] then
            draw_region(i, l)
         end
      end
      if removed[drawn_layer] then
         for _,point in ipairs(removed[drawn_layer]) do
            love.graphics.setColor(1,1,1)
            love.graphics.circle("fill", point.x, point.y, 10)
            love.graphics.setColor(0,0,0)
            love.graphics.circle("line", point.x, point.y, 10)
            love.graphics.setColor(1,1,1)
         end
      end
   end
   if state == "drawing" and polygon then 
      draw_unfinished(polygon) 
   end
   view()
   if snapped then draw_red_point(mouse_position) end
   if point_to_find then draw_red_point(point_to_find) end
   love.graphics.setCanvas()
   love.graphics.draw(canvas)
end

function draw_red_point(p)
   local ps = love.graphics.getPointSize()
   love.graphics.setPointSize(10)
   love.graphics.points({{ p.x, p.y, .8,0,0,1 }})
   love.graphics.setPointSize(ps)
end

function draw_unfinished(polygon)
   local r,g,b,a = love.graphics.getColor()
   local ps = love.graphics.getPointSize()
   local lw = love.graphics.getLineWidth()
   local shape = {}

   for _,point in ipairs(polygon) do
      table.insert(shape, point.x)
      table.insert(shape, point.y)
   end

   if mouse_position.x > ui_width + 10 then
      table.insert(shape, mouse_position.x)
      table.insert(shape, mouse_position.y)
   end

   love.graphics.setLineWidth(2)
   love.graphics.setColor(0,0,0,.5)
   if #shape > 4 then love.graphics.polygon("fill", shape) end
   love.graphics.setColor(0,0,0,1)
   if #shape > 4 then love.graphics.polygon("line", shape) end
   love.graphics.setPointSize(6)
   love.graphics.points(shape)

   love.graphics.setLineWidth(lw)
   love.graphics.setPointSize(ps)
   love.graphics.setColor(r,g,b,a)
end

function view()
   ui_width,_ = UI.draw { x = 10, y = 10,
      UI.button( "debug", function() debug = not debug end ),
      UI.button( "Ulepsz triangulację", function() 
         state = "none"
         layers[layer] = edges
         if removed[layer] and #removed[layer] > 0 then
            edges = step_algorithm(edges, removed[layer]) 
            drawn_layer = layer
            removed[layer] = independent(edges)
         end
      end ),
      UI.label{""},
      UI.button( "Góra", function() drawn_layer = math.min(layer, drawn_layer + 1) end ),
      UI.button( "Dół", function() drawn_layer = math.max(1, drawn_layer - 1) end ),
      UI.button( "Szukaj punktu", function() state = "search" end ),
      UI.label{ ("Punkt %s:"):format(point_to_find) },
   }
   UI.draw { x = ui_width + 30, y = 10,
      {
         UI.label({ ("[%d] warstwa"):format(drawn_layer) }, font_title),
         point_to_find and UI.label({ find_point(point_to_find) or "Punkt poza obszarem" }, font_title),
      }
   }

   love.graphics.line(ui_width + 20, 0, ui_width + 20, 2000)
end
