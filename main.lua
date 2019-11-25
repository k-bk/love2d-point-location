UI = require "lib.UI"
v2 = require "lib.v2"
require "kirkpatrick"

font_body = love.graphics.newFont("Cantarell-Regular.otf", 15)
font_title = love.graphics.newFont("Cantarell-Regular.otf", 18)

UI.font = font_body

function love.load()
   love.graphics.setBackgroundColor{ 1,1,1 }
   state = "main"

   edges = {}
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

      if state == "drawing" then
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
   end
end

function love.mousemoved(x, y)
   mouse_position = v2(x,y)
   UI.mousemoved { x = x, y = y }
end

function love.keypressed(key)
   if key == "escape" then
      if love.draw == draw_menu then
         love.event.quit()
      else
         love.draw = draw_menu
      end
   elseif key == "enter" or key == "space" then
      edges[last] = edges[last] or {}
      edges[last][first] = region_id

      for from,e in pairs(edges) do
         for to,region in pairs(e) do
            print(from, to, region)
         end
      end
      state = "main"
      triangulate(edges, polygon, region_id)
   end
end


-- Polygon



-- Drawing
local view = {}

function love.draw()
   view[state]()
   for i = 1,region_id do
      if triangles[i] then
         draw_region(i)
      end
   end
   draw_points()
end

function draw_points()
   local grab_radius = 15

   local r,g,b = love.graphics.getColor()
   local ps = love.graphics.getPointSize()
   local radius
   for point,_ in pairs(edges) do
      if (point - mouse_position):len() < grab_radius then
         love.graphics.setPointSize(7)
      else
         love.graphics.setPointSize(4)
      end
      love.graphics.setColor(1,1,1)
      love.graphics.points(point.x, point.y)
      love.graphics.setColor(0,0,0)
      love.graphics.points(point.x, point.y)
   end

   love.graphics.setPointSize(ps)
   love.graphics.setColor(r,g,b)
end

function view.main()
   UI.draw { x = 10, y = 10,
      UI.button( "Wczytaj siatkę", function() end ),
      UI.button( "Rysuj", function() 
         edges = {}
         polygon = {}
         state = "drawing" 
         generate_id()
      end ),
      UI.button( "Uruchom algorytm", function() end ),
   }
end

function view.drawing()
   UI.draw { x = 10, y = 10,
      UI.button( "Zapisz", function() save_to_file() end ),
   }
end
