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
      (Math.sqrt(x*x + y*y) / 24 * 360 * 2).sin 
    }
    observer_z =  (args.state.tick_count).sin / 2 + 0.98
    visible = compute_fov([0, 0, observer_z], 16, &get_z)

    visible.each do |x, y| 
      # TODO: Shorter spires further from start?
      z = get_z.call(x, y)
      return if z.nil? 
      cx, cy = 1280/2, 720/2

      tx = cx - x * 14 - y * 14
      ty = cy - x * 7 + y * 7 
      tyz = ty + (z - observer_z) * 28

      zbuf.add(-ty,
        {primitive_marker: :sprite, x: tx - 16, y: tyz - 8, w: 32, h: 32, path: 'sprites/circ32.png', r: 255, g: 128 + z * 127, b: 0}
      )
    end

    zbuf.add(-720/2, {primitive_marker: :sprite, x: 1280/2 - 16, y: 720/2 - 16, w: 32, h: 32, path: 'sprites/circ32.png', r: 0, g: 128, b: 255})

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
