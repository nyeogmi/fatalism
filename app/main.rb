# NOTE: Engine renders at 1280x720
require "app/shadows.rb"

# TODO: Replace with a faster implementation
class ZBuf
  def initialize() 
    @primitives = Hash.new { |hash, key| hash[key] = [] }
  end

  def add(z, prim)
    @primitives[z].push(prim)
  end

  def consume(args)
    args.outputs.primitives << @primitives.keys.sort!.map(&@primitives)
  end
end

class Game
  attr_gtk

  def inject(args) @args = args end

  def tick
    zbuf = ZBuf.new
    args.outputs.background_color=[255,255,255]

    # zbuf.add(0) { self.draw_player(1280/2, 720/2, 255, 0, 255) }
    get_z = lambda { |x, y| 
      # return nil if x == 0 && y == 0
      dist = Math.sqrt(x*x + y*y) / 18
      (dist * 360 * 2).sin * (0.25 + 1.0 * dist)
    }
    observer_x = (args.state.tick_count).cos * 12
    observer_y = (args.state.tick_count).sin * 4
    observer_z = get_z.call(observer_x, observer_y) # (args.state.tick_count).sin + 0.98
    visible = compute_fov([observer_x, observer_y, observer_z + 0.5], 16, &get_z)

    visible.each do |x, y| 
      # TODO: Shorter spires further from start?
      z = get_z.call(x, y)
      return if z.nil? 
      cx, cy = 1280/2, 720/2 - 64

      dx, dy, dz = x - observer_x, y - observer_y, z - observer_z

      dist = Math.sqrt(dx * dx + dy * dy) 
      alpha = (1.0 - (dist <= 14 ? 0.0 : ((dist - 14) / (16 - 14)) ** 1.5))

      tx = - dx * 14 - dy * 14
      ty = - dx * 7 + dy * 7 
      tyz = ty + dz * 28

      r, g, b = 255, 128 + z * 127, 0
      g = 0 if g < 0
      g = 255 if g > 255

      zbuf.add(-ty,
        {primitive_marker: :sprite, x: cx + tx - 16, y: cy + tyz - 8, w: 32, h: 32, path: 'sprites/circ32.png', r: r, g: g, b: b, a: 255 * alpha}
      )
    end

    zbuf.add(0, {primitive_marker: :sprite, x: 1280/2 - 32, y: 720/2 - 64 + 16, w: 64, h: 64, path: 'sprites/bat256.png', r: 0, g: 128, b: 255})

    zbuf.consume(@args)
  end

  def draw_player(x, y, *rgb)
    # @args.outputs.solids << [x - 30, y - 30, 60, 60, *rgb]
  end
end

def tick args
  args.state.game ||= Game.new
  args.state.game.inject(args)
  args.state.game.tick
end

$gtk.reset
$game = nil
