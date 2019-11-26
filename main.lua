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
   state = "main"
   drawn_layer = layer

   debug = false
   removed = {}
   edges = {}
   layers = {}
   polygon = {}
   mouse_position = v2(0,0)
end

function love.update(dt)
end

function love.mousepressed(x, y, button)
   if button == 1 then
      UI.mousepressed { x = x, y = y }
   end
end

function love.mousereleased(x, y, button)
   if button == 1 then
      UI.mousereleased { x = x, y = y }
      if state == "main" and algoritm_ended then
         where_is_the_point = find_point(mouse_position)
      elseif state == "drawing" and mouse_position.x > (ui_width or 0) + 10 then

         local to = mouse_position
         first = first or to

         if last then
            edges[last] = edges[last] or {}
            edges[last][to] = region_id
         end

         if last and ((to-last):len() < 15 or (to-first):len() < 15) then
            if #polygon > 2 then
               edges[last] = edges[last] or {}
               edges[last][first] = region_id
               triangulate(edges, polygon, region_id)
               reset = true
            end
            if edges then
               removed[layer] = independent(edges)
            end
         end
         last = to
         table.insert(polygon, to)

         if reset then
            polygon = {}
            first = nil
            last = nil
            reset = false
            generate_id()
         end
      end
   end
end

function love.mousemoved(x, y)
   min_dist = math.huge
   mouse_position = v2(x,y)

   snapped = false
   for point,_ in pairs(edges) do
      local dist = (mouse_position - point):len()
      if dist < 15 then
         snapped = true
         if dist < min_dist then
            min_dist = dist
            mouse_position = point
         end
      end
      inner_label = inner(edges, mouse_position)
   end
   UI.mousemoved { x = x, y = y }
end

function love.keypressed(key)
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
   if snapped then draw_cursor() end
   love.graphics.setCanvas()
   love.graphics.draw(canvas)
end

function draw_cursor()
   local ps = love.graphics.getPointSize()
   love.graphics.setPointSize(10)
   love.graphics.points({{ mouse_position.x, mouse_position.y, .8,0,0,1 }})
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

   table.insert(shape, mouse_position.x)
   table.insert(shape, mouse_position.y)

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
      UI.button( "Rysuj", function() 
         edges = {}
         polygon = {}
         state = "drawing" 
         generate_id()
      end ),
      UI.button( "Popraw triangulację", function() 
         layers[layer] = edges
         if #removed[layer] > 0 then
            edges = step_algorithm(edges, removed[layer]) 
            drawn_layer = layer
            removed[layer] = independent(edges)
         end
      end ),
      UI.label{ "" },
      UI.label{ ("[%d] warstwa:  "):format(drawn_layer) }, 
      UI.button( "Góra", function() drawn_layer = math.min(layer, drawn_layer + 1) end ),
      UI.button( "Dół", function() drawn_layer = math.max(1, drawn_layer - 1) end ),
      UI.label{ "Punkt w wielokącie: " },
      UI.label{ tostring(where_is_the_point) },
      UI.label{ "Punkt 'wewnętrzny'?  " },
      UI.label{ tostring(inner_label) },
   }
   love.graphics.line(ui_width + 10, 0, ui_width + 10, 2000)
end
